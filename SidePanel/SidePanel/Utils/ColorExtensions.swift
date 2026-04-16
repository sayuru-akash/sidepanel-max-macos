import SwiftUI
import AppKit

/// Design-system colours that adapt to the current appearance (dark / light).
extension Color {

    // MARK: - Backgrounds

    static let sidebarBackground = Color("sidebarBackground", bundle: nil)
    static let tabBarBackground = Color("tabBarBackground", bundle: nil)
    static let collapsedButtonBackground = Color("collapsedButtonBackground", bundle: nil)

    // Programmatic fallbacks used when asset-catalog colours aren't available.

    static var sidebarBG: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(calibratedWhite: 0.12, alpha: 0.85)
                : NSColor(calibratedWhite: 1.0, alpha: 0.90)
        })
    }

    static var tabBarBG: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(calibratedWhite: 0.15, alpha: 0.90)
                : NSColor(calibratedWhite: 0.97, alpha: 0.95)
        })
    }

    static var collapsedBG: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(calibratedWhite: 0.2, alpha: 0.95)
                : NSColor(calibratedWhite: 0.95, alpha: 0.98)
        })
    }

    // MARK: - Text

    static var primaryText: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? .white : .black
        })
    }

    static var secondaryText: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(calibratedWhite: 0.6, alpha: 1)
                : NSColor(calibratedWhite: 0.4, alpha: 1)
        })
    }

    // MARK: - Tab States

    static var tabActive: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor.white.withAlphaComponent(0.1)
                : NSColor.black.withAlphaComponent(0.06)
        })
    }

    static var tabHover: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor.white.withAlphaComponent(0.05)
                : NSColor.black.withAlphaComponent(0.03)
        })
    }

    // MARK: - Borders

    static var subtleBorder: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor.white.withAlphaComponent(0.1)
                : NSColor.black.withAlphaComponent(0.08)
        })
    }
}
