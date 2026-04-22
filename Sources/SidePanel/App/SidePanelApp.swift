import SwiftUI

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

    var body: some Scene {
        // Keep an inert hidden scene so App runtime stays alive without opening
        // a SwiftUI Settings scene automatically on launch.
        MenuBarExtra("SidePanel", systemImage: "sidebar.right", isInserted: .constant(false)) {
            EmptyView()
        }
    }
}
