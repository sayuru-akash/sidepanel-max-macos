import Foundation
import SwiftData
import WebKit

/// Persistent model for a browser tab.
@Model
final class Tab {
    @Attribute(.unique) var id: UUID
    var url: String
    var title: String
    var faviconURLString: String?
    var createdAt: Date
    var lastAccessedAt: Date
    var order: Int
    var isPinned: Bool
    var isMuted: Bool

    // MARK: - Transient (not persisted)

    @Transient var webView: WKWebView?
    @Transient var isLoading: Bool = false
    @Transient var estimatedProgress: Double = 0

    // MARK: - Computed

    var faviconURL: URL? {
        guard let s = faviconURLString else { return nil }
        return URL(string: s)
    }

    /// Builds a Google-style favicon service URL from the page URL.
    var googleFaviconURL: URL? {
        guard let host = URL(string: url)?.host else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=64")
    }

    // MARK: - Init

    init(
        url: String = "https://google.com",
        title: String = "New Tab",
        order: Int = 0
    ) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.createdAt = Date()
        self.lastAccessedAt = Date()
        self.order = order
        self.isPinned = false
        self.isMuted = false
    }
}
