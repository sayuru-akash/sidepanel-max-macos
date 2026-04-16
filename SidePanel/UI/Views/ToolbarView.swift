import SwiftUI

/// Top toolbar with navigation controls, pin button, and settings.
struct ToolbarView: View {
    @EnvironmentObject var panelManager: PanelManager
    @EnvironmentObject var tabManager: TabManager
    @State private var showSettings = false

    var body: some View {
        let activeTab = tabManager.activeTab

        HStack(spacing: 12) {
            // Navigation controls
            HStack(spacing: 4) {
                navButton(icon: "chevron.left", action: { tabManager.goBack() })
                    .disabled(!tabManager.canGoBack(activeTab))
                    .opacity(tabManager.canGoBack(activeTab) ? 1 : 0.45)
                    .help("Back")
                navButton(icon: "chevron.right", action: { tabManager.goForward() })
                    .disabled(!tabManager.canGoForward(activeTab))
                    .opacity(tabManager.canGoForward(activeTab) ? 1 : 0.45)
                    .help("Forward")
            }

            Spacer()

            // Pin / Unpin toggle
            Button(action: {
                withAnimation(AnimationConfig.pinTransition) {
                    if panelManager.state == .pinned {
                        panelManager.unpin()
                    } else {
                        panelManager.pin()
                    }
                }
            }) {
                Image(systemName: panelManager.state == .pinned ? "pin.fill" : "pin")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(panelManager.state == .pinned ? Color.accentColor : .secondary)
                    .rotationEffect(.degrees(panelManager.state == .pinned ? 0 : 45))
            }
            .buttonStyle(.plain)
            .help(panelManager.state == .pinned ? "Unpin sidebar" : "Pin sidebar")
            .accessibilityIdentifier("pinButton")

            // Settings
            Button(action: {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func navButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
