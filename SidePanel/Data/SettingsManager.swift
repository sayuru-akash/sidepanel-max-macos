import AppKit
import Foundation
import Combine

/// Persists user preferences via UserDefaults and publishes changes.
@MainActor
final class SettingsManager: ObservableObject {

    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    // MARK: - General

    @Published var rememberLastSession: Bool {
        didSet { defaults.set(rememberLastSession, forKey: "rememberLastSession") }
    }

    @Published var defaultSearchEngine: String {
        didSet { defaults.set(defaultSearchEngine, forKey: "defaultSearchEngine") }
    }

    @Published var homepage: String {
        didSet {
            let normalized = Self.normalizedHomepageValue(homepage)
            defaults.set(normalized, forKey: "homepage")
        }
    }

    // MARK: - Appearance

    @Published var theme: Theme {
        didSet {
            defaults.set(theme.rawValue, forKey: "theme")
            applyTheme()
        }
    }

    @Published var sidebarWidth: Double {
        didSet { defaults.set(sidebarWidth, forKey: "sidebarWidth") }
    }

    @Published var transparency: Double {
        didSet { defaults.set(transparency, forKey: "transparency") }
    }

    // MARK: - Behavior

    @Published var autoCollapseDelay: Double {
        didSet {
            defaults.set(autoCollapseDelay, forKey: "autoCollapseDelay")
            AutoCollapseManager.shared.updateDelay(autoCollapseDelay)
        }
    }

    @Published var showOnAllSpaces: Bool {
        didSet { defaults.set(showOnAllSpaces, forKey: "showOnAllSpaces") }
    }

    // MARK: - Privacy

    @Published var clearHistoryOnQuit: Bool {
        didSet { defaults.set(clearHistoryOnQuit, forKey: "clearHistoryOnQuit") }
    }

    // MARK: - Types

    enum Theme: String, CaseIterable, Identifiable {
        case auto, dark, light
        var id: String { rawValue }
    }

    // MARK: - Init

    private init() {
        // Register defaults
        let defaultValues: [String: Any] = [
            "rememberLastSession": true,
            "defaultSearchEngine": "google",
            "homepage": "https://google.com",
            "theme": Theme.auto.rawValue,
            "sidebarWidth": LayoutMetrics.defaultWidth,
            "transparency": 0.85,
            "autoCollapseDelay": 2.0,
            "showOnAllSpaces": true,
            "clearHistoryOnQuit": false
        ]
        defaults.register(defaults: defaultValues)

        // Load
        self.rememberLastSession = defaults.bool(forKey: "rememberLastSession")
        self.defaultSearchEngine = defaults.string(forKey: "defaultSearchEngine") ?? "google"
        self.homepage = Self.normalizedHomepageValue(defaults.string(forKey: "homepage") ?? "https://google.com")
        self.theme = Theme(rawValue: defaults.string(forKey: "theme") ?? "auto") ?? .auto
        self.sidebarWidth = defaults.double(forKey: "sidebarWidth")
        self.transparency = defaults.double(forKey: "transparency")
        self.autoCollapseDelay = defaults.double(forKey: "autoCollapseDelay")
        self.showOnAllSpaces = defaults.bool(forKey: "showOnAllSpaces")
        self.clearHistoryOnQuit = defaults.bool(forKey: "clearHistoryOnQuit")

        applyTheme()
    }

    /// Reset everything to factory defaults.
    func resetToDefaults() {
        let domain = Bundle.main.bundleIdentifier ?? "com.sidepanel"
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()

        // Re-init published properties
        rememberLastSession = true
        defaultSearchEngine = "google"
        homepage = "https://google.com"
        theme = .auto
        sidebarWidth = LayoutMetrics.defaultWidth
        transparency = 0.85
        autoCollapseDelay = 2.0
        showOnAllSpaces = true
        clearHistoryOnQuit = false
    }

    static func normalizedHomepageValue(_ rawValue: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "https://google.com" }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url.absoluteString
        }
        return "https://\(trimmed)"
    }

    private func applyTheme() {
        switch theme {
        case .auto:
            NSApp.appearance = nil
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        }
    }
}
