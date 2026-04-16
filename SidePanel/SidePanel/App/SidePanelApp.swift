import SwiftUI
import SwiftData

/// Main entry point for SidePanel.
/// Uses LSUIElement = true (set in Info.plist) so the app
/// does not appear in the Dock or the Cmd-Tab switcher.
@main
struct SidePanelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Settings window – opened via the menu bar or gear button
        Settings {
            SettingsView()
                .environmentObject(appDelegate.settingsManager)
        }
    }
}
