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

    private init() {}

    // MARK: - Public API

    func startMonitoring() {
        stopMonitoring()

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseMove()
            }
        }
    }

    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        cancelCollapse()
    }

    /// Called when the user hovers the collapsed icon -- begins temporary expansion.
    func scheduleCollapse() {
        cancelCollapse()
        collapseTimer = Timer.scheduledTimer(withTimeInterval: collapseDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.collapseIfNeeded()
            }
        }
    }

    func cancelCollapse() {
        collapseTimer?.invalidate()
        collapseTimer = nil
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
            scheduleCollapse()
        }
    }

    private func collapseIfNeeded() {
        let panelManager = PanelManager.shared
        if panelManager.state == .temporarilyExpanded {
            panelManager.collapseFromTemporary()
        }
    }
}
