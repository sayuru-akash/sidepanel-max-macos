import AppKit
import SwiftData

/// Coordinates one-time app startup that must happen even when the Swift package
/// is launched directly as a raw executable instead of a bundled .app.
@MainActor
final class AppRuntimeController: NSObject {

    static let shared = AppRuntimeController()

    let panelManager = PanelManager.shared
    let settingsManager = SettingsManager.shared
    let hotkeyManager = GlobalHotkeyManager.shared

    private let sessionManager = SessionManager.shared
    private var statusItem: NSStatusItem?
    private var hasStarted = false

    private override init() {}

    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true

        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)

        TabManager.shared.modelContext = PersistenceController.shared.container.mainContext

        sessionManager.restoreSession()
        if panelManager.currentWindowState().frame == .zero {
            panelManager.showPanel()
        }

        setupStatusItem()
        PersistenceController.shared.startAutoSave()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            if PermissionManager.checkAccessibilityPermission() {
                self.hotkeyManager.registerHotkeys()
            } else {
                PermissionManager.requestAccessibilityPermission()
            }
        }
    }

    func saveSession() {
        sessionManager.saveSession()
    }

    func reopen() {
        panelManager.showPanel()
    }

    private func setupStatusItem() {
        guard statusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "sidebar.right", accessibilityDescription: "SidePanel")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Panel", action: #selector(togglePanel), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "New Tab", action: #selector(newTab), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit SidePanel", action: #selector(quitApp), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }

        item.menu = menu
        statusItem = item
    }

    @objc private func togglePanel() {
        panelManager.toggle()
    }

    @objc private func newTab() {
        NotificationCenter.default.post(name: .newTab, object: nil)
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
