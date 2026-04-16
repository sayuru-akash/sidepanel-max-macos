import AppKit
import SwiftUI
import Combine

// MARK: - Panel State

/// Describes the three states the floating panel can be in.
enum PanelState: Equatable {
    /// Full sidebar is visible and pinned open.
    case pinned
    /// Sidebar is collapsed to a small floating icon.
    case unpinned
    /// Sidebar is temporarily visible because the user is hovering the collapsed icon.
    case temporarilyExpanded

    var showsSidebar: Bool {
        switch self {
        case .pinned, .temporarilyExpanded: return true
        case .unpinned: return false
        }
    }
}

// MARK: - Panel Manager

/// Singleton that owns and coordinates the floating panel window
/// and the collapsed-button window.
@MainActor
final class PanelManager: ObservableObject {

    static let shared = PanelManager()

    // MARK: - Published State

    @Published private(set) var state: PanelState = .pinned
    @Published var panelFrame: NSRect = .zero

    // MARK: - Windows

    private var panel: FloatingPanel?
    private var collapsedWindow: CollapsedButtonWindow?
    private var hostingController: NSHostingController<AnyView>?
    private var collapsedHostingController: NSHostingController<AnyView>?

    // MARK: - Position Memory

    /// Remembers the panel frame so it can be restored after collapsing.
    private var lastPanelFrame: NSRect?
    /// Remembers the collapsed icon position.
    private var lastCollapsedOrigin: NSPoint?

    private var frameObservers: [NSObjectProtocol] = []

    private init() {}

    // MARK: - Show / Hide

    /// Creates the floating panel (if needed) and makes it visible.
    func showPanel() {
        AutoCollapseManager.shared.stopMonitoring()

        if panel == nil {
            let floatingPanel = FloatingPanel()

            // Restore saved frame if available
            if let saved = validatedPanelFrame(lastPanelFrame) {
                floatingPanel.setFrame(saved, display: true)
            }

            let contentView = ContentView()
                .environmentObject(self)
                .environmentObject(TabManager.shared)
                .environmentObject(SettingsManager.shared)
                .modelContainer(PersistenceController.shared.container)

            let hosting = NSHostingController(rootView: AnyView(contentView))
            floatingPanel.contentView = hosting.view

            // Round corners via the content view's layer
            floatingPanel.contentView?.wantsLayer = true
            floatingPanel.contentView?.layer?.cornerRadius = LayoutMetrics.cornerRadius
            floatingPanel.contentView?.layer?.masksToBounds = true

            self.panel = floatingPanel
            self.hostingController = hosting

            // Observe window frame changes to keep panelFrame in sync
            observePanelFrame(floatingPanel)
        }

        panel?.orderFrontRegardless()
        panel?.makeKey()
        panelFrame = panel?.frame ?? .zero
        collapsedWindow?.orderOut(nil)
        state = .pinned
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Frame Observation

    private func observePanelFrame(_ window: NSPanel) {
        // Remove any existing observers
        for observer in frameObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        frameObservers.removeAll()

        let moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.syncPanelFrame()
            }
        }

        let resizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.syncPanelFrame()
            }
        }

        frameObservers = [moveObserver, resizeObserver]
    }

    private func syncPanelFrame() {
        if let frame = panel?.frame {
            panelFrame = frame
        }
    }

    private func validatedPanelFrame(_ frame: NSRect?) -> NSRect? {
        guard let frame else { return nil }
        guard frame.width >= LayoutMetrics.minWidth, frame.height >= LayoutMetrics.minHeight else {
            return nil
        }

        let visibleFrame = NSScreen.main?.visibleFrame ?? .zero
        guard !visibleFrame.isEmpty, frame.intersects(visibleFrame) else {
            return nil
        }

        return frame
    }

    /// Hides the sidebar and shows the collapsed icon instead.
    func collapse() {
        AutoCollapseManager.shared.stopMonitoring()

        // Remember where the panel was
        if let frame = panel?.frame {
            lastPanelFrame = frame
        }

        panel?.orderOut(nil)
        showCollapsedButton()
        state = .unpinned
    }

    /// Temporarily shows the sidebar (used on hover).
    func temporarilyExpand() {
        guard state == .unpinned else { return }
        AutoCollapseManager.shared.cancelCollapse()
        collapsedWindow?.orderOut(nil)
        panel?.makeKeyAndOrderFront(nil)
        panelFrame = panel?.frame ?? .zero
        state = .temporarilyExpanded
        AutoCollapseManager.shared.startMonitoring()
    }

    /// Collapses back from a temporary expansion.
    func collapseFromTemporary() {
        guard state == .temporarilyExpanded else { return }
        AutoCollapseManager.shared.stopMonitoring()
        panel?.orderOut(nil)
        showCollapsedButton()
        state = .unpinned
    }

    // MARK: - Toggle

    /// Convenience: flip between pinned and unpinned.
    func toggle() {
        switch state {
        case .pinned:
            collapse()
        case .unpinned, .temporarilyExpanded:
            showPanel()
        }
    }

    /// Pin the sidebar open (from any state).
    func pin() {
        showPanel()
    }

    /// Unpin the sidebar (collapse it).
    func unpin() {
        collapse()
    }

    // MARK: - Collapsed Button

    private func showCollapsedButton() {
        if collapsedWindow == nil {
            let window = CollapsedButtonWindow(origin: lastCollapsedOrigin)

            let buttonView = CollapsedButtonView(
                onTap: { [weak self] in
                    self?.pin()
                },
                onHoverEnter: { [weak self] in
                    self?.temporarilyExpand()
                },
                onHoverExit: {
                    AutoCollapseManager.shared.scheduleIconTransitionCollapse()
                }
            )
            .environmentObject(TabManager.shared)

            let hosting = NSHostingController(rootView: AnyView(buttonView))
            window.contentView = hosting.view

            self.collapsedWindow = window
            self.collapsedHostingController = hosting
        }

        collapsedWindow?.orderFrontRegardless()
    }

    // MARK: - Persistence Helpers

    /// Returns the current window state for session saving.
    func currentWindowState() -> (frame: NSRect, isPinned: Bool) {
        let frame = panel?.frame ?? lastPanelFrame ?? .zero
        return (frame, state == .pinned)
    }

    /// Restores window state from a saved session.
    func restoreWindowState(frame: NSRect, isPinned: Bool) {
        lastPanelFrame = validatedPanelFrame(frame)
        if isPinned {
            showPanel()
            if let frame = lastPanelFrame {
                panel?.setFrame(frame, display: true)
            }
        } else {
            collapse()
        }
    }
}
