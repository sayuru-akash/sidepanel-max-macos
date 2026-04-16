import Foundation

/// Saves and restores the complete app session (tabs, window position, pin state)
/// using UserDefaults for lightweight persistence.
@MainActor
final class SessionManager {

    static let shared = SessionManager()

    private let defaults = UserDefaults.standard
    private let tabsKey = "savedTabs"
    private let windowFrameKey = "savedWindowFrame"
    private let isPinnedKey = "savedIsPinned"

    private init() {}

    // MARK: - Save

    func saveSession() {
        saveTabs()
        saveWindowState()
    }

    // MARK: - Restore

    func restoreSession() {
        guard SettingsManager.shared.rememberLastSession else { return }
        restoreTabs()
        restoreWindowState()
    }

    // MARK: - Tabs

    private func saveTabs() {
        let tabManager = TabManager.shared
        let tabData: [[String: Any]] = tabManager.tabs.map { tab in
            [
                "id": tab.id.uuidString,
                "url": tab.url,
                "title": tab.title,
                "faviconURL": tab.faviconURLString ?? "",
                "order": tab.order,
                "isPinned": tab.isPinned
            ]
        }
        defaults.set(tabData, forKey: tabsKey)
        defaults.set(tabManager.activeTabId?.uuidString ?? "", forKey: "activeTabId")
    }

    private func restoreTabs() {
        guard let tabData = defaults.array(forKey: tabsKey) as? [[String: Any]] else { return }
        let tabManager = TabManager.shared

        for data in tabData {
            guard let urlString = data["url"] as? String,
                  let url = URL(string: urlString) else { continue }

            let tab = tabManager.createTab(url: url, activate: false)
            tab.title = data["title"] as? String ?? "Untitled"
            tab.isPinned = data["isPinned"] as? Bool ?? false
            tab.order = data["order"] as? Int ?? 0

            if let favicon = data["faviconURL"] as? String, !favicon.isEmpty {
                tab.faviconURLString = favicon
            }
        }

        // Restore active tab by saved order index, since createTab() generates
        // new UUIDs and the old UUID no longer matches any tab.
        if let activeIdString = defaults.string(forKey: "activeTabId"),
           let savedTabData = defaults.array(forKey: tabsKey) as? [[String: Any]],
           let activeIndex = savedTabData.firstIndex(where: {
               ($0["id"] as? String) == activeIdString
           }),
           activeIndex < tabManager.tabs.count {
            tabManager.activateTab(tabManager.tabs[activeIndex])
        } else if let first = tabManager.tabs.first {
            tabManager.activateTab(first)
        }
    }

    // MARK: - Window State

    private func saveWindowState() {
        let (frame, isPinned) = PanelManager.shared.currentWindowState()
        let frameDict: [String: Double] = [
            "x": frame.origin.x,
            "y": frame.origin.y,
            "w": frame.size.width,
            "h": frame.size.height
        ]
        defaults.set(frameDict, forKey: windowFrameKey)
        defaults.set(isPinned, forKey: isPinnedKey)
    }

    private func restoreWindowState() {
        guard let frameDict = defaults.dictionary(forKey: windowFrameKey) as? [String: Double] else { return }
        let frame = NSRect(
            x: frameDict["x"] ?? 0,
            y: frameDict["y"] ?? 0,
            width: frameDict["w"] ?? LayoutMetrics.defaultWidth,
            height: frameDict["h"] ?? LayoutMetrics.defaultHeight
        )
        let isPinned = defaults.bool(forKey: isPinnedKey)
        PanelManager.shared.restoreWindowState(frame: frame, isPinned: isPinned)
    }
}
