import SwiftUI

/// Predefined animation curves used throughout the app.
enum AnimationConfig {
    // Durations
    static let quick: Double = 0.15
    static let standard: Double = 0.25
    static let slow: Double = 0.4

    // Named animations
    static let easeOut = Animation.easeOut(duration: standard)
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let collapseSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let pinTransition = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let tabSwitch = Animation.easeInOut(duration: quick)
    static let hoverExpand = Animation.easeOut(duration: 0.2)
}
