import SwiftUI

/// A single tab in the vertical tab bar.
/// Shows the favicon; on hover reveals the close button and title tooltip.
struct TabButton: View {
    let tab: Tab
    let isActive: Bool

    @EnvironmentObject var tabManager: TabManager
    @State private var isHovering = false

    var body: some View {
        Button(action: { tabManager.activateTab(tab) }) {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutMetrics.smallCornerRadius)
                    .fill(backgroundColor)

                HStack(spacing: 0) {
                    FaviconImage(url: tab.faviconURL ?? tab.googleFaviconURL)

                    if isHovering {
                        Spacer()

                        Button(action: { tabManager.closeTab(tab) }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 16, height: 16)
                                .background(
                                    Circle().fill(Color.secondary.opacity(0.15))
                                )
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(.horizontal, 8)

                // Active indicator line
                if isActive {
                    HStack {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.accentColor)
                            .frame(width: 3, height: 20)
                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: LayoutMetrics.tabBarWidth - 8, height: LayoutMetrics.tabHeight)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(AnimationConfig.hoverExpand) {
                isHovering = hovering
            }
        }
        .help(tab.title)
        .accessibilityIdentifier("tabButton")
        .contextMenu {
            Button("Close Tab") { tabManager.closeTab(tab) }
                .disabled(tab.isPinned)
            Button("Duplicate Tab") { tabManager.duplicateTab(tab) }
            Divider()
            Button(tab.isPinned ? "Unpin Tab" : "Pin Tab") {
                tabManager.setPinned(!tab.isPinned, for: tab)
            }
        }
    }

    private var backgroundColor: Color {
        if isActive { return .tabActive }
        if isHovering { return .tabHover }
        return .clear
    }
}
