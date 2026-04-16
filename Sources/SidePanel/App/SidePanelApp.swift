import SwiftUI
import SwiftData

/// Main entry point for SidePanel.
/// Uses LSUIElement = true (set in Info.plist) so the app
/// does not appear in the Dock or the Cmd-Tab switcher.
@main
struct SidePanelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        DispatchQueue.main.async {
            AppRuntimeController.shared.startIfNeeded()
        }
    }

    /// Wire the SwiftData ModelContainer so Tab objects are managed
    /// by a real ModelContext and auto-save actually persists data.
    var sharedModelContainer: ModelContainer {
        PersistenceController.shared.container
    }

    var body: some Scene {
        // Settings window – opened via the menu bar or gear button
        Settings {
            SettingsView()
                .environmentObject(SettingsManager.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
