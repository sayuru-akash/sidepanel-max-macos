import WebKit
import Combine

/// Acts as the WKNavigationDelegate and WKUIDelegate for a tab's WKWebView.
/// Publishes navigation events back to the owning Tab model.
@MainActor
final class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {

    private let tab: Tab
    private let tabManager: TabManager
    private var progressObservation: NSKeyValueObservation?
    private var titleObservation: NSKeyValueObservation?
    private var urlObservation: NSKeyValueObservation?

    init(tab: Tab, tabManager: TabManager) {
        self.tab = tab
        self.tabManager = tabManager
        super.init()
    }

    // MARK: - KVO Setup

    /// Call once after the WKWebView is created to start observing properties.
    func observe(_ webView: WKWebView) {
        progressObservation = webView.observe(\.estimatedProgress, options: .new) { [weak self] wv, _ in
            Task { @MainActor [weak self] in
                self?.tab.estimatedProgress = wv.estimatedProgress
                self?.tab.isLoading = wv.isLoading
            }
        }

        titleObservation = webView.observe(\.title, options: .new) { [weak self] wv, _ in
            Task { @MainActor [weak self] in
                if let title = wv.title, !title.isEmpty {
                    self?.tab.title = title
                }
            }
        }

        urlObservation = webView.observe(\.url, options: .new) { [weak self] wv, _ in
            Task { @MainActor [weak self] in
                if let url = wv.url?.absoluteString {
                    self?.tab.url = url
                }
            }
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        tab.isLoading = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        tab.isLoading = false
        tab.estimatedProgress = 1.0

        // Extract favicon URL
        let js = """
        (function() {
            var links = document.querySelectorAll('link[rel~="icon"]');
            if (links.length > 0) return links[links.length - 1].href;
            return '';
        })()
        """
        Task { [weak self, weak webView] in
            guard let self, let webView else { return }

            if let result = try? await webView.evaluateJavaScript(js) as? String, !result.isEmpty {
                self.tab.faviconURLString = result
            } else if let host = webView.url?.host {
                self.tab.faviconURLString = "https://www.google.com/s2/favicons?domain=\(host)&sz=64"
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        tab.isLoading = false
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        tab.isLoading = false
    }

    // MARK: - WKUIDelegate

    /// Handle target="_blank" links: open in a new tab.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            tabManager.createTab(url: url)
        }
        return nil
    }
}
