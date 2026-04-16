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

    // MARK: - Limits

    private let maxTabs = 50

    // MARK: - Active Tab Helper

    var activeTab: Tab? {
        tabs.first { $0.id == activeTabId }
    }

    private init() {}

    // MARK: - CRUD

    @discardableResult
    func createTab(url: URL? = nil, activate: Bool = true) -> Tab {
        if tabs.count >= maxTabs {
            closeOldestUnpinnedTab()
        }

        let tab = Tab(
            url: url?.absoluteString ?? "about:blank",
            title: "New Tab",
            order: tabs.count
        )

        tabs.append(tab)

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

        reindex()
    }

    func closeAllTabs(exceptPinned: Bool = true) {
        let toClose = exceptPinned ? tabs.filter { !$0.isPinned } : tabs
        for tab in toClose {
            tab.webView?.stopLoading()
            tab.webView = nil
        }
        if exceptPinned {
            tabs.removeAll { !$0.isPinned }
        } else {
            tabs.removeAll()
        }
        activeTabId = tabs.first?.id
        reindex()
    }

    func activateTab(_ tab: Tab) {
        activeTabId = tab.id
        tab.lastAccessedAt = Date()

        // Lazily create the web view if it was suspended.
        if tab.webView == nil {
            let webView = createWebView(for: tab)
            tab.webView = webView
            if let url = URL(string: tab.url) {
                webView.load(URLRequest(url: url))
            }
        }
    }

    func duplicateTab(_ tab: Tab) {
        createTab(url: URL(string: tab.url))
    }

    // MARK: - Reordering

    func reorderTabs(from source: IndexSet, to destination: Int) {
        tabs.move(fromOffsets: source, toOffset: destination)
        reindex()
    }

    // MARK: - Navigation Helpers

    func navigate(to urlString: String) {
        guard let tab = activeTab else {
            createTab(url: resolveURL(from: urlString))
            return
        }

        let url = resolveURL(from: urlString)
        tab.url = url.absoluteString
        tab.webView?.load(URLRequest(url: url))
    }

    func goBack() { activeTab?.webView?.goBack() }
    func goForward() { activeTab?.webView?.goForward() }
    func reload() { activeTab?.webView?.reload() }
    func stopLoading() { activeTab?.webView?.stopLoading() }

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
        let html = """
        <html>
        <head>
        <style>
            body {
                background: #1a1a1a;
                color: #888;
                font-family: -apple-system, system-ui;
                display: flex;
                align-items: center;
                justify-content: center;
                height: 100vh;
                margin: 0;
            }
            h1 { font-weight: 300; font-size: 24px; }
        </style>
        </head>
        <body><h1>SidePanel</h1></body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
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
        return URL(string: "https://www.google.com/search?q=\(encoded)")!
    }

    private func closeOldestUnpinnedTab() {
        let unpinned = tabs.filter { !$0.isPinned }
        if let oldest = unpinned.min(by: { $0.lastAccessedAt < $1.lastAccessedAt }) {
            closeTab(oldest)
        }
    }

    private func reindex() {
        for (i, tab) in tabs.enumerated() {
            tab.order = i
        }
    }
}
