import SwiftUI

/// Loads and displays a website favicon with a globe fallback.
struct FaviconImage: View {
    let url: URL?
    var size: CGFloat = LayoutMetrics.tabIconSize

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        fallbackIcon
                    case .empty:
                        ProgressView()
                            .controlSize(.small)
                    @unknown default:
                        fallbackIcon
                    }
                }
            } else {
                fallbackIcon
            }
        }
        .frame(width: size, height: size)
    }

    private var fallbackIcon: some View {
        Image(systemName: "globe")
            .font(.system(size: size * 0.7))
            .foregroundStyle(.secondary)
    }
}
