import SwiftUI

/// Displays the WKWebView for the currently active tab.
/// Swaps the underlying web view whenever the active tab changes.
struct WebViewContainer: View {
    @EnvironmentObject var tabManager: TabManager

    var body: some View {
        Group {
            if let tab = tabManager.activeTab {
                WebViewWrapper(tab: tab)
                    .id(tab.id)  // Force new view when tab changes
                    .accessibilityIdentifier("webViewContainer")
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(.tertiary)
            Text("No tabs open")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("New Tab") {
                tabManager.createTab()
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
