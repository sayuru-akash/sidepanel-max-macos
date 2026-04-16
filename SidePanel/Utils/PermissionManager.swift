import AppKit
import ApplicationServices

/// Handles checking and requesting macOS Accessibility permission,
/// which is required for global keyboard shortcuts.
enum PermissionManager {

    /// Returns true if the app already has Accessibility permission.
    static func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Triggers the system prompt without blocking app startup.
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilityPreferences() {
        let preferenceURLs = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.Settings.PrivacySecurity.extension?Privacy_Accessibility"
        ]

        for preferenceURL in preferenceURLs {
            if let url = URL(string: preferenceURL), NSWorkspace.shared.open(url) {
                return
            }
        }

        if let settingsURL = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity") {
            _ = NSWorkspace.shared.open(settingsURL)
        }
    }
}
