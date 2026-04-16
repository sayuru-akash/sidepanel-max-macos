import AppKit

/// Manages the application lifecycle.
/// Handles system callbacks while startup is coordinated by AppRuntimeController.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppRuntimeController.shared.startIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppRuntimeController.shared.saveSession()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        AppRuntimeController.shared.reopen()
        return true
    }
}
