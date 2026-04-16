import SwiftUI
import AppKit

/// A glassmorphism background using NSVisualEffectView under the hood.
struct GlassBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var opacity: Double

    init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        opacity: Double = 1
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.opacity = opacity
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.alphaValue = opacity
        view.wantsLayer = true
        view.layer?.cornerRadius = LayoutMetrics.cornerRadius
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.alphaValue = opacity
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
