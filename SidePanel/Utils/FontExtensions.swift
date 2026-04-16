import SwiftUI

/// Typography scale for the design system.
extension Font {
    static let tabTitle = Font.system(size: 11, weight: .medium, design: .default)
    static let tabTitleActive = Font.system(size: 11, weight: .semibold, design: .default)
    static let addressBar = Font.system(size: 13, weight: .regular, design: .default)
    static let addressBarSecure = Font.system(size: 13, weight: .medium, design: .default)
    static let tooltip = Font.system(size: 12, weight: .regular, design: .default)
    static let statusText = Font.system(size: 10, weight: .medium, design: .default)
    static let sectionHeader = Font.system(size: 14, weight: .semibold, design: .default)
    static let settingLabel = Font.system(size: 13, weight: .regular, design: .default)
}
