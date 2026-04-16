import SwiftUI

private enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case appearance
    case behavior
    case privacy
    case shortcuts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .appearance: return "Appearance"
        case .behavior: return "Behavior"
        case .privacy: return "Privacy"
        case .shortcuts: return "Shortcuts"
        }
    }

    var subtitle: String {
        switch self {
        case .general: return "Core browsing defaults and session behavior."
        case .appearance: return "Window look, size, and presentation."
        case .behavior: return "How the floating panel responds."
        case .privacy: return "Browsing history retention and clearing."
        case .shortcuts: return "Keyboard shortcut reference and permissions."
        }
    }

    var symbolName: String {
        switch self {
        case .general: return "gearshape"
        case .appearance: return "paintbrush"
        case .behavior: return "slider.horizontal.3"
        case .privacy: return "hand.raised"
        case .shortcuts: return "keyboard"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var selection: SettingsPane = .general

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            detailPane
        }
        .frame(width: 720, height: 500)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.system(size: 22, weight: .semibold))
                Text("SidePanel preferences")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                ForEach(SettingsPane.allCases) { pane in
                    sidebarButton(for: pane)
                }
            }

            Spacer()

            Button("Reset All Settings", role: .destructive) {
                settingsManager.resetToDefaults()
            }
            .buttonStyle(.borderless)
            .font(.system(size: 12, weight: .medium))
        }
        .padding(20)
        .frame(width: 190)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(Color.secondary.opacity(0.06))
    }

    private var detailPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selection.title)
                        .font(.system(size: 26, weight: .semibold))
                    Text(selection.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                paneContent
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var paneContent: some View {
        switch selection {
        case .general:
            GeneralSettingsPane()
                .environmentObject(settingsManager)
        case .appearance:
            AppearanceSettingsPane()
                .environmentObject(settingsManager)
        case .behavior:
            BehaviorSettingsPane()
                .environmentObject(settingsManager)
        case .privacy:
            PrivacySettingsPane()
                .environmentObject(settingsManager)
        case .shortcuts:
            ShortcutsSettingsPane()
        }
    }

    private func sidebarButton(for pane: SettingsPane) -> some View {
        Button {
            selection = pane
        } label: {
            HStack(spacing: 10) {
                Image(systemName: pane.symbolName)
                    .frame(width: 16)
                Text(pane.title)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .foregroundStyle(selection == pane ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selection == pane ? Color.accentColor.opacity(0.16) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct GeneralSettingsPane: View {
    @EnvironmentObject private var settings: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsCard("Startup") {
                SettingsToggleRow("Remember last session", isOn: $settings.rememberLastSession)
            }

            SettingsCard("Browsing") {
                SettingsLabeledRow("Homepage") {
                    TextField("https://google.com", text: $settings.homepage)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 280)
                }

                Divider()

                SettingsLabeledRow("Default search engine") {
                    Picker("Search Engine", selection: $settings.defaultSearchEngine) {
                        Text("Google").tag("google")
                        Text("DuckDuckGo").tag("duckduckgo")
                        Text("Bing").tag("bing")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AppearanceSettingsPane: View {
    @EnvironmentObject private var settings: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsCard("Window Appearance") {
                SettingsLabeledRow("Theme") {
                    Picker("Theme", selection: $settings.theme) {
                        ForEach(SettingsManager.Theme.allCases) { theme in
                            Text(theme.rawValue.capitalized).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }

                Divider()

                SettingsSliderRow(
                    title: "Sidebar width",
                    valueText: "\(Int(settings.sidebarWidth)) px",
                    value: $settings.sidebarWidth,
                    range: 320...600,
                    step: 10
                )

                Divider()

                SettingsSliderRow(
                    title: "Transparency",
                    valueText: "\(Int(settings.transparency * 100))%",
                    value: $settings.transparency,
                    range: 0.5...1.0,
                    step: 0.05
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BehaviorSettingsPane: View {
    @EnvironmentObject private var settings: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsCard("Panel Behavior") {
                SettingsSliderRow(
                    title: "Auto-collapse delay",
                    valueText: "\(String(format: "%.1f", settings.autoCollapseDelay)) s",
                    value: $settings.autoCollapseDelay,
                    range: 0.5...10,
                    step: 0.5
                )

                Divider()

                Toggle("Show on all spaces", isOn: $settings.showOnAllSpaces)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PrivacySettingsPane: View {
    @EnvironmentObject private var settings: SettingsManager
    @ObservedObject private var historyManager = BrowsingHistoryManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsCard("Browsing History") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stored history")
                            .font(.system(size: 13, weight: .medium))
                        Text("\(historyManager.items.count) saved item\(historyManager.items.count == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Clear Now", role: .destructive) {
                        historyManager.clearAll()
                    }
                    .buttonStyle(.bordered)
                }

                Divider()

                Toggle("Clear history on quit", isOn: $settings.clearHistoryOnQuit)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ShortcutsSettingsPane: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsCard("Keyboard Shortcuts") {
                ShortcutRow(label: "Toggle sidebar", shortcut: "Cmd + Shift + S")
                Divider()
                ShortcutRow(label: "New tab", shortcut: "Cmd + Shift + N")
                Divider()
                ShortcutRow(label: "Close tab", shortcut: "Cmd + Shift + W")
                Divider()
                ShortcutRow(label: "Previous tab", shortcut: "Cmd + Shift + [")
                Divider()
                ShortcutRow(label: "Next tab", shortcut: "Cmd + Shift + ]")
                Divider()
                ShortcutRow(label: "Focus address bar", shortcut: "Cmd + Shift + L")
            }

            SettingsCard("Permissions") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Global shortcuts require Accessibility permission.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Button("Open Accessibility Settings") {
                        PermissionManager.openAccessibilityPreferences()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Request Permission Prompt") {
                        PermissionManager.requestAccessibilityPermission()
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))

            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct SettingsLabeledRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 140, alignment: .leading)
            content
            Spacer(minLength: 0)
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    init(_ title: String, isOn: Binding<Bool>) {
        self.title = title
        self._isOn = isOn
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
            Spacer(minLength: 0)
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

private struct SettingsSliderRow: View {
    let title: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 140, alignment: .leading)

            Slider(value: $value, in: range, step: step)

            Text(valueText)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
    }
}

private struct ShortcutRow: View {
    let label: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
            Spacer()
            Text(shortcut)
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
        }
    }
}
