import XCTest
@testable import SidePanel

final class SettingsManagerTests: XCTestCase {

    @MainActor
    func testNormalizedHomepageAddsHTTPSWhenMissingScheme() {
        XCTAssertEqual(
            SettingsManager.normalizedHomepageValue("example.com"),
            "https://example.com"
        )
    }

    @MainActor
    func testNormalizedHomepageTrimsWhitespace() {
        XCTAssertEqual(
            SettingsManager.normalizedHomepageValue("  https://google.com  "),
            "https://google.com"
        )
    }

    @MainActor
    func testNormalizedHomepageFallsBackToGoogleForEmptyInput() {
        XCTAssertEqual(
            SettingsManager.normalizedHomepageValue("   "),
            "https://google.com"
        )
    }
}
