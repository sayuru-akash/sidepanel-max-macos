import AppKit

/// A borderless, always-on-top panel that hosts the sidebar browser UI.
/// Uses NSPanel so the window can float above all apps without stealing
/// focus from the frontmost application.
final class FloatingPanel: NSPanel {

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        configure()
    }

    convenience init() {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let panelHeight = screenFrame.height * 0.85
        let panelWidth: CGFloat = LayoutMetrics.defaultWidth

        // Default position: right edge, vertically centered
        let x = screenFrame.maxX - panelWidth - 12
        let y = screenFrame.midY - panelHeight / 2

        self.init(
            contentRect: NSRect(x: x, y: y, width: panelWidth, height: panelHeight),
            styleMask: [.borderless, .nonactivatingPanel, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
    }

    // MARK: - Configuration

    private func configure() {
        // Visual
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true

        // Behavior
        level = .floating
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle,
            .moveToActiveSpace
        ]
        isMovableByWindowBackground = true
        animationBehavior = .utilityWindow

        // Size constraints
        minSize = NSSize(width: LayoutMetrics.minWidth, height: LayoutMetrics.minHeight)
        maxSize = NSSize(width: LayoutMetrics.maxWidth, height: NSScreen.main?.frame.height ?? 2000)
    }

    // MARK: - Key / Main window overrides

    /// Allow becoming key so the user can type in the address bar and web views.
    override var canBecomeKey: Bool { true }

    /// Never become main window -- we don't want to steal focus from other apps.
    override var canBecomeMain: Bool { false }
}
