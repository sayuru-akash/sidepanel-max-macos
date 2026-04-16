import SwiftUI

/// Vertical tab strip on the left side of the panel.
struct TabBarView: View {
    @EnvironmentObject var tabManager: TabManager

    var body: some View {
        VStack(spacing: LayoutMetrics.tabSpacing) {
            // New tab button
            Button(action: { tabManager.createTab() }) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: LayoutMetrics.tabBarWidth - 8, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("New Tab")
            .accessibilityIdentifier("newTabButton")

            Divider()
                .padding(.horizontal, 8)
                .opacity(0.3)

            // Tab list
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: LayoutMetrics.tabSpacing) {
                    ForEach(tabManager.tabs, id: \.id) { tab in
                        TabButton(
                            tab: tab,
                            isActive: tabManager.activeTabId == tab.id
                        )
                    }
                    .onMove { source, destination in
                        tabManager.reorderTabs(from: source, to: destination)
                    }
                }
                .padding(.horizontal, 4)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .background(Color.tabBarBG)
    }
}
