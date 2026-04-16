import SwiftUI
import AppKit

/// A glassmorphism background using NSVisualEffectView under the hood.
struct GlassBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = LayoutMetrics.cornerRadius
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

/// View modifier for easy glass backgrounds.
extension View {
    func glassBackground(
        material: NSVisualEffectView.Material = .hudWindow,
        cornerRadius: CGFloat = LayoutMetrics.cornerRadius
    ) -> some View {
        self
            .background(
                GlassBackground(material: material)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
    }
}
