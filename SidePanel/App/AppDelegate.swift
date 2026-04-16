import AppKit
import SwiftUI
import Combine

/// Manages the application lifecycle.
/// Creates the floating panel on launch and coordinates top-level managers.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Managers

    let panelManager = PanelManager.shared
    let settingsManager = SettingsManager.shared
    let hotkeyManager = GlobalHotkeyManager.shared
    private let sessionManager = SessionManager.shared

    // MARK: - Status Bar

    private var statusItem: NSStatusItem?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon (belt-and-suspenders; also set via LSUIElement)
        NSApp.setActivationPolicy(.accessory)

        // Wire SwiftData ModelContext into TabManager so Tab inserts/deletes persist
        TabManager.shared.modelContext = PersistenceController.shared.container.mainContext

        // Restore previous session (tabs, window position, pin state)
        sessionManager.restoreSession()

        // Show the floating panel
        panelManager.showPanel()

        // Register global keyboard shortcuts
        if PermissionManager.checkAccessibilityPermission() {
            hotkeyManager.registerHotkeys()
        } else {
            PermissionManager.requestAccessibilityPermission()
        }

        // Set up the menu-bar status item
        setupStatusItem()

        // Start auto-save timer
        PersistenceController.shared.startAutoSave()
    }

    func applicationWillTerminate(_ notification: Notification) {
        sessionManager.saveSession()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panelManager.showPanel()
        return true
    }

    // MARK: - Status Bar Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sidebar.right", accessibilityDescription: "SidePanel")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Panel", action: #selector(togglePanel), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "New Tab", action: #selector(newTab), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit SidePanel", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    // MARK: - Menu Actions

    @objc private func togglePanel() {
        panelManager.toggle()
    }

    @objc private func newTab() {
        NotificationCenter.default.post(name: .newTab, object: nil)
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
