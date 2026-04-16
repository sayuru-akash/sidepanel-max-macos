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
    private var boundsObservation: NSKeyValueObservation?
    private var fitTask: Task<Void, Never>?
    private var initialRevealTask: Task<Void, Never>?
    private var isAwaitingInitialPresentation = false

    private let fitDebounceNanoseconds: UInt64 = 120_000_000
    private let initialFitDebounceNanoseconds: UInt64 = 20_000_000
    private let minimumAdaptiveZoom: Double = 0.78
    private let overflowTolerance: Double = 1.02

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
                if wv.isLoading, wv.estimatedProgress > 0.08 {
                    self?.scheduleAdaptiveFit(for: wv, debounceNanoseconds: self?.initialFitDebounceNanoseconds ?? 20_000_000)
                }
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

        boundsObservation = webView.observe(\.bounds, options: .new) { [weak self] wv, _ in
            Task { @MainActor [weak self] in
                let debounce = (self?.isAwaitingInitialPresentation == true)
                    ? self?.initialFitDebounceNanoseconds
                    : self?.fitDebounceNanoseconds
                self?.scheduleAdaptiveFit(for: wv, debounceNanoseconds: debounce ?? 120_000_000)
            }
        }
    }

    // MARK: - WKNavigationDelegate

    nonisolated func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        MainActor.assumeIsolated { [weak self] in
            self?.tab.isLoading = true
            self?.prepareForInitialPresentation(of: webView)
        }
    }

    nonisolated func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        MainActor.assumeIsolated { [weak self] in
            self?.scheduleAdaptiveFit(for: webView, debounceNanoseconds: self?.initialFitDebounceNanoseconds ?? 20_000_000)
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        MainActor.assumeIsolated { [weak self] in
            guard let self else { return }

            tab.isLoading = false
            tab.estimatedProgress = 1.0
            if let url = webView.url {
                tabManager.recordCompletedNavigation(for: tab, to: url)
            }
            scheduleAdaptiveFit(for: webView, debounceNanoseconds: 0)

            // Extract favicon URL
            let js = """
            (function() {
                var links = document.querySelectorAll('link[rel~="icon"]');
                if (links.length > 0) return links[links.length - 1].href;
                return '';
            })()
            """

            webView.evaluateJavaScript(js) { [weak self, weak webView] result, _ in
                guard let self, let webView else { return }

                MainActor.assumeIsolated {
                    if let favicon = result as? String, !favicon.isEmpty {
                        self.tab.faviconURLString = favicon
                    } else if let host = webView.url?.host {
                        self.tab.faviconURLString = "https://www.google.com/s2/favicons?domain=\(host)&sz=64"
                    }

                    if let url = webView.url {
                        BrowsingHistoryManager.shared.recordVisit(
                            url: url,
                            title: self.tab.title,
                            faviconURLString: self.tab.faviconURLString
                        )
                    }
                }
            }
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        MainActor.assumeIsolated { [weak self] in
            guard let self else { return }
            tab.isLoading = false
            scheduleAdaptiveFit(for: webView, debounceNanoseconds: 0)
            revealWebViewIfNeeded(webView)
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        MainActor.assumeIsolated { [weak self] in
            guard let self else { return }
            tab.isLoading = false
            scheduleAdaptiveFit(for: webView, debounceNanoseconds: 0)
            revealWebViewIfNeeded(webView)
        }
    }

    // MARK: - WKUIDelegate

    /// Handle target="_blank" links: open in a new tab.
    nonisolated func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        MainActor.assumeIsolated { [weak self] in
            guard let self else { return }
            if let url = navigationAction.request.url {
                tabManager.createTab(url: url)
            }
        }
        return nil
    }

    // MARK: - Adaptive Layout

    func scheduleAdaptiveFit(for webView: WKWebView, debounceNanoseconds: UInt64? = nil) {
        fitTask?.cancel()
        fitTask = Task { @MainActor [weak self, weak webView] in
            guard let self, let webView else { return }

            let delay = debounceNanoseconds ?? fitDebounceNanoseconds
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }

            await applyAdaptiveFit(to: webView)
        }
    }

    private func applyAdaptiveFit(to webView: WKWebView) async {
        let viewportWidth = max(Double(webView.bounds.width), 1)
        guard viewportWidth > 1 else { return }

        let script = """
        (function() {
            var doc = document.documentElement;
            var body = document.body;
            var widths = [
                window.innerWidth || 0,
                doc ? doc.clientWidth : 0,
                doc ? doc.scrollWidth : 0,
                doc ? doc.getBoundingClientRect().width : 0,
                body ? body.scrollWidth : 0,
                body ? body.getBoundingClientRect().width : 0
            ].filter(function(v) { return Number.isFinite(v) && v > 0; });
            return Math.max.apply(null, widths);
        })();
        """

        guard let result = try? await webView.evaluateJavaScript(script) else {
            revealWebViewIfNeeded(webView)
            return
        }

        let contentWidth: Double
        switch result {
        case let number as NSNumber:
            contentWidth = number.doubleValue
        case let value as Double:
            contentWidth = value
        case let value as Int:
            contentWidth = Double(value)
        default:
            revealWebViewIfNeeded(webView)
            return
        }

        guard contentWidth > 0 else {
            revealWebViewIfNeeded(webView)
            return
        }

        let targetZoom: Double
        if contentWidth > viewportWidth * overflowTolerance {
            targetZoom = max(minimumAdaptiveZoom, min(1, viewportWidth / contentWidth))
        } else {
            targetZoom = 1
        }

        if abs(webView.pageZoom - targetZoom) > 0.02 {
            webView.pageZoom = targetZoom
        }

        revealWebViewIfNeeded(webView)
    }

    private func prepareForInitialPresentation(of webView: WKWebView) {
        isAwaitingInitialPresentation = true
        fitTask?.cancel()
        initialRevealTask?.cancel()

        webView.alphaValue = 0
        if webView.bounds.width > 0 {
            webView.pageZoom = minimumAdaptiveZoom
        }

        initialRevealTask = Task { @MainActor [weak self, weak webView] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard let self, let webView, !Task.isCancelled else { return }
            self.revealWebViewIfNeeded(webView)
        }
    }

    private func revealWebViewIfNeeded(_ webView: WKWebView) {
        guard isAwaitingInitialPresentation else { return }

        isAwaitingInitialPresentation = false
        initialRevealTask?.cancel()
        initialRevealTask = nil

        if webView.alphaValue < 1 {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.08
                webView.animator().alphaValue = 1
            }
        }
    }
}
