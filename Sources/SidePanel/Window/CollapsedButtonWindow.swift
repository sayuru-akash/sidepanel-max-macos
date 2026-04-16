import AppKit

/// A tiny floating window that shows the collapsed "bubble" icon
/// when the sidebar is unpinned. Clicking it toggles the panel back open.
final class CollapsedButtonWindow: NSPanel {

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
        let defaultOrigin = NSPoint(
            x: screen.maxX - size - 16,
            y: screen.midY - size / 2
        )

        self.init(
            contentRect: NSRect(origin: origin ?? defaultOrigin, size: NSSize(width: size, height: size)),
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
}
