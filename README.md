# SidePanel

SidePanel is a native macOS floating browser panel built with SwiftUI, AppKit, and WebKit. It stays above other apps, collapses into a circular hover bubble when unpinned, and keeps browsing tools available without taking over the desktop.

## Current Features

- Always-on-top floating `NSPanel`
- Pinned and unpinned modes
- Collapsed circular icon with hover-to-expand behavior
- Multi-tab browsing with per-tab session restore
- Restored back/forward history after relaunch
- Address bar with history suggestions
- Browsing history popover in the toolbar
- Minimal settings window for real app preferences only
- Adaptive page fitting for narrow responsive sites
- Global shortcuts through macOS Accessibility permission
- Accessory-style app behavior with no Dock or Cmd-Tab entry

## Requirements

- macOS 14 or later
- Xcode 15 or later if opening in Xcode

## Build And Run

### Swift Package Manager

```bash
swift build
./.build/debug/SidePanel
```

This launches a GUI process from the terminal, so the shell stays attached while the app is running. Use `Ctrl+C` in that terminal to stop it.

### Xcode

1. Open `Package.swift` in Xcode.
2. Select the `SidePanel` executable target.
3. Build and run.

## Testing

```bash
swift test
```

The current package includes unit tests for homepage normalization logic.

## First Launch

SidePanel uses Accessibility permission for system-wide shortcuts.

1. Launch the app.
2. If macOS shows the Accessibility prompt, approve it.
3. If it does not, open `System Settings > Privacy & Security > Accessibility`.
4. Enable `SidePanel`.
5. Relaunch the app if macOS requires it.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Cmd+Shift+S` | Toggle sidebar |
| `Cmd+Shift+N` | New tab |
| `Cmd+Shift+W` | Close current tab |
| `Cmd+Shift+[` | Previous tab |
| `Cmd+Shift+]` | Next tab |
| `Cmd+Shift+L` | Focus address bar |

## Toolbar

The toolbar currently provides:

- Back
- Forward
- Pin / unpin
- History popover
- Settings

## Settings

The settings window is intentionally minimal and only includes active preferences:

- `General`
  - Homepage
  - Default search engine
  - Remember last session
- `Appearance`
  - Theme
  - Sidebar width
  - Transparency
- `Behavior`
  - Auto-collapse delay
  - Show on all spaces
- `Privacy`
  - Clear browsing history now
  - Clear history on quit
- `Shortcuts`
  - Shortcut reference
  - Open Accessibility settings

Browsing history is not a settings tab. It is available from the toolbar history button.

## Interaction Notes

- Drag the panel background to move it.
- Resize the panel from its edges.
- Unpin to collapse the app into the circular floating icon.
- Hover the icon to temporarily expand the panel.
- Move out of the temporary panel to collapse it again.
- Use the toolbar history button to reopen previously visited pages.

## Architecture

The current codebase is organized like this:

```text
SidePanel/
  App/
  Data/
  Tabs/
  UI/
    Components/
    Settings/
    Views/
  Utils/
  Web/
  Window/
```

Main pieces:

- `App/` app lifecycle and startup coordination
- `Window/` floating panel and collapsed bubble window management
- `Tabs/` tab state, restored navigation history, and tab-level navigation
- `Web/` `WKWebView` integration and adaptive page fitting
- `Data/` settings, session persistence, and browsing history persistence
- `UI/` SwiftUI views for toolbar, tabs, settings, address bar, and history

## Notes

- The app stores window/session snapshots locally in app preferences.
- Open tabs are persisted in SwiftData.
- Browsing history is stored locally in app preferences.
- The homepage defaults to Google and can be changed in Settings.
- Browsing history can be cleared immediately from Settings or automatically on quit.

## License

MIT
