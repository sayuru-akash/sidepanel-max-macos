import Foundation
import Combine

/// Persists user preferences via UserDefaults and publishes changes.
final class SettingsManager: ObservableObject {

    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    // MARK: - General

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: "launchAtLogin") }
    }

    @Published var rememberLastSession: Bool {
        didSet { defaults.set(rememberLastSession, forKey: "rememberLastSession") }
    }

    @Published var defaultSearchEngine: String {
        didSet { defaults.set(defaultSearchEngine, forKey: "defaultSearchEngine") }
    }

    // MARK: - Appearance

    @Published var theme: Theme {
        didSet { defaults.set(theme.rawValue, forKey: "theme") }
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

    @Published var doNotTrack: Bool {
        didSet { defaults.set(doNotTrack, forKey: "doNotTrack") }
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
            "launchAtLogin": false,
            "rememberLastSession": true,
            "defaultSearchEngine": "google",
            "theme": Theme.auto.rawValue,
            "sidebarWidth": LayoutMetrics.defaultWidth,
            "transparency": 0.85,
            "autoCollapseDelay": 2.0,
            "showOnAllSpaces": true,
            "clearHistoryOnQuit": false,
            "doNotTrack": true
        ]
        defaults.register(defaults: defaultValues)

        // Load
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.rememberLastSession = defaults.bool(forKey: "rememberLastSession")
        self.defaultSearchEngine = defaults.string(forKey: "defaultSearchEngine") ?? "google"
        self.theme = Theme(rawValue: defaults.string(forKey: "theme") ?? "auto") ?? .auto
        self.sidebarWidth = defaults.double(forKey: "sidebarWidth")
        self.transparency = defaults.double(forKey: "transparency")
        self.autoCollapseDelay = defaults.double(forKey: "autoCollapseDelay")
        self.showOnAllSpaces = defaults.bool(forKey: "showOnAllSpaces")
        self.clearHistoryOnQuit = defaults.bool(forKey: "clearHistoryOnQuit")
        self.doNotTrack = defaults.bool(forKey: "doNotTrack")
    }

    /// Reset everything to factory defaults.
    func resetToDefaults() {
        let domain = Bundle.main.bundleIdentifier ?? "com.sidepanel"
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()

        // Re-init published properties
        launchAtLogin = false
        rememberLastSession = true
        defaultSearchEngine = "google"
        theme = .auto
        sidebarWidth = LayoutMetrics.defaultWidth
        transparency = 0.85
        autoCollapseDelay = 2.0
        showOnAllSpaces = true
        clearHistoryOnQuit = false
        doNotTrack = true
    }
}
