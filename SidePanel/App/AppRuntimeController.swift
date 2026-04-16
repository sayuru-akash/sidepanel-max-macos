import AppKit
import Darwin
import SwiftUI
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
    private var settingsWindow: NSWindow?
    private var terminationSignalSources: [DispatchSourceSignal] = []
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
        sessionManager.startObservingSessionState()
        installTerminationSignalHandlers()
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

    func showSettingsWindow() {
        let window = settingsWindow ?? makeSettingsWindow()
        settingsWindow = window

        NSApp.activate(ignoringOtherApps: true)
        positionSettingsWindow(window)
        window.makeKeyAndOrderFront(nil)
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
        showSettingsWindow()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func makeSettingsWindow() -> NSWindow {
        let rootView = SettingsView()
            .environmentObject(settingsManager)
            .modelContainer(PersistenceController.shared.container)

        let hostingController = NSHostingController(rootView: rootView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .preference
        window.contentViewController = hostingController
        window.setContentSize(NSSize(width: 720, height: 500))
        return window
    }

    private func positionSettingsWindow(_ window: NSWindow) {
        let windowSize = window.frame.size

        if panelManager.panelFrame != .zero,
           let screen = visibleFrame(containing: panelManager.panelFrame) {
            let panelFrame = panelManager.panelFrame
            var origin = NSPoint(
                x: panelFrame.minX - windowSize.width - 18,
                y: panelFrame.maxY - windowSize.height
            )

            if origin.x < screen.minX + 12 {
                origin.x = min(screen.maxX - windowSize.width - 12, panelFrame.maxX + 18)
            }

            origin.x = min(max(origin.x, screen.minX + 12), screen.maxX - windowSize.width - 12)
            origin.y = min(max(origin.y, screen.minY + 12), screen.maxY - windowSize.height - 12)

            window.setFrameOrigin(origin)
        } else {
            window.centerIfNeeded()
        }
    }

    private func visibleFrame(containing frame: NSRect) -> NSRect? {
        NSScreen.screens
            .map(\.visibleFrame)
            .first(where: {
                $0.intersects(frame) ||
                $0.contains(frame.origin) ||
                $0.contains(NSPoint(x: frame.maxX, y: frame.maxY))
            })
    }

    private func installTerminationSignalHandlers() {
        guard terminationSignalSources.isEmpty else { return }

        for signalNumber in [SIGINT, SIGTERM] {
            signal(signalNumber, SIG_IGN)

            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
            source.setEventHandler { [weak self] in
                guard let self else { return }
                self.saveSession()
                signal(signalNumber, SIG_DFL)
                kill(getpid(), signalNumber)
            }
            source.resume()
            terminationSignalSources.append(source)
        }
    }
}

private extension NSWindow {
    func centerIfNeeded() {
        if frame.origin == .zero {
            center()
        }
    }
}
