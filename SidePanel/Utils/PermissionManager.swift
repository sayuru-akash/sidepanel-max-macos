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

    /// Shows an explanation alert and opens System Preferences if the user agrees.
    static func requestAccessibilityPermission() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
        SidePanel needs Accessibility access to:

        - Register global keyboard shortcuts
        - Stay visible across all applications

        You can grant this in System Settings > Privacy & Security > Accessibility.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openAccessibilityPreferences()
        }
    }

    // MARK: - Private

    private static func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
