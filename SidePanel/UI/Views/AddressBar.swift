import SwiftUI

/// URL / search input bar at the top of the content area.
struct AddressBar: View {
    @EnvironmentObject var tabManager: TabManager
    @ObservedObject private var historyManager = BrowsingHistoryManager.shared
    @State private var urlText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 6) {
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
                        submit(urlText)
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

            if isFocused, !suggestions.isEmpty {
                VStack(spacing: 4) {
                    ForEach(suggestions) { item in
                        Button(action: {
                            submit(item.url)
                        }) {
                            HStack(spacing: 10) {
                                FaviconImage(url: item.faviconURL, size: 16)
                                    .frame(width: 18, height: 18)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .lineLimit(1)
                                        .foregroundStyle(.primary)
                                    Text(item.host)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: LayoutMetrics.smallCornerRadius)
                        .fill(Color(nsColor: .windowBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutMetrics.smallCornerRadius)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
            }
        }
        .onAppear {
            if let url = tabManager.activeTab?.url, !isFocused {
                urlText = url
            }
        }
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

    private var suggestions: [BrowsingHistoryItem] {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        return historyManager.matches(for: trimmed, limit: 6)
            .filter { $0.url != tabManager.activeTab?.url }
    }

    private func submit(_ value: String) {
        tabManager.navigate(to: value)
        isFocused = false
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
