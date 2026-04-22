import Foundation

/// Central source of truth for all spacing and sizing constants.
enum LayoutMetrics {
    // MARK: - Window
    static let defaultWidth: CGFloat = 420
    static let defaultHeight: CGFloat = 700
    static let minWidth: CGFloat = 320
    static let maxWidth: CGFloat = 600
    static let minHeight: CGFloat = 400

    // MARK: - Collapsed State
    static let collapsedSize: CGFloat = 64
    static let collapsedCornerRadius: CGFloat = 32
    static let collapsedShadowPadding: CGFloat = 12
    static let collapsedWindowSize: CGFloat = collapsedSize + (collapsedShadowPadding * 2)

    // MARK: - Tab Bar
    static let tabBarWidth: CGFloat = 56
    static let tabHeight: CGFloat = 44
    static let tabSpacing: CGFloat = 2
    static let tabIconSize: CGFloat = 20

    // MARK: - Address Bar
    static let addressBarHeight: CGFloat = 36
    static let addressBarPadding: CGFloat = 12

    // MARK: - General
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 8
    static let windowPadding: CGFloat = 8
    static let toolbarHeight: CGFloat = 44
}
