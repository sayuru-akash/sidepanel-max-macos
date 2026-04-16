import SwiftUI

struct HistoryView: View {
    @ObservedObject private var historyManager = BrowsingHistoryManager.shared
    @EnvironmentObject private var tabManager: TabManager

    @State private var query = ""

    let embeddedInPopover: Bool
    var onOpen: (() -> Void)? = nil

    init(embeddedInPopover: Bool = false, onOpen: (() -> Void)? = nil) {
        self.embeddedInPopover = embeddedInPopover
        self.onOpen = onOpen
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            searchField
            content
        }
        .padding(embeddedInPopover ? 14 : 16)
        .frame(
            width: embeddedInPopover ? 360 : 560,
            height: embeddedInPopover ? 440 : 420
        )
    }

    private var header: some View {
        HStack {
            Label("History", systemImage: "clock.arrow.circlepath")
                .font(.headline)

            Spacer()

            if !historyManager.items.isEmpty {
                Button("Clear") {
                    historyManager.clearAll()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search history", text: $query)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: LayoutMetrics.smallCornerRadius)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    private var content: some View {
        let matches = historyManager.matches(for: query, limit: embeddedInPopover ? 60 : 200)

        return Group {
            if matches.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text(query.isEmpty ? "No browsing history yet" : "No history matches")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(matches) { item in
                            HistoryRow(
                                item: item,
                                openInCurrentTab: { open(item, inNewTab: false) },
                                openInNewTab: { open(item, inNewTab: true) },
                                deleteItem: { historyManager.delete(item) }
                            )
                        }
                    }
                }
            }
        }
    }

    private func open(_ item: BrowsingHistoryItem, inNewTab: Bool) {
        if inNewTab {
            tabManager.createTab(url: URL(string: item.url))
        } else {
            tabManager.navigate(to: item.url)
        }
        onOpen?()
    }
}

private struct HistoryRow: View {
    let item: BrowsingHistoryItem
    let openInCurrentTab: () -> Void
    let openInNewTab: () -> Void
    let deleteItem: () -> Void

    var body: some View {
        Button(action: openInCurrentTab) {
            HStack(spacing: 10) {
                FaviconImage(url: item.faviconURL, size: 18)
                    .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    Text(item.host)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(item.lastVisitedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: LayoutMetrics.smallCornerRadius)
                    .fill(Color.secondary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open") {
                openInCurrentTab()
            }
            Button("Open in New Tab") {
                openInNewTab()
            }
            Divider()
            Button("Delete", role: .destructive) {
                deleteItem()
            }
        }
    }
}
