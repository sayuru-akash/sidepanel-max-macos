import XCTest
@testable import SidePanel

@MainActor
final class SettingsManagerTests: XCTestCase {

    func testNormalizedHomepageAddsHTTPSWhenMissingScheme() {
        XCTAssertEqual(
            SettingsManager.normalizedHomepageValue("example.com"),
            "https://example.com"
        )
    }

    func testNormalizedHomepageTrimsWhitespace() {
        XCTAssertEqual(
            SettingsManager.normalizedHomepageValue("  https://google.com  "),
            "https://google.com"
        )
    }

    func testNormalizedHomepageFallsBackToGoogleForEmptyInput() {
        XCTAssertEqual(
            SettingsManager.normalizedHomepageValue("   "),
            "https://google.com"
        )
    }
}
