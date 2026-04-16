import WebKit

/// Factory for WKWebViewConfiguration shared across all tabs.
enum WebViewConfigurationFactory {
    /// Single shared configuration so all tabs share cookies and sessions.
    static let shared: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        // Play media inline without requiring user gesture
        config.mediaTypesRequiringUserActionForPlayback = []

        // Shared process pool = shared cookies across tabs
        config.processPool = WKProcessPool()

        // Identify as Safari so sites don't block us
        config.applicationNameForUserAgent = "Version/17.0 Safari/605.1.15"

        return config
    }()
}
