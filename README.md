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

## Versioning (Single Source Of Truth)

Release version is controlled by one file:

- `version.txt`

Example:

```text
0.1.0
```

To bump version:

```bash
./scripts/bump_version.sh 0.1.1
```

Or edit `version.txt` directly.

All packaging and release automation reads from that file.

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

## Production Build And Packaging

Build a signed (ad-hoc by default) app bundle and `.pkg` installer:

```bash
./scripts/check.sh
```

Artifacts are created in `dist/`:

- `dist/SidePanel.app`
- `dist/SidePanel-<version>.pkg`

To only build the app bundle:

```bash
./scripts/build_app_bundle.sh
```

To only build the installer package from an already built app bundle:

```bash
./scripts/build_pkg.sh --skip-app-build
```

For Developer ID signing and notarization, provide these environment variables:

- `CODESIGN_IDENTITY`
- `PKG_SIGN_IDENTITY`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`

Notarize a generated package manually:

```bash
./scripts/notarize_pkg.sh dist/SidePanel-$(cat version.txt).pkg
```

## App Icon

A custom purple-focused icon can be generated and regenerated with:

```bash
./scripts/generate_icon.sh
```

It outputs:

- `Assets/AppIcon/SidePanel-1024.png`
- `Assets/AppIcon/SidePanel.icns`

The installer build embeds this `.icns` file into `SidePanel.app`.

## Pre-Commit Quality Gate

Enable repository-managed git hooks:

```bash
./scripts/setup-git-hooks.sh
```

This wires `.githooks/pre-commit` so every commit runs:

- unit tests
- release build
- app bundle build
- `.pkg` build

If any step fails, the commit is blocked.

## GitHub Actions (CI + Auto Release)

### CI

- Workflow: `.github/workflows/ci.yml`
- Runs on push and pull request
- Executes `./scripts/check.sh`

### Auto Release

- Workflow: `.github/workflows/release.yml`
- Runs on pushes to `main`/`master` and on manual dispatch
- If `version.txt` changed and tag does not already exist:
  - runs production checks
  - builds `.app` and `.pkg`
  - optionally notarizes package if Apple credentials are configured
  - creates and pushes tag `v<version>`
  - publishes GitHub Release with artifacts and SHA256 checksums

Required repository secrets for signed/notarized releases:

- `APPLE_CERTIFICATE_BASE64`
- `APPLE_CERTIFICATE_PASSWORD`
- `CODESIGN_IDENTITY`
- `PKG_SIGN_IDENTITY`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`

If signing secrets are omitted, the workflow still builds and publishes unsigned artifacts.

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

| Shortcut      | Action            |
| ------------- | ----------------- |
| `Cmd+Shift+S` | Toggle sidebar    |
| `Cmd+Shift+N` | New tab           |
| `Cmd+Shift+W` | Close current tab |
| `Cmd+Shift+[` | Previous tab      |
| `Cmd+Shift+]` | Next tab          |
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
Sources/
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

Tests/
  SidePanelTests/
```

Main pieces:

- `Sources/SidePanel/App/` app lifecycle and startup coordination
- `Sources/SidePanel/Window/` floating panel and collapsed bubble window management
- `Sources/SidePanel/Tabs/` tab state, restored navigation history, and tab-level navigation
- `Sources/SidePanel/Web/` `WKWebView` integration and adaptive page fitting
- `Sources/SidePanel/Data/` settings, session persistence, and browsing history persistence
- `Sources/SidePanel/UI/` SwiftUI views for toolbar, tabs, settings, address bar, and history
- `Tests/SidePanelTests/` unit tests for pure logic

## Notes

- The app stores window/session snapshots locally in app preferences.
- Open tabs are persisted in SwiftData.
- Browsing history is stored locally in app preferences.
- The homepage defaults to Google and can be changed in Settings.
- Browsing history can be cleared immediately from Settings or automatically on quit.

## License

MIT
