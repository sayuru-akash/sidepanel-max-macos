import Foundation

struct BrowsingHistoryItem: Codable, Identifiable, Equatable {
    var id: UUID
    var url: String
    var title: String
    var faviconURLString: String?
    var lastVisitedAt: Date

    init(
        id: UUID = UUID(),
        url: String,
        title: String,
        faviconURLString: String? = nil,
        lastVisitedAt: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.faviconURLString = faviconURLString
        self.lastVisitedAt = lastVisitedAt
    }

    var host: String {
        URL(string: url)?.host() ?? url
    }

    var faviconURL: URL? {
        guard let faviconURLString, !faviconURLString.isEmpty else { return nil }
        return URL(string: faviconURLString)
    }
}

@MainActor
final class BrowsingHistoryManager: ObservableObject {

    static let shared = BrowsingHistoryManager()

    @Published private(set) var items: [BrowsingHistoryItem] = []

    private let defaults = UserDefaults.standard
    private let storageKey = "browsingHistoryItems"
    private let maxItems = 500

    private init() {
        load()
    }

    func recordVisit(url: URL, title: String?, faviconURLString: String?) {
        guard let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else { return }

        let normalizedURL = url.absoluteString
        let normalizedTitle = normalizedDisplayTitle(from: title, fallbackURL: normalizedURL)
        let now = Date()

        if let existingIndex = items.firstIndex(where: { $0.url == normalizedURL }) {
            var existing = items.remove(at: existingIndex)
            existing.title = normalizedTitle
            existing.faviconURLString = faviconURLString ?? existing.faviconURLString
            existing.lastVisitedAt = now
            items.insert(existing, at: 0)
        } else {
            let item = BrowsingHistoryItem(
                url: normalizedURL,
                title: normalizedTitle,
                faviconURLString: faviconURLString,
                lastVisitedAt: now
            )
            items.insert(item, at: 0)
        }

        if items.count > maxItems {
            items.removeLast(items.count - maxItems)
        }

        persist()
    }

    func matches(for query: String, limit: Int = 8) -> [BrowsingHistoryItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Array(items.prefix(limit))
        }

        let lowered = trimmed.lowercased()
        return items
            .filter {
                $0.title.lowercased().contains(lowered) ||
                $0.url.lowercased().contains(lowered) ||
                $0.host.lowercased().contains(lowered)
            }
            .prefix(limit)
            .map { $0 }
    }

    func delete(_ item: BrowsingHistoryItem) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    func clearAll() {
        items.removeAll()
        persist()
    }

    private func normalizedDisplayTitle(from title: String?, fallbackURL: String) -> String {
        let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty {
            return trimmed
        }

        return URL(string: fallbackURL)?.host() ?? fallbackURL
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([BrowsingHistoryItem].self, from: data) else {
            items = []
            return
        }
        items = decoded.sorted { $0.lastVisitedAt > $1.lastVisitedAt }
    }
}
