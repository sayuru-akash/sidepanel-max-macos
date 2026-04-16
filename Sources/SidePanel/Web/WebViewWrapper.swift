import SwiftUI
import WebKit

/// NSViewRepresentable that bridges a WKWebView into SwiftUI.
/// Each tab owns its own WKWebView instance; this wrapper simply
/// embeds it into the SwiftUI view hierarchy.
struct WebViewWrapper: NSViewRepresentable {
    let tab: Tab
    @EnvironmentObject var tabManager: TabManager

    func makeNSView(context: Context) -> WKWebView {
        let webView = tab.webView ?? WKWebView(frame: .zero, configuration: WebViewConfigurationFactory.shared)
        webView.autoresizingMask = [.width, .height]

        // Wire up coordinator
        let coordinator = context.coordinator
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        coordinator.observe(webView)

        // Store reference on the tab if needed
        if tab.webView == nil {
            tab.webView = webView
            if let url = URL(string: tab.url) {
                webView.load(URLRequest(url: url))
            }
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // If the tab's webView changed (e.g., after session restore), swap it.
        // In practice the view identity is tied to the tab, so this is a no-op
        // most of the time.
        context.coordinator.scheduleAdaptiveFit(for: nsView)
    }

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(tab: tab, tabManager: tabManager)
    }
}
