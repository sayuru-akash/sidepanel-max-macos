import Foundation
import SwiftData
import WebKit
import Combine

/// Owns the array of open tabs and exposes CRUD + reordering.
@MainActor
final class TabManager: ObservableObject {

    static let shared = TabManager()

    // MARK: - Published State

    @Published var tabs: [Tab] = []
    @Published var activeTabId: UUID?

    // MARK: - SwiftData

    /// The model context used to persist Tab objects. Set during app startup
    /// from PersistenceController so that inserts/deletes are actually tracked.
    var modelContext: ModelContext?

    // MARK: - Limits

    private let maxTabs = 50
    private var pendingHistoryIndexByTabID: [UUID: Int] = [:]
    private var cancellables: Set<AnyCancellable> = []
    private var observedHomepage: String

    // MARK: - Active Tab Helper

    var activeTab: Tab? {
        tabs.first { $0.id == activeTabId }
    }

    var defaultHomeURLString: String {
        Self.normalizedHomepage(SettingsManager.shared.homepage)
    }

    private var defaultHomeURL: URL {
        URL(string: defaultHomeURLString) ?? URL(string: "https://google.com")!
    }

    private init() {
        observedHomepage = Self.normalizedHomepage(SettingsManager.shared.homepage)

        SettingsManager.shared.$homepage
            .receive(on: RunLoop.main)
            .sink { [weak self] newHomepage in
                guard let self else { return }
                let oldHomepage = self.observedHomepage
                let normalizedNewHomepage = Self.normalizedHomepage(newHomepage)
                self.observedHomepage = normalizedNewHomepage
                self.updateHomepageTabs(from: oldHomepage, to: normalizedNewHomepage)
            }
            .store(in: &cancellables)
    }

    // MARK: - CRUD

    @discardableResult
    func createTab(url: URL? = nil, activate: Bool = true) -> Tab {
        if tabs.count >= maxTabs {
            closeOldestUnpinnedTab()
        }

        let tab = Tab(
            url: normalizedURLString(url?.absoluteString),
            title: "New Tab",
            order: tabs.count
        )

        tabs.append(tab)
        modelContext?.insert(tab)

        // Initialize WKWebView
        let webView = createWebView(for: tab)
        tab.webView = webView

        if let url {
            webView.load(URLRequest(url: url))
        } else {
            loadDefaultPage(in: webView)
        }

        if activate {
            activateTab(tab)
        }

        SessionManager.shared.scheduleSnapshotSave()
        return tab
    }

    func closeTab(_ tab: Tab) {
        guard !tab.isPinned else { return }

        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        tabs.remove(at: index)

        // Pick a new active tab if we just closed the active one.
        if activeTabId == tab.id {
            let newIndex = min(index, tabs.count - 1)
            if newIndex >= 0 {
                activateTab(tabs[newIndex])
            } else {
                activeTabId = nil
            }
        }

        // Tear down the web view.
        tab.webView?.stopLoading()
        tab.webView = nil
        pendingHistoryIndexByTabID.removeValue(forKey: tab.id)
        modelContext?.delete(tab)

        reindex()
        SessionManager.shared.scheduleSnapshotSave()
    }

    func closeAllTabs(exceptPinned: Bool = true) {
        let toClose = exceptPinned ? tabs.filter { !$0.isPinned } : tabs
        for tab in toClose {
            tab.webView?.stopLoading()
            tab.webView = nil
            pendingHistoryIndexByTabID.removeValue(forKey: tab.id)
            modelContext?.delete(tab)
        }
        if exceptPinned {
            tabs.removeAll { !$0.isPinned }
        } else {
            tabs.removeAll()
        }
        activeTabId = tabs.first?.id
        reindex()
        SessionManager.shared.scheduleSnapshotSave()
    }

    func activateTab(_ tab: Tab) {
        activeTabId = tab.id
        tab.lastAccessedAt = Date()

        // Lazily create the web view if it was suspended.
        if tab.webView == nil {
            let webView = createWebView(for: tab)
            tab.webView = webView
            if let url = URL(string: normalizedURLString(tab.url)) {
                webView.load(URLRequest(url: url))
                tab.url = url.absoluteString
            }
        }

        SessionManager.shared.scheduleSnapshotSave()
    }

    func duplicateTab(_ tab: Tab) {
        createTab(url: URL(string: tab.url))
    }

    // MARK: - Reordering

    func reorderTabs(from source: IndexSet, to destination: Int) {
        tabs.move(fromOffsets: source, toOffset: destination)
        reindex()
        SessionManager.shared.scheduleSnapshotSave()
    }

    // MARK: - Navigation Helpers

    func navigate(to urlString: String) {
        guard let tab = activeTab else {
            createTab(url: resolveURL(from: urlString))
            return
        }

        let url = resolveURL(from: urlString)
        pendingHistoryIndexByTabID.removeValue(forKey: tab.id)
        tab.url = url.absoluteString
        tab.webView?.load(URLRequest(url: url))
        SessionManager.shared.scheduleSnapshotSave()
    }

    func goBack() {
        guard let tab = activeTab, canGoBack(tab) else { return }
        navigateHistory(for: tab, direction: -1)
    }

    func goForward() {
        guard let tab = activeTab, canGoForward(tab) else { return }
        navigateHistory(for: tab, direction: 1)
    }

    func reload() { activeTab?.webView?.reload() }
    func stopLoading() { activeTab?.webView?.stopLoading() }

    func canGoBack(_ tab: Tab?) -> Bool {
        guard let tab else { return false }
        return (tab.webView?.canGoBack ?? false) || historyIndex(for: tab) > 0
    }

    func canGoForward(_ tab: Tab?) -> Bool {
        guard let tab else { return false }
        let entries = historyEntries(for: tab)
        return (tab.webView?.canGoForward ?? false) || historyIndex(for: tab, entries: entries) < entries.count - 1
    }

    // MARK: - Tab Switching

    func activateNextTab() {
        guard let current = activeTab,
              let idx = tabs.firstIndex(where: { $0.id == current.id }) else { return }
        let next = (idx + 1) % tabs.count
        activateTab(tabs[next])
    }

    func activatePreviousTab() {
        guard let current = activeTab,
              let idx = tabs.firstIndex(where: { $0.id == current.id }) else { return }
        let prev = idx == 0 ? tabs.count - 1 : idx - 1
        activateTab(tabs[prev])
    }

    // MARK: - Private Helpers

    private func createWebView(for tab: Tab) -> WKWebView {
        let config = WebViewConfigurationFactory.shared
        let webView = WKWebView(frame: .zero, configuration: config)
        return webView
    }

    private func loadDefaultPage(in webView: WKWebView) {
        webView.load(URLRequest(url: defaultHomeURL))
    }

    func recordCompletedNavigation(for tab: Tab, to rawURL: URL) {
        let urlString = normalizedURLString(rawURL.absoluteString)
        let entries = historyEntries(for: tab)
        let currentIndex = historyIndex(for: tab, entries: entries)

        if let pendingIndex = pendingHistoryIndexByTabID.removeValue(forKey: tab.id) {
            if entries.indices.contains(pendingIndex) {
                var updatedEntries = entries
                updatedEntries[pendingIndex] = urlString
                setHistory(updatedEntries, index: pendingIndex, for: tab)
            } else {
                appendHistoryEntry(urlString, to: tab)
            }
        } else if entries.indices.contains(currentIndex),
                  entries[currentIndex] == urlString {
            // Same-page reload or refresh.
        } else {
            appendHistoryEntry(urlString, to: tab)
        }

        tab.url = urlString
        objectWillChange.send()
        SessionManager.shared.scheduleSnapshotSave()
    }

    private func normalizedURLString(_ rawValue: String?) -> String {
        let trimmed = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty || trimmed == "about:blank" {
            return defaultHomeURLString
        }
        return trimmed
    }

    private static func normalizedHomepage(_ rawValue: String?) -> String {
        let trimmed = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return "https://google.com" }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url.absoluteString
        }
        return "https://\(trimmed)"
    }

    /// Turns user input into a URL -- either directly or via search.
    private func resolveURL(from input: String) -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Already a valid URL with scheme
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }

        // Looks like a domain
        if trimmed.contains(".") && !trimmed.contains(" ") {
            return URL(string: "https://\(trimmed)") ?? searchURL(for: trimmed)
        }

        // Fall back to search
        return searchURL(for: trimmed)
    }

    private func searchURL(for query: String) -> URL {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let engine = SettingsManager.shared.defaultSearchEngine
        let baseURL: String
        switch engine {
        case "duckduckgo":
            baseURL = "https://duckduckgo.com/?q=\(encoded)"
        case "bing":
            baseURL = "https://www.bing.com/search?q=\(encoded)"
        default:
            baseURL = "https://www.google.com/search?q=\(encoded)"
        }
        return URL(string: baseURL)!
    }

    private func closeOldestUnpinnedTab() {
        let unpinned = tabs.filter { !$0.isPinned }
        if let oldest = unpinned.min(by: { $0.lastAccessedAt < $1.lastAccessedAt }) {
            closeTab(oldest)
        }
    }

    private func appendHistoryEntry(_ urlString: String, to tab: Tab) {
        var entries = historyEntries(for: tab)
        let currentIndex = historyIndex(for: tab, entries: entries)

        if currentIndex < entries.count - 1 {
            entries.removeSubrange((currentIndex + 1)..<entries.count)
        }

        if entries.last != urlString {
            entries.append(urlString)
        } else if entries.isEmpty {
            entries = [urlString]
        }

        setHistory(entries, index: max(0, entries.count - 1), for: tab)
    }

    private func navigateHistory(for tab: Tab, direction: Int) {
        let entries = historyEntries(for: tab)
        let targetIndex = historyIndex(for: tab, entries: entries) + direction
        guard entries.indices.contains(targetIndex) else { return }

        pendingHistoryIndexByTabID[tab.id] = targetIndex

        if direction < 0, let webView = tab.webView, webView.canGoBack {
            webView.goBack()
            return
        }

        if direction > 0, let webView = tab.webView, webView.canGoForward {
            webView.goForward()
            return
        }

        guard let url = URL(string: entries[targetIndex]) else {
            pendingHistoryIndexByTabID.removeValue(forKey: tab.id)
            return
        }

        tab.webView?.load(URLRequest(url: url))
    }

    private func historyEntries(for tab: Tab) -> [String] {
        let entries = (tab.historyEntries ?? []).map(normalizedURLString).filter { !$0.isEmpty }
        if entries.isEmpty {
            return [normalizedURLString(tab.url)]
        }
        return entries
    }

    private func historyIndex(for tab: Tab, entries: [String]? = nil) -> Int {
        let entries = entries ?? historyEntries(for: tab)
        guard !entries.isEmpty else { return 0 }
        let rawIndex = tab.historyIndex ?? max(0, entries.count - 1)
        return min(max(rawIndex, 0), entries.count - 1)
    }

    private func setHistory(_ entries: [String], index: Int, for tab: Tab) {
        let normalizedEntries = entries.isEmpty ? [normalizedURLString(tab.url)] : entries
        let normalizedIndex = min(max(index, 0), normalizedEntries.count - 1)
        tab.historyEntries = normalizedEntries
        tab.historyIndex = normalizedIndex
        tab.url = normalizedEntries[normalizedIndex]
        SessionManager.shared.scheduleSnapshotSave()
    }

    private func reindex() {
        for (i, tab) in tabs.enumerated() {
            tab.order = i
        }
    }

    private func updateHomepageTabs(from oldHomepage: String, to newHomepage: String) {
        let previousHome = normalizedURLString(oldHomepage)
        let updatedHome = normalizedURLString(newHomepage)
        guard previousHome != updatedHome else { return }

        let updatedHomeURL = URL(string: updatedHome) ?? defaultHomeURL

        for tab in tabs {
            let currentURL = normalizedURLString(tab.url)
            let entries = historyEntries(for: tab)
            let isBlankTab = tab.url == "about:blank" || tab.url.isEmpty
            let isSimpleHomeTab = currentURL == previousHome && entries.count <= 1

            guard isBlankTab || isSimpleHomeTab else { continue }

            tab.url = updatedHome
            tab.historyEntries = [updatedHome]
            tab.historyIndex = 0

            if let webView = tab.webView {
                webView.load(URLRequest(url: updatedHomeURL))
            }
        }

        SessionManager.shared.scheduleSnapshotSave()
    }
}
