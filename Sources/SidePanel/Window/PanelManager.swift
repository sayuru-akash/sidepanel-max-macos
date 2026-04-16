import AppKit
import SwiftUI
import Combine
import QuartzCore

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
    private var collapsedMoveObserver: NSObjectProtocol?
    private var cancellables: Set<AnyCancellable> = []
    private let hoverTransitionDuration: TimeInterval = 0.14
    private let hoverSlideOffset: CGFloat = 18
    private let minimumHoverReachDelay: TimeInterval = 0.18
    private let maximumHoverReachDelay: TimeInterval = 0.75
    private let hoverReachPixelsPerSecond: CGFloat = 1400

    private init() {
        bindSettings()
    }

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

        applyWindowPreferences()

        animateWindowIn(panel, makeKey: true)
        animateWindowOut(collapsedWindow)
        panelFrame = panel?.frame ?? .zero
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
            lastPanelFrame = frame

            if state == .temporarilyExpanded {
                let attachedOrigin = collapsedOrigin(for: frame)
                lastCollapsedOrigin = attachedOrigin
                collapsedWindow?.setFrameOrigin(attachedOrigin)
                AutoCollapseManager.shared.cancelCollapse()
            }
        }
    }

    private func validatedPanelFrame(_ frame: NSRect?) -> NSRect? {
        guard let frame else { return nil }
        guard frame.width >= LayoutMetrics.minWidth, frame.height >= LayoutMetrics.minHeight else {
            return nil
        }

        guard let visibleFrame = visibleFrame(containing: frame), frame.intersects(visibleFrame) else {
            return nil
        }

        return frame
    }

    private func validatedCollapsedOrigin(_ origin: NSPoint?, fallbackPanelFrame: NSRect?) -> NSPoint? {
        if let origin {
            let candidateRect = NSRect(
                origin: origin,
                size: NSSize(width: LayoutMetrics.collapsedSize, height: LayoutMetrics.collapsedSize)
            )

            if let visibleFrame = visibleFrame(containing: candidateRect),
               visibleFrame.contains(candidateRect) {
                return origin
            }
        }

        guard let fallbackPanelFrame else { return nil }
        return collapsedOrigin(for: fallbackPanelFrame)
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

    private func collapsedOrigin(for panelFrame: NSRect) -> NSPoint {
        let size = LayoutMetrics.collapsedSize
        let fallbackFrame = NSScreen.main?.visibleFrame ?? .zero
        let screenFrame = visibleFrame(containing: panelFrame) ?? fallbackFrame

        let proposedOrigin = NSPoint(
            x: panelFrame.maxX - size - 12,
            y: panelFrame.midY - size / 2
        )

        guard !screenFrame.isEmpty else { return proposedOrigin }

        return NSPoint(
            x: min(max(proposedOrigin.x, screenFrame.minX + 12), screenFrame.maxX - size - 12),
            y: min(max(proposedOrigin.y, screenFrame.minY + 12), screenFrame.maxY - size - 12)
        )
    }

    private func currentCollapsedFrame() -> NSRect? {
        if let collapsedWindow {
            return collapsedWindow.frame
        }

        guard let origin = lastCollapsedOrigin else { return nil }
        return NSRect(
            origin: origin,
            size: NSSize(width: LayoutMetrics.collapsedSize, height: LayoutMetrics.collapsedSize)
        )
    }

    private func hoverReachDelay() -> TimeInterval {
        guard let collapsedFrame = currentCollapsedFrame() else {
            return minimumHoverReachDelay
        }

        let targetFrame = panel?.frame ?? panelFrame
        guard targetFrame != .zero else { return minimumHoverReachDelay }

        let horizontalGap = max(0, max(targetFrame.minX - collapsedFrame.maxX, collapsedFrame.minX - targetFrame.maxX))
        let verticalGap = max(0, max(targetFrame.minY - collapsedFrame.maxY, collapsedFrame.minY - targetFrame.maxY))
        let distance = hypot(horizontalGap, verticalGap)
        let adaptiveDelay = minimumHoverReachDelay + TimeInterval(distance / hoverReachPixelsPerSecond)

        return min(maximumHoverReachDelay, adaptiveDelay)
    }

    /// Hides the sidebar and shows the collapsed icon instead.
    func collapse() {
        AutoCollapseManager.shared.stopMonitoring()

        // Remember where the panel was
        if let frame = panel?.frame {
            lastPanelFrame = frame
            lastCollapsedOrigin = collapsedOrigin(for: frame)
        }

        showCollapsedButton()
        animateWindowOut(panel)
        animateWindowIn(collapsedWindow)
        state = .unpinned
    }

    /// Temporarily shows the sidebar (used on hover).
    func temporarilyExpand() {
        guard state == .unpinned else { return }
        AutoCollapseManager.shared.cancelCollapse()
        animateTemporaryExpand()
        panelFrame = panel?.frame ?? .zero
        state = .temporarilyExpanded
        AutoCollapseManager.shared.startMonitoring()
    }

    /// Collapses back from a temporary expansion.
    func collapseFromTemporary() {
        guard state == .temporarilyExpanded else { return }
        AutoCollapseManager.shared.stopMonitoring()
        showCollapsedButton()
        animateTemporaryCollapse()
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
                onHoverExit: { [weak self] in
                    let delay = self?.hoverReachDelay() ?? self?.minimumHoverReachDelay
                    AutoCollapseManager.shared.scheduleIconTransitionCollapse(after: delay)
                }
            )
            .environmentObject(TabManager.shared)

            let hosting = NSHostingController(rootView: AnyView(buttonView))
            window.contentView = hosting.view

            self.collapsedWindow = window
            self.collapsedHostingController = hosting
            observeCollapsedWindowFrame(window)
        }

        applyWindowPreferences()
    }

    private func observeCollapsedWindowFrame(_ window: NSWindow) {
        if let collapsedMoveObserver {
            NotificationCenter.default.removeObserver(collapsedMoveObserver)
        }

        collapsedMoveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.lastCollapsedOrigin = window.frame.origin
            }
        }
    }

    private func animateWindowIn(_ window: NSWindow?, makeKey: Bool = false) {
        guard let window else { return }

        window.alphaValue = 0
        window.orderFrontRegardless()
        if makeKey {
            window.makeKey()
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = hoverTransitionDuration
            window.animator().alphaValue = 1
        }
    }

    private func animateWindowOut(_ window: NSWindow?) {
        guard let window, window.isVisible else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = hoverTransitionDuration
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
            window.alphaValue = 1
        })
    }

    private func animateTemporaryExpand() {
        guard let panel else { return }

        let targetFrame = panel.frame
        let startFrame = targetFrame.offsetBy(dx: hoverSlideOffset, dy: 0)

        panel.setFrame(startFrame, display: false)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()

        if let collapsedWindow, collapsedWindow.isVisible {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = hoverTransitionDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                collapsedWindow.animator().alphaValue = 0
            } completionHandler: {
                collapsedWindow.orderOut(nil)
                collapsedWindow.alphaValue = 1
            }
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = hoverTransitionDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(targetFrame, display: true)
            panel.animator().alphaValue = 1
        }
    }

    private func animateTemporaryCollapse() {
        guard let panel else { return }

        let stableFrame = panel.frame
        let endFrame = stableFrame.offsetBy(dx: hoverSlideOffset, dy: 0)

        if let collapsedWindow {
            collapsedWindow.alphaValue = 0
            collapsedWindow.orderFrontRegardless()

            NSAnimationContext.runAnimationGroup { context in
                context.duration = hoverTransitionDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                collapsedWindow.animator().alphaValue = 1
            }
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = hoverTransitionDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(endFrame, display: true)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
            panel.alphaValue = 1
            panel.setFrame(stableFrame, display: false)
        })
    }

    private func bindSettings() {
        let settings = SettingsManager.shared

        settings.$sidebarWidth
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] width in
                self?.applySidebarWidth(width)
            }
            .store(in: &cancellables)

        settings.$showOnAllSpaces
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyWindowPreferences()
            }
            .store(in: &cancellables)
    }

    private func applySidebarWidth(_ width: Double) {
        let clampedWidth = min(max(CGFloat(width), LayoutMetrics.minWidth), LayoutMetrics.maxWidth)

        if var frame = lastPanelFrame {
            let maxX = frame.maxX
            frame.size.width = clampedWidth
            frame.origin.x = maxX - clampedWidth
            lastPanelFrame = frame
        }

        guard let panel else { return }

        var frame = panel.frame
        let maxX = frame.maxX
        frame.size.width = clampedWidth
        frame.origin.x = maxX - clampedWidth
        panel.setFrame(frame, display: true, animate: true)
        panelFrame = frame
        lastPanelFrame = frame
    }

    private func applyWindowPreferences() {
        let behavior = collectionBehavior(showOnAllSpaces: SettingsManager.shared.showOnAllSpaces)
        panel?.collectionBehavior = behavior
        collapsedWindow?.collectionBehavior = behavior
    }

    private func collectionBehavior(showOnAllSpaces: Bool) -> NSWindow.CollectionBehavior {
        if showOnAllSpaces {
            return [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        }
        return [.moveToActiveSpace, .fullScreenAuxiliary, .ignoresCycle]
    }

    // MARK: - Persistence Helpers

    /// Returns the current window state for session saving.
    func currentWindowState() -> (frame: NSRect, isPinned: Bool, collapsedOrigin: NSPoint?) {
        let frame = panel?.frame ?? lastPanelFrame ?? .zero
        let collapsedOrigin = collapsedWindow?.frame.origin ?? lastCollapsedOrigin
        return (frame, state == .pinned, collapsedOrigin)
    }

    /// Restores window state from a saved session.
    func restoreWindowState(frame: NSRect, isPinned: Bool, collapsedOrigin: NSPoint?) {
        lastPanelFrame = validatedPanelFrame(frame)
        lastCollapsedOrigin = validatedCollapsedOrigin(collapsedOrigin, fallbackPanelFrame: lastPanelFrame)
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
