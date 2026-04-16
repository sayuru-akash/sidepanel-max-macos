import AppKit
import Combine

/// Monitors the mouse position and auto-collapses the panel
/// when the cursor leaves the panel area after a configurable delay.
@MainActor
final class AutoCollapseManager: ObservableObject {

    static let shared = AutoCollapseManager()

    @Published var isHovering: Bool = false

    private var collapseTimer: Timer?
    private var collapseDelay: TimeInterval = 2.0
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var pendingDelay: TimeInterval?

    private let iconTransitionDelay: TimeInterval = 0.18
    private let temporaryPanelExitDelayCap: TimeInterval = 0.35

    private init() {}

    // MARK: - Public API

    func startMonitoring() {
        stopMonitoring()

        let eventMask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] _ in
            Task { @MainActor in
                self?.handleMouseMove()
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseMove()
            }
            return event
        }
    }

    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        cancelCollapse()
    }

    func scheduleCollapse() {
        scheduleCollapse(after: collapseDelay)
    }

    /// Small grace period so moving from the icon into the expanded panel does not flicker closed.
    func scheduleIconTransitionCollapse() {
        scheduleCollapse(after: iconTransitionDelay)
    }

    /// Keep temporary hover-open behavior responsive even if the general preference is larger.
    func scheduleTemporaryPanelExitCollapse() {
        scheduleCollapse(after: min(collapseDelay, temporaryPanelExitDelayCap))
    }

    func cancelCollapse() {
        collapseTimer?.invalidate()
        collapseTimer = nil
        pendingDelay = nil
    }

    func updateDelay(_ seconds: TimeInterval) {
        collapseDelay = seconds
    }

    // MARK: - Private

    private func handleMouseMove() {
        let panelManager = PanelManager.shared
        guard panelManager.state == .temporarilyExpanded else { return }

        // If the mouse is over the panel, cancel any pending collapse.
        // Otherwise schedule one.
        let mouseLocation = NSEvent.mouseLocation

        if let panelFrame = panelManager.panelFrame as NSRect?,
           panelFrame.contains(mouseLocation) {
            cancelCollapse()
        } else {
            scheduleTemporaryPanelExitCollapse()
        }
    }

    private func scheduleCollapse(after delay: TimeInterval) {
        if let pendingDelay, abs(pendingDelay - delay) < 0.001, collapseTimer != nil {
            return
        }

        cancelCollapse()
        pendingDelay = delay
        collapseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.collapseIfNeeded()
            }
        }
    }

    private func collapseIfNeeded() {
        let panelManager = PanelManager.shared
        if panelManager.state == .temporarilyExpanded {
            panelManager.collapseFromTemporary()
        }
    }
}
