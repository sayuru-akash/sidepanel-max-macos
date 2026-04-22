import AppKit

/// A tiny floating window that shows the collapsed "bubble" icon
/// when the sidebar is unpinned. Clicking it toggles the panel back open.
final class CollapsedButtonWindow: NSPanel {

    var visualOrigin: NSPoint {
        Self.visualOrigin(forWindowOrigin: frame.origin)
    }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configure()
    }

    convenience init(origin: NSPoint? = nil) {
        let size = LayoutMetrics.collapsedSize
        let screen = NSScreen.main?.visibleFrame ?? .zero
        let defaultVisualOrigin = NSPoint(
            x: screen.maxX - size - 16,
            y: screen.midY - size / 2
        )
        let visualOrigin = origin ?? defaultVisualOrigin
        let windowOrigin = Self.windowOrigin(forVisualOrigin: visualOrigin)
        let windowSize = LayoutMetrics.collapsedWindowSize

        self.init(
            contentRect: NSRect(
                origin: windowOrigin,
                size: NSSize(width: windowSize, height: windowSize)
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
    }

    // MARK: - Configuration

    private func configure() {
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        level = .floating
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
        acceptsMouseMovedEvents = true
        isMovableByWindowBackground = true
        animationBehavior = .utilityWindow
    }

    // MARK: - Overrides

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func setVisualOrigin(_ origin: NSPoint) {
        setFrameOrigin(Self.windowOrigin(forVisualOrigin: origin))
    }

    static func windowOrigin(forVisualOrigin origin: NSPoint) -> NSPoint {
        let padding = LayoutMetrics.collapsedShadowPadding
        return NSPoint(x: origin.x - padding, y: origin.y - padding)
    }

    static func visualOrigin(forWindowOrigin origin: NSPoint) -> NSPoint {
        let padding = LayoutMetrics.collapsedShadowPadding
        return NSPoint(x: origin.x + padding, y: origin.y + padding)
    }
}
