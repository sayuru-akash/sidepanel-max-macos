import SwiftUI

/// Root view hosted inside the FloatingPanel.
/// Layout: vertical tab bar on the left, toolbar + webview on the right.
struct ContentView: View {
    @EnvironmentObject var panelManager: PanelManager
    @EnvironmentObject var tabManager: TabManager
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        ZStack {
            // Glass background
            GlassBackground(material: .hudWindow, opacity: settingsManager.transparency)
                .ignoresSafeArea()

            HStack(spacing: 0) {
                // Vertical tab bar
                TabBarView()
                    .frame(width: LayoutMetrics.tabBarWidth)

                Divider()
                    .opacity(0.3)

                // Main content area
                VStack(spacing: 0) {
                    ToolbarView()
                        .frame(height: LayoutMetrics.toolbarHeight)

                    // Address bar
                    AddressBar()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)

                    // Loading progress
                    if let tab = tabManager.activeTab, tab.isLoading {
                        ProgressView(value: tab.estimatedProgress)
                            .progressViewStyle(.linear)
                            .tint(.accentColor)
                            .frame(height: 2)
                    }

                    // Web content
                    WebViewContainer()
                        .clipShape(
                            RoundedRectangle(cornerRadius: LayoutMetrics.smallCornerRadius)
                        )
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                }
            }
        }
        .frame(
            minWidth: LayoutMetrics.minWidth,
            minHeight: LayoutMetrics.minHeight
        )
        .onAppear {
            // Create a default tab if none exist
            if tabManager.tabs.isEmpty {
                tabManager.createTab()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            panelManager.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .newTab)) { _ in
            tabManager.createTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .closeTab)) { _ in
            if let tab = tabManager.activeTab {
                tabManager.closeTab(tab)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .previousTab)) { _ in
            tabManager.activatePreviousTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .nextTab)) { _ in
            tabManager.activateNextTab()
        }
    }
}
