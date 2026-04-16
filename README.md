# SidePanel

A native macOS floating sidebar browser. Browse the web without leaving your workflow.

## What It Does

SidePanel is a lightweight, always-on-top browser panel that floats over all your applications. It gives you quick web access -- reference docs while coding, check a site while writing, look something up without switching windows.

**Key features:**

- Always-on-top floating panel built with NSPanel
- Full WKWebView browser (not an iframe -- works with every site)
- Pin/unpin: keep the sidebar open or collapse it to a small floating icon
- Vertical tab bar with favicon display and drag-to-reorder
- Global keyboard shortcuts (Cmd+Shift+S to toggle, etc.)
- Glassmorphism UI with dark/light mode support
- Session persistence -- tabs and window position survive restarts
- No Dock icon, no Cmd+Tab entry -- stays out of your way

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac

## Build & Run

### Option 1: Xcode

1. Open `SidePanel/` in Xcode 15+
2. Create a new macOS App project and add all Swift files from the `SidePanel/` directory
3. Set deployment target to macOS 14.0
4. Set `Info.plist` to include `LSUIElement = YES`
5. Build and run (Cmd+R)

### Option 2: Swift Package Manager

```bash
cd sidepanel-max-macos
swift build
./.build/debug/SidePanel
```

The executable is a GUI process, so the terminal stays attached while the app is running. Use `Ctrl+C` in that terminal to stop it.

## First Launch

On first launch, macOS should ask for **Accessibility** permission:

1. Approve the system prompt if it appears
2. Or open System Settings > Privacy & Security > Accessibility
3. Find `SidePanel` and toggle it on
4. Relaunch the app if needed

This permission is needed for global keyboard shortcuts to work from any application.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| Cmd+Shift+S | Toggle sidebar |
| Cmd+Shift+N | New tab |
| Cmd+Shift+W | Close current tab |
| Cmd+Shift+[ | Previous tab |
| Cmd+Shift+] | Next tab |
| Cmd+Shift+L | Focus address bar |

All shortcuts work system-wide, even when SidePanel is not the active app.

## Mouse Interaction

- **Drag** the sidebar background to reposition
- **Hover** the collapsed icon to temporarily expand
- **Click** the pin button to keep the sidebar open
- **Right-click** tabs for context menu (close, duplicate, pin)

## Architecture

- **Swift 5.9+ / SwiftUI / AppKit** -- native performance, no Electron
- **WKWebView** -- full WebKit engine, same as Safari
- **NSPanel** -- floating window that stays above all apps
- **MVVM** -- clean separation of concerns
- **SwiftData** -- lightweight persistence for tabs
- **Carbon HotKeys** -- system-wide keyboard shortcuts

```
SidePanel/
  App/          -- Entry point, AppDelegate
  Window/       -- FloatingPanel, CollapsedButtonWindow, PanelManager
  UI/Views/     -- ContentView, TabBar, AddressBar, Toolbar
  UI/Settings/  -- Settings window tabs
  UI/Components/-- GlassBackground, FaviconImage
  Web/          -- WKWebView wrapper and coordinator
  Tabs/         -- Tab model and TabManager
  Data/         -- Persistence, settings, session management
  Utils/        -- Hotkeys, permissions, design system tokens
```

## License

MIT License -- see LICENSE file.
