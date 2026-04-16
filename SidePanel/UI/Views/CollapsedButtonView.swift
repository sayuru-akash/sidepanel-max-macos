import SwiftUI

/// The small circular floating icon shown when the panel is unpinned.
struct CollapsedButtonView: View {
    let onTap: () -> Void
    let onHoverEnter: () -> Void
    let onHoverExit: () -> Void

    @EnvironmentObject var tabManager: TabManager
    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(Color.collapsedBG)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)

                // Favicon or default icon
                if let tab = tabManager.activeTab {
                    FaviconImage(url: tab.faviconURL ?? tab.googleFaviconURL, size: 28)
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.accentColor)
                }

                // Hover ring
                if isHovering {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 3)
                        .transition(.opacity)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: LayoutMetrics.collapsedSize, height: LayoutMetrics.collapsedSize)
        .onHover { hovering in
            withAnimation(AnimationConfig.hoverExpand) {
                isHovering = hovering
            }
            if hovering {
                onHoverEnter()
            } else {
                onHoverExit()
            }
        }
        .accessibilityIdentifier("collapsedButton")
        .accessibilityLabel("SidePanel - click to expand")
    }
}
