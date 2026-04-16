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
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let granted = AXIsProcessTrustedWithOptions(options)
        guard !granted else { return }

        NSApp.activate(ignoringOtherApps: true)

        let response = NSAlert(
            messageText: "Accessibility Permission Required",
            informativeText: """
            SidePanel needs Accessibility access for global keyboard shortcuts.

            macOS should also show the system permission prompt. If it does not, open:
            System Settings > Privacy & Security > Accessibility
            """,
            buttons: ["Open System Settings", "Later"]
        ).runModal()

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

private extension NSAlert {
    convenience init(messageText: String, informativeText: String, buttons: [String]) {
        self.init()
        self.messageText = messageText
        self.informativeText = informativeText
        self.alertStyle = .informational
        buttons.forEach { addButton(withTitle: $0) }
    }
}
