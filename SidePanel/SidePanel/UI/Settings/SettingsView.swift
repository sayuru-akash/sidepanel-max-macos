import SwiftUI

/// Main settings window with tabbed sections.
struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }

            AppearanceSettingsView()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }

            BehaviorSettingsView()
                .tabItem { Label("Behavior", systemImage: "hand.tap") }

            PrivacySettingsView()
                .tabItem { Label("Privacy", systemImage: "shield") }

            ShortcutsSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(width: 480, height: 320)
        .environmentObject(settingsManager)
    }
}

// MARK: - General

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            Toggle("Remember Last Session", isOn: $settings.rememberLastSession)

            Picker("Search Engine", selection: $settings.defaultSearchEngine) {
                Text("Google").tag("google")
                Text("DuckDuckGo").tag("duckduckgo")
                Text("Bing").tag("bing")
            }
            .pickerStyle(.menu)

            Divider()

            Button("Reset All Settings") {
                settings.resetToDefaults()
            }
            .foregroundStyle(.red)
        }
        .padding()
    }
}

// MARK: - Appearance

struct AppearanceSettingsView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        Form {
            Picker("Theme", selection: $settings.theme) {
                ForEach(SettingsManager.Theme.allCases) { theme in
                    Text(theme.rawValue.capitalized).tag(theme)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Sidebar Width")
                Slider(value: $settings.sidebarWidth, in: 320...600, step: 10)
                Text("\(Int(settings.sidebarWidth))px")
                    .monospacedDigit()
                    .frame(width: 50)
            }

            HStack {
                Text("Transparency")
                Slider(value: $settings.transparency, in: 0.5...1.0, step: 0.05)
                Text("\(Int(settings.transparency * 100))%")
                    .monospacedDigit()
                    .frame(width: 50)
            }
        }
        .padding()
    }
}

// MARK: - Behavior

struct BehaviorSettingsView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        Form {
            HStack {
                Text("Auto-Collapse Delay")
                Slider(value: $settings.autoCollapseDelay, in: 0.5...10, step: 0.5)
                Text("\(settings.autoCollapseDelay, specifier: "%.1f")s")
                    .monospacedDigit()
                    .frame(width: 40)
            }

            Toggle("Show on All Spaces", isOn: $settings.showOnAllSpaces)
        }
        .padding()
    }
}

// MARK: - Privacy

struct PrivacySettingsView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        Form {
            Toggle("Clear History on Quit", isOn: $settings.clearHistoryOnQuit)
            Toggle("Send Do-Not-Track Header", isOn: $settings.doNotTrack)
        }
        .padding()
    }
}

// MARK: - Shortcuts

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            shortcutRow("Toggle Sidebar", shortcut: "Cmd + Shift + S")
            shortcutRow("New Tab", shortcut: "Cmd + Shift + N")
            shortcutRow("Close Tab", shortcut: "Cmd + Shift + W")
            shortcutRow("Previous Tab", shortcut: "Cmd + Shift + [")
            shortcutRow("Next Tab", shortcut: "Cmd + Shift + ]")
            shortcutRow("Focus Address Bar", shortcut: "Cmd + Shift + L")

            Divider()

            Text("Shortcuts require Accessibility permission.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Open Accessibility Settings") {
                PermissionManager.requestAccessibilityPermission()
            }
        }
        .padding()
    }

    private func shortcutRow(_ label: String, shortcut: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.1))
                )
        }
    }
}
