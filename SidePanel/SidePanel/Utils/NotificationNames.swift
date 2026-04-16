import Foundation

/// Custom notification names used to decouple global hotkeys
/// and menu actions from the UI layer.
extension Notification.Name {
    static let toggleSidebar  = Notification.Name("com.sidepanel.toggleSidebar")
    static let newTab         = Notification.Name("com.sidepanel.newTab")
    static let closeTab       = Notification.Name("com.sidepanel.closeTab")
    static let previousTab    = Notification.Name("com.sidepanel.previousTab")
    static let nextTab        = Notification.Name("com.sidepanel.nextTab")
    static let focusAddressBar = Notification.Name("com.sidepanel.focusAddressBar")
}
