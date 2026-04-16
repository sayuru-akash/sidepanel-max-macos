import SwiftUI

/// URL / search input bar at the top of the content area.
struct AddressBar: View {
    @EnvironmentObject var tabManager: TabManager
    @State private var urlText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Security indicator
            securityIcon
                .font(.system(size: 12))
                .frame(width: 16)

            // Text field
            TextField("Search or enter address", text: $urlText)
                .font(.addressBar)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    tabManager.navigate(to: urlText)
                    isFocused = false
                }
                .accessibilityIdentifier("addressBar")

            // Trailing button
            if isFocused {
                Button(action: { urlText = ""; isFocused = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: { tabManager.reload() }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Reload")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: LayoutMetrics.smallCornerRadius)
                .fill(Color.secondary.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutMetrics.smallCornerRadius)
                .stroke(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onChange(of: tabManager.activeTab?.url) { _, newValue in
            if !isFocused, let url = newValue {
                urlText = url
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusAddressBar)) { _ in
            isFocused = true
            // Select all text for easy replacement
            urlText = tabManager.activeTab?.url ?? ""
        }
    }

    @ViewBuilder
    private var securityIcon: some View {
        if let url = tabManager.activeTab?.url, url.hasPrefix("https://") {
            Image(systemName: "lock.fill")
                .foregroundStyle(.green)
        } else {
            Image(systemName: "lock.open")
                .foregroundStyle(.orange)
        }
    }
}
