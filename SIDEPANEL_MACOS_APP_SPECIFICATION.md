# SidePanel - macOS Floating Sidebar Browser

## Complete Development Specification

**Version:** 1.0  
**Platform:** macOS 14.0+ (Sonoma+)  
**Language:** Swift 5.9+  
**Frameworks:** SwiftUI, AppKit, WebKit, Core Data, Combine  
**Architecture:** MVVM + Coordinator Pattern

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Core Requirements](#2-core-requirements)
3. [Technical Architecture](#3-technical-architecture)
4. [UI/UX Design System](#4-uiux-design-system)
5. [Feature Specifications](#5-feature-specifications)
6. [Data Models](#6-data-models)
7. [File Structure](#7-file-structure)
8. [Implementation Guide](#8-implementation-guide)
9. [Testing Strategy](#9-testing-strategy)
10. [Distribution](#10-distribution)

---

## 1. Product Overview

### 1.1 Vision Statement

SidePanel is a global floating sidebar browser for macOS that provides quick, always-accessible web browsing across all applications. It combines the utility of a sidebar (like Arc or Edge) with the convenience of a floating utility panel that stays visible regardless of which application is active.

### 1.2 Key Differentiators

- **True Global Presence**: Unlike browser sidebars, SidePanel floats over ALL applications
- **Zero Context Switching**: Browse without leaving your current app
- **Mini Browser Experience**: Full web engine, not limited iframes or extensions
- **Smart Collapse**: Expanded when needed, minimal icon when not
- **Native Performance**: Built with Swift and WebKit, not Electron

### 1.3 Target Users

- Developers researching while coding
- Content creators referencing sources while writing
- Professionals multitasking between apps and web
- Anyone wanting quick web access without window management

### 1.4 Core Value Proposition

"A browser that follows your workflow, not the other way around."

---

## 2. Core Requirements

### 2.1 Functional Requirements

#### FR-001: Floating Panel Window

- **Priority:** Critical
- **Description:** Create a borderless, always-on-top floating panel window
- **Acceptance Criteria:**
  - Window stays above all other application windows (level = .floating)
  - Window is visible across all Mission Control spaces
  - Window does not appear in Dock or app switcher (accessory app style)
  - Window can be dragged by clicking anywhere on the background
  - Window supports resizing from edges

#### FR-002: Pin/Unpin States

- **Priority:** Critical
- **Description:** Two distinct states for the panel
- **Acceptance Criteria:**

  **Pinned State:**
  - Full sidebar visible (default width: 420px, height: 85% of screen)
  - Shows tab bar, address bar, and web content area
  - Positioned on right edge of screen by default
  - Persists until user unpins

  **Unpinned State:**
  - Collapses to floating icon (64x64px circle)
  - Icon shows current tab's favicon or default browser icon
  - Position: remembers last dragged position or default to right-center
  - Hovering over icon temporarily expands sidebar (auto-collapse on mouse leave)
  - Clicking icon toggles pinned state

#### FR-003: WebView Integration

- **Priority:** Critical
- **Description:** Full web browsing capability using WKWebView
- **Acceptance Criteria:**
  - Each tab has independent WKWebView instance
  - Supports JavaScript, video playback, WebGL
  - Handles all websites (no X-Frame-Options limitations)
  - Standard browser features: back/forward, refresh, zoom
  - Downloads work through standard macOS download dialog

#### FR-004: Tab Management

- **Priority:** Critical
- **Description:** Vertical tab bar with full tab lifecycle
- **Acceptance Criteria:**
  - Vertical tab strip on left side of panel
  - Tab shows favicon and title on hover
  - New tab button at top
  - Maximum 50 tabs (configurable in settings)
  - Tab persistence across app launches
  - Tab ordering via drag-and-drop

#### FR-005: Address Bar

- **Priority:** High
- **Description:** URL input and search functionality
- **Acceptance Criteria:**
  - Displays current URL with security indicator
  - Typing searches using default search engine (Google)
  - URL validation and formatting
  - Autocomplete from history
  - Keyboard shortcut: Cmd+L to focus

#### FR-006: Global Keyboard Shortcuts

- **Priority:** High
- **Description:** System-wide shortcuts that work from any app
- **Acceptance Criteria:**
  - Cmd+Shift+S: Toggle sidebar visible/collapsed
  - Cmd+Shift+N: New tab
  - Cmd+Shift+W: Close current tab
  - Cmd+Shift+[/]: Previous/Next tab
  - Cmd+Shift+L: Focus address bar
  - All shortcuts work even when SidePanel is not active app

#### FR-007: Settings & Preferences

- **Priority:** Medium
- **Description:** User-configurable options
- **Acceptance Criteria:**
  - Launch at login option
  - Theme selection (Auto/Dark/Light)
  - Default search engine
  - Download location
  - Sidebar width
  - Auto-collapse delay
  - Keyboard shortcut customization
  - Reset to defaults option

#### FR-008: Session Persistence

- **Priority:** High
- **Description:** Restore previous session on launch
- **Acceptance Criteria:**
  - Save all open tabs with their URLs
  - Restore tabs on next app launch
  - Remember pinned/unpinned state
  - Remember window position and size
  - Save every 30 seconds and on quit

### 2.2 Non-Functional Requirements

#### NFR-001: Performance

- Cold launch: < 2 seconds
- Tab switch: < 500ms
- Memory usage: < 500MB for 10 tabs
- CPU usage: < 5% when idle

#### NFR-002: Security

- Sandboxed WebView (WKWebView default behavior)
- No access to local files except through standard dialogs
- HTTPS enforced for sensitive sites (configurable)
- Private browsing mode option

#### NFR-003: Accessibility

- Support VoiceOver
- Keyboard navigation for all features
- Respects Reduce Motion setting
- Minimum font size option

#### NFR-004: macOS Integration

- Native Swift/SwiftUI look and feel
- Supports macOS Dark Mode automatically
- Respects system accent color
- Proper menu bar integration
- Notification Center integration for downloads

---

## 3. Technical Architecture

### 3.1 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      SidePanel macOS App                        │
├─────────────────────────────────────────────────────────────────┤
│  Presentation Layer (SwiftUI)                                    │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐               │
│  │ SidebarView │ │ TabBarView  ││ WebViewHost │               │
│  │ (Container) │ │ (Vertical)  ││ (WKWebView) │               │
│  └─────────────┘ └─────────────┘ └─────────────┘               │
│         │               │               │                        │
├─────────┼───────────────┼───────────────┼──────────────────────┤
│         │    Business Logic Layer (MVVM)                       │
│         │               │               │                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐               │
│  │PanelManager │ │ TabManager  │ │WebViewModel │               │
│  │ (Window Mgr)│ │ (Tab State) │ │ (Navigation)│               │
│  └─────────────┘ └─────────────┘ └─────────────┘               │
│         │               │               │                        │
├─────────┼───────────────┼───────────────┼──────────────────────┤
│         │     Data Layer (Core Data)                           │
│         │               │               │                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐               │
│  │TabEntity    │ │HistoryEntity│ │SettingsEnt  │               │
│  │ (Tab Model) │ │ (Browsing)  │ │(Preferences)│               │
│  └─────────────┘ └─────────────┘ └─────────────┘               │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  System Integration Layer                                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐               │
│  │GlobalHotkey │ │ WindowLevel │ │AutoCollapse │               │
│  │ (Shortcuts) │ │ (Panel Mgr) │ │ (Hover)     │               │
│  └─────────────┘ └─────────────┘ └─────────────┘               │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Technology Stack

| Component            | Technology            | Justification                                |
| -------------------- | --------------------- | -------------------------------------------- |
| UI Framework         | SwiftUI + AppKit      | Native performance, modern declarative UI    |
| Web Engine           | WKWebView             | Apple's WebKit, full browser capability      |
| Data Persistence     | Core Data             | Native ORM, change tracking, iCloud ready    |
| Reactive Programming | Combine               | Native reactive streams, SwiftUI integration |
| Keyboard Shortcuts   | Carbon HotKeys API    | Global shortcuts require Carbon              |
| Window Management    | AppKit NSPanel        | For floating panel behavior                  |
| Image Loading        | Kingfisher (optional) | Efficient async image loading for favicons   |

### 3.3 Design Patterns

#### MVVM (Model-View-ViewModel)

```swift
// Model (Core Data Entity)
@Model
class Tab {
    var id: UUID
    var url: String
    var title: String
    var createdAt: Date
}

// ViewModel
class TabViewModel: ObservableObject {
    @Published var tabs: [Tab] = []
    @Published var activeTabId: UUID?

    func createTab(url: String) { ... }
    func closeTab(id: UUID) { ... }
    func activateTab(id: UUID) { ... }
}

// View
struct TabBarView: View {
    @StateObject var viewModel: TabViewModel

    var body: some View { ... }
}
```

#### Coordinator Pattern for Navigation

```swift
protocol Coordinator {
    func start()
    func handleDeepLink(url: URL)
}

class AppCoordinator: Coordinator {
    let panelManager: PanelManager
    let tabManager: TabManager

    func start() {
        // Initialize all managers
    }
}
```

#### Singleton Pattern for Managers

- `PanelManager` - Single floating panel instance
- `SettingsManager` - App-wide preferences
- `HotkeyManager` - Global shortcut handling

### 3.4 Window Architecture

#### Floating Panel Window (NSPanel)

```swift
class FloatingPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 800),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )

        // Critical configurations
        self.level = .floating
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
        self.isMovableByWindowBackground = true
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isOpaque = false
    }
}
```

#### Collapsed Button Window (Separate for flexibility)

```swift
class CollapsedButtonWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 64, height: 64),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
    }
}
```

---

## 4. UI/UX Design System

### 4.1 Visual Design Philosophy

**Glassmorphism + Minimalism**

- Semi-transparent backgrounds with backdrop blur
- Clean, uncluttered interface
- Generous whitespace
- Smooth, purposeful animations
- Focus on content (web pages), not chrome

### 4.2 Color System

#### Dark Mode (Default)

```swift
extension Color {
    // Backgrounds
    static let sidebarBackground = Color(NSColor(calibratedWhite: 0.12, alpha: 0.85))
    static let tabBarBackground = Color(NSColor(calibratedWhite: 0.15, alpha: 0.90))
    static let webViewBackground = Color.black
    static let collapsedButtonBackground = Color(NSColor(calibratedWhite: 0.2, alpha: 0.95))

    // Text
    static let primaryText = Color.white
    static let secondaryText = Color(NSColor(calibratedWhite: 0.6, alpha: 1.0))
    static let tertiaryText = Color(NSColor(calibratedWhite: 0.4, alpha: 1.0))

    // Accents (Dynamic - follows system accent)
    static let accent = Color(NSColor.controlAccentColor)
    static let accentHover = Color(NSColor.controlAccentColor).opacity(0.8)

    // States
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red

    // Borders
    static let border = Color.white.opacity(0.1)
    static let borderHover = Color.white.opacity(0.2)

    // Tab States
    static let tabInactive = Color.clear
    static let tabActive = Color.white.opacity(0.1)
    static let tabHover = Color.white.opacity(0.05)
}
```

#### Light Mode

```swift
extension Color {
    static let sidebarBackground = Color(NSColor(calibratedWhite: 1.0, alpha: 0.90))
    static let tabBarBackground = Color(NSColor(calibratedWhite: 0.97, alpha: 0.95))
    static let webViewBackground = Color.white
    static let collapsedButtonBackground = Color(NSColor(calibratedWhite: 0.95, alpha: 0.98))

    static let primaryText = Color.black
    static let secondaryText = Color(NSColor(calibratedWhite: 0.4, alpha: 1.0))
    static let tertiaryText = Color(NSColor(calibratedWhite: 0.5, alpha: 1.0))

    static let border = Color.black.opacity(0.08)
    static let borderHover = Color.black.opacity(0.15)

    static let tabActive = Color.black.opacity(0.06)
    static let tabHover = Color.black.opacity(0.03)
}
```

### 4.3 Typography

```swift
extension Font {
    // System fonts with specific weights
    static let tabTitle = Font.system(size: 11, weight: .medium, design: .default)
    static let tabTitleActive = Font.system(size: 11, weight: .semibold, design: .default)

    static let addressBar = Font.system(size: 13, weight: .regular, design: .default)
    static let addressBarSecure = Font.system(size: 13, weight: .medium, design: .default)

    static let tooltip = Font.system(size: 12, weight: .regular, design: .default)
    static let statusText = Font.system(size: 10, weight: .medium, design: .default)

    static let sectionHeader = Font.system(size: 14, weight: .semibold, design: .default)
    static let settingLabel = Font.system(size: 13, weight: .regular, design: .default)
}
```

### 4.4 Spacing & Layout

```swift
struct LayoutMetrics {
    // Window
    static let defaultWidth: CGFloat = 420
    static let defaultHeight: CGFloat = 700
    static let minWidth: CGFloat = 320
    static let maxWidth: CGFloat = 600
    static let minHeight: CGFloat = 400

    // Collapsed
    static let collapsedSize: CGFloat = 64
    static let collapsedCornerRadius: CGFloat = 32

    // Tab Bar
    static let tabBarWidth: CGFloat = 56
    static let tabHeight: CGFloat = 44
    static let tabSpacing: CGFloat = 2
    static let tabIconSize: CGFloat = 20

    // Address Bar
    static let addressBarHeight: CGFloat = 36
    static let addressBarPadding: CGFloat = 12

    // General
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 8
    static let windowPadding: CGFloat = 8
}
```

### 4.5 Animations

```swift
struct AnimationConfig {
    // Durations
    static let quick: Double = 0.15
    static let standard: Double = 0.25
    static let slow: Double = 0.4

    // Curves
    static let easeOut = Animation.easeOut(duration: standard)
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let collapseSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)

    // Specific animations
    static let pinTransition = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let tabSwitch = Animation.easeInOut(duration: quick)
    static let hoverExpand = Animation.easeOut(duration: 0.2)
}
```

### 4.6 Component Specifications

#### Tab Button

```swift
struct TabButton: View {
    let tab: Tab
    let isActive: Bool
    let isHovering: Bool

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)

            // Content
            HStack(spacing: 0) {
                // Favicon
                AsyncImage(url: tab.faviconURL) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "globe")
                        .foregroundColor(.secondaryText)
                }
                .frame(width: 20, height: 20)

                // Close button (visible on hover)
                if isHovering {
                    Button(action: closeTab) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(width: LayoutMetrics.tabBarWidth - 8, height: LayoutMetrics.tabHeight)
        .contentShape(Rectangle())
    }

    private var backgroundColor: Color {
        if isActive { return .tabActive }
        if isHovering { return .tabHover }
        return .clear
    }
}
```

#### Address Bar

```swift
struct AddressBar: View {
    @Binding var urlString: String
    @State var isSecure: Bool = false
    @FocusState var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Security indicator
            Image(systemName: isSecure ? "lock.fill" : "lock.open")
                .foregroundColor(isSecure ? .green : .orange)
                .font(.system(size: 12))

            // URL Input
            TextField("Search or enter address", text: $urlString)
                .font(.addressBar)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
                .onSubmit(navigate)

            // Action buttons
            if isFocused {
                Button(action: { isFocused = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondaryText.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? Color.accent : Color.clear, lineWidth: 2)
        )
    }
}
```

#### Collapsed Button

```swift
struct CollapsedButton: View {
    @State var isHovering: Bool = false
    let currentFavicon: URL?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                Circle()
                    .fill(.collapsedButtonBackground)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)

                // Favicon or default icon
                if let favicon = currentFavicon {
                    AsyncImage(url: favicon) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        defaultIcon
                    }
                    .frame(width: 28, height: 28)
                } else {
                    defaultIcon
                }

                // Hover indicator ring
                if isHovering {
                    Circle()
                        .stroke(Color.accent, lineWidth: 3)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: LayoutMetrics.collapsedSize, height: LayoutMetrics.collapsedSize)
        .onHover { hovering in
            withAnimation(.hoverExpand) {
                isHovering = hovering
            }
        }
    }

    private var defaultIcon: some View {
        Image(systemName: "globe")
            .font(.system(size: 24))
            .foregroundColor(.accent)
    }
}
```

---

## 5. Feature Specifications

### 5.1 Panel Management

#### Panel States

```swift
enum PanelState: Equatable {
    case pinned(expanded: Bool)    // Full sidebar, optionally expanded/collapsed
    case unpinned                  // Shows only collapsed button
    case temporarilyExpanded       // Unpinned but mouse is hovering

    var isVisible: Bool {
        switch self {
        case .pinned: return true
        case .unpinned: return true
        case .temporarilyExpanded: return true
        }
    }

    var showsSidebar: Bool {
        switch self {
        case .pinned(let expanded): return expanded
        case .unpinned: return false
        case .temporarilyExpanded: return true
        }
    }
}
```

#### Panel Positioning

```swift
struct PanelPosition: Codable {
    var screenID: UUID          // Which screen the panel is on
    var x: Double               // X position (right edge default)
    var y: Double               // Y position (centered vertically default)
    var width: Double           // Current width
    var height: Double          // Current height
    var isPinned: Bool          // Pinned state

    static let `default` = PanelPosition(
        screenID: UUID(),
        x: -1,  // -1 means right edge (calculated at runtime)
        y: -1,  // -1 means centered vertically
        width: 420,
        height: 700,
        isPinned: true
    )
}
```

#### Auto-Collapse Logic

```swift
class AutoCollapseManager: ObservableObject {
    @Published var isHovering: Bool = false
    private var collapseTimer: Timer?
    private let collapseDelay: TimeInterval = 2.0  // Seconds before auto-collapse

    func startMonitoring(window: NSWindow) {
        // Track mouse position relative to window
        NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMove(event)
        }
    }

    private func handleMouseMove(_ event: NSEvent) {
        let mouseLocation = NSEvent.mouseLocation
        // Check if mouse is over panel or collapsed button
        // Set isHovering accordingly
        // Start/reset collapse timer
    }

    private func scheduleCollapse() {
        collapseTimer?.invalidate()
        collapseTimer = Timer.scheduledTimer(withTimeInterval: collapseDelay, repeats: false) { [weak self] _ in
            self?.collapseIfNeeded()
        }
    }
}
```

### 5.2 WebView Management

#### WebView Coordinator

```swift
class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var parent: WebViewWrapper
    var webView: WKWebView?

    init(_ parent: WebViewWrapper) {
        self.parent = parent
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        parent.onPageLoaded?()

        // Update tab title
        webView.evaluateJavaScript("document.title") { [weak self] result, _ in
            if let title = result as? String {
                self?.parent.tab.title = title
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        parent.onError?(error)
    }

    // Handle new window requests (open in new tab)
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            parent.onNewTabRequested?(url)
        }
        return nil
    }
}
```

#### WebView Configuration

```swift
extension WKWebViewConfiguration {
    static var sidePanelConfig: WKWebViewConfiguration {
        let config = WKWebViewConfiguration()

        // Preferences
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        // Enable media playback
        config.mediaTypesRequiringUserActionForPlayback = []

        // Process pool (shared across tabs for session persistence if desired)
        config.processPool = WKProcessPool()

        // User agent (identify as Safari to avoid blocks)
        config.applicationNameForUserAgent = "Version/16.0 Safari/605.1.15"

        return config
    }
}
```

### 5.3 Tab System

#### Tab Model

```swift
@Model
class Tab {
    @Attribute(.unique) var id: UUID
    var url: String
    var title: String
    var faviconURL: String?
    var createdAt: Date
    var lastAccessedAt: Date
    var order: Int                  // For drag-and-drop ordering
    var isPinned: Bool            // Pin this tab (don't close)
    var isMuted: Bool               // Mute audio

    // WebView state (not persisted, restored on launch)
    @Transient var webView: WKWebView?
    @Transient var isLoading: Bool = false
    @Transient var estimatedProgress: Double = 0

    init(url: String, title: String = "New Tab") {
        self.id = UUID()
        self.url = url
        self.title = title
        self.createdAt = Date()
        self.lastAccessedAt = Date()
        self.order = 0
        self.isPinned = false
        self.isMuted = false
    }
}
```

#### Tab Manager

```swift
@MainActor
class TabManager: ObservableObject {
    @Published var tabs: [Tab] = []
    @Published var activeTabId: UUID?

    private let container: ModelContainer
    private let maxTabs = 50

    init(container: ModelContainer) {
        self.container = container
        loadTabs()
    }

    func createTab(url: URL? = nil, activate: Bool = true) -> Tab {
        // Enforce max tabs
        if tabs.count >= maxTabs {
            closeOldestUnpinnedTab()
        }

        let tab = Tab(url: url?.absoluteString ?? "about:blank")
        tabs.append(tab)

        // Initialize WebView
        let config = WKWebViewConfiguration.sidePanelConfig
        let webView = WKWebView(frame: .zero, configuration: config)
        tab.webView = webView

        // Load URL
        if let url = url {
            webView.load(URLRequest(url: url))
        } else {
            loadDefaultPage(in: webView)
        }

        if activate {
            activateTab(tab)
        }

        saveTabs()
        return tab
    }

    func closeTab(_ tab: Tab) {
        guard !tab.isPinned else { return }

        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs.remove(at: index)

            // Activate next tab
            if activeTabId == tab.id {
                let newIndex = min(index, tabs.count - 1)
                if newIndex >= 0 {
                    activateTab(tabs[newIndex])
                } else {
                    activeTabId = nil
                }
            }

            // Cleanup WebView
            tab.webView?.stopLoading()
            tab.webView = nil

            saveTabs()
        }
    }

    func activateTab(_ tab: Tab) {
        activeTabId = tab.id
        tab.lastAccessedAt = Date()

        // Ensure WebView is initialized
        if tab.webView == nil {
            let config = WKWebViewConfiguration.sidePanelConfig
            let webView = WKWebView(frame: .zero, configuration: config)
            tab.webView = webView

            if let url = URL(string: tab.url) {
                webView.load(URLRequest(url: url))
            }
        }
    }

    func reorderTabs(from source: IndexSet, to destination: Int) {
        tabs.move(fromOffsets: source, toOffset: destination)

        // Update order property
        for (index, tab) in tabs.enumerated() {
            tab.order = index
        }

        saveTabs()
    }

    private func saveTabs() {
        // Core Data auto-saves with @Model
    }

    private func loadTabs() {
        // Fetch from Core Data on init
    }

    private func closeOldestUnpinnedTab() {
        let unpinned = tabs.filter { !$0.isPinned }
        if let oldest = unpinned.min(by: { $0.lastAccessedAt < $1.lastAccessedAt }) {
            closeTab(oldest)
        }
    }
}
```

### 5.4 Global Hotkeys

#### Hotkey Manager

```swift
import Carbon.HIToolbox

class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()

    private var eventHandler: EventHandlerRef?
    private var registeredHotkeys: [UInt32: () -> Void] = [:]

    func registerHotkeys() {
        // Register global shortcuts
        registerHotkey(keyCode: UInt32(kVK_ANSI_S), modifiers: cmdShift, id: 1) { [weak self] in
            self?.toggleSidebar()
        }

        registerHotkey(keyCode: UInt32(kVK_ANSI_N), modifiers: cmdShift, id: 2) { [weak self] in
            self?.newTab()
        }

        registerHotkey(keyCode: UInt32(kVK_ANSI_W), modifiers: cmdShift, id: 3) { [weak self] in
            self?.closeTab()
        }

        registerHotkey(keyCode: UInt32(kVK_ANSI_LeftBracket), modifiers: cmdShift, id: 4) { [weak self] in
            self?.previousTab()
        }

        registerHotkey(keyCode: UInt32(kVK_ANSI_RightBracket), modifiers: cmdShift, id: 5) { [weak self] in
            self?.nextTab()
        }

        registerHotkey(keyCode: UInt32(kVK_ANSI_L), modifiers: cmdShift, id: 6) { [weak self] in
            self?.focusAddressBar()
        }
    }

    private func registerHotkey(keyCode: UInt32, modifiers: UInt32, id: Int, action: @escaping () -> Void) {
        let hotKeyID = EventHotKeyID(signature: FourCharCode("SPKB"), id: UInt32(id))
        var hotKeyRef: EventHotKeyRef?

        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        registeredHotkeys[hotKeyID.id] = action
    }

    private let cmdShift: UInt32 = UInt32(cmdKey | shiftKey)

    // Actions
    private func toggleSidebar() {
        NotificationCenter.default.post(name: .toggleSidebar, object: nil)
    }

    private func newTab() {
        NotificationCenter.default.post(name: .newTab, object: nil)
    }

    private func closeTab() {
        NotificationCenter.default.post(name: .closeTab, object: nil)
    }

    private func previousTab() {
        NotificationCenter.default.post(name: .previousTab, object: nil)
    }

    private func nextTab() {
        NotificationCenter.default.post(name: .nextTab, object: nil)
    }

    private func focusAddressBar() {
        NotificationCenter.default.post(name: .focusAddressBar, object: nil)
    }
}

extension Notification.Name {
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let newTab = Notification.Name("newTab")
    static let closeTab = Notification.Name("closeTab")
    static let previousTab = Notification.Name("previousTab")
    static let nextTab = Notification.Name("nextTab")
    static let focusAddressBar = Notification.Name("focusAddressBar")
}
```

### 5.5 Settings & Preferences

#### Settings Model

```swift
@Model
class AppSettings {
    // General
    var launchAtLogin: Bool = false
    var rememberLastSession: Bool = true
    var defaultSearchEngine: String = "google"
    var downloadLocation: String = "~/Downloads"

    // Appearance
    var theme: Theme = .auto
    var accentColor: AccentColor = .system
    var transparency: Double = 0.85
    var sidebarWidth: Double = 420

    // Behavior
    var collapseBehavior: CollapseBehavior = .auto
    var autoCollapseDelay: Double = 2.0
    var floatPosition: FloatPosition = .right
    var showOnAllSpaces: Bool = true

    // Privacy
    var clearHistoryOnQuit: Bool = false
    var blockAds: Bool = false
    var doNotTrack: Bool = true
    var cookiePolicy: CookiePolicy = .allowAll

    // Keyboard (stored as key combinations)
    var shortcutToggle: KeyboardShortcut = .init(key: .s, modifiers: [.command, .shift])
    var shortcutNewTab: KeyboardShortcut = .init(key: .n, modifiers: [.command, .shift])
    var shortcutCloseTab: KeyboardShortcut = .init(key: .w, modifiers: [.command, .shift])

    enum Theme: String, Codable, CaseIterable {
        case auto, dark, light
    }

    enum AccentColor: String, Codable, CaseIterable {
        case system, blue, purple, pink, red, orange, green
    }

    enum CollapseBehavior: String, Codable, CaseIterable {
        case auto, manual, never
    }

    enum FloatPosition: String, Codable, CaseIterable {
        case left, right, custom
    }

    enum CookiePolicy: String, Codable, CaseIterable {
        case allowAll, blockThirdParty, blockAll
    }
}

struct KeyboardShortcut: Codable {
    var key: KeyEquivalent
    var modifiers: NSEvent.ModifierFlags
}
```

#### Settings View

```swift
struct SettingsView: View {
    @StateObject private var settings: SettingsManager

    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem { Label("General", systemImage: "gear") }

            AppearanceSettingsView(settings: settings)
                .tabItem { Label("Appearance", systemImage: "paintbrush") }

            BehaviorSettingsView(settings: settings)
                .tabItem { Label("Behavior", systemImage: "hand.tap") }

            PrivacySettingsView(settings: settings)
                .tabItem { Label("Privacy", systemImage: "shield") }

            ShortcutsSettingsView(settings: settings)
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(width: 500, height: 400)
    }
}
```

---

## 6. Data Models

### 6.1 Core Data Schema

```swift
// MARK: - Tab Entity
@Model
class TabEntity {
    @Attribute(.unique) var id: UUID
    var url: String
    var title: String
    var faviconURL: String?
    var createdAt: Date
    var lastAccessedAt: Date
    var order: Int
    var isPinned: Bool
    var isMuted: Bool

    init(id: UUID, url: String, title: String, order: Int) {
        self.id = id
        self.url = url
        self.title = title
        self.order = order
        self.createdAt = Date()
        self.lastAccessedAt = Date()
        self.isPinned = false
        self.isMuted = false
    }
}

// MARK: - History Entity
@Model
class HistoryEntity {
    @Attribute(.unique) var id: UUID
    var url: String
    var title: String
    var visitedAt: Date
    var visitCount: Int

    init(url: String, title: String) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.visitedAt = Date()
        self.visitCount = 1
    }
}

// MARK: - Window State Entity
@Model
class WindowStateEntity {
    @Attribute(.unique) var id: UUID
    var screenID: UUID
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var isPinned: Bool
    var isExpanded: Bool
    var activeTabId: UUID?
    var updatedAt: Date

    init(screenID: UUID, x: Double, y: Double, width: Double, height: Double, isPinned: Bool) {
        self.id = UUID()
        self.screenID = screenID
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.isPinned = isPinned
        self.isExpanded = true
        self.updatedAt = Date()
    }
}

// MARK: - Settings Entity
@Model
class SettingsEntity {
    @Attribute(.unique) var id: UUID = UUID()

    // General
    var launchAtLogin: Bool = false
    var rememberLastSession: Bool = true
    var defaultSearchEngine: String = "google"
    var downloadLocation: String = "~/Downloads"

    // Appearance
    var themeRaw: String = "auto"
    var accentColorRaw: String = "system"
    var transparency: Double = 0.85
    var sidebarWidth: Double = 420

    // Behavior
    var collapseBehaviorRaw: String = "auto"
    var autoCollapseDelay: Double = 2.0
    var floatPositionRaw: String = "right"
    var showOnAllSpaces: Bool = true

    // Privacy
    var clearHistoryOnQuit: Bool = false
    var blockAds: Bool = false
    var doNotTrack: Bool = true
    var cookiePolicyRaw: String = "allowAll"

    // Computed properties for enums
    var theme: AppSettings.Theme {
        get { AppSettings.Theme(rawValue: themeRaw) ?? .auto }
        set { themeRaw = newValue.rawValue }
    }
}
```

### 6.2 Data Persistence Strategy

```swift
class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    init() {
        let schema = Schema([
            TabEntity.self,
            HistoryEntity.self,
            WindowStateEntity.self,
            SettingsEntity.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    // Auto-save every 30 seconds
    func startAutoSave() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            try? self.container.mainContext.save()
        }
    }
}
```

---

## 7. File Structure

```
SidePanel/
├── SidePanel.xcodeproj/
├── SidePanel/
│   ├── App/
│   │   ├── SidePanelApp.swift              # App entry point
│   │   ├── AppDelegate.swift               # App lifecycle, permissions
│   │   └── Info.plist                      # App metadata
│   │
│   ├── Window/
│   │   ├── FloatingPanel.swift             # Main panel window (NSPanel)
│   │   ├── CollapsedButtonWindow.swift     # Collapsed state window
│   │   ├── PanelManager.swift              # Window state & position management
│   │   └── WindowPositionManager.swift       # Multi-display, positioning logic
│   │
│   ├── UI/
│   │   ├── Views/
│   │   │   ├── SidebarView.swift           # Main container view
│   │   │   ├── TabBarView.swift             # Vertical tab strip
│   │   │   ├── TabButton.swift              # Individual tab UI
│   │   │   ├── AddressBar.swift             # URL/search input
│   │   │   ├── WebViewContainer.swift       # WKWebView wrapper
│   │   │   ├── ToolbarView.swift            # Top controls (pin, settings)
│   │   │   ├── CollapsedButtonView.swift    # Collapsed state button
│   │   │   └── ContentView.swift            # Root SwiftUI view
│   │   │
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift           # Main settings container
│   │   │   ├── GeneralSettingsView.swift
│   │   │   ├── AppearanceSettingsView.swift
│   │   │   ├── BehaviorSettingsView.swift
│   │   │   ├── PrivacySettingsView.swift
│   │   │   └── ShortcutsSettingsView.swift
│   │   │
│   │   └── Components/
│   │       ├── GlassBackground.swift        # Glassmorphism background
│   │       ├── FaviconImage.swift           # Async favicon loader
│   │       ├── TooltipView.swift            # Hover tooltips
│   │       ├── LoadingIndicator.swift       # Progress spinner
│   │       └── ContextMenu.swift            # Right-click menus
│   │
│   ├── Web/
│   │   ├── WebViewManager.swift            # WebView lifecycle
│   │   ├── WebViewCoordinator.swift        # Navigation delegate
│   │   ├── WebViewConfiguration.swift       # WKWebView settings
│   │   └── UserScriptManager.swift          # Inject custom JS if needed
│   │
│   ├── Tabs/
│   │   ├── Tab.swift                       # Tab model (SwiftData)
│   │   ├── TabManager.swift                 # Tab CRUD operations
│   │   ├── TabPersistence.swift           # Save/restore tabs
│   │   └── TabDragDrop.swift                # Reordering logic
│   │
│   ├── Data/
│   │   ├── PersistenceController.swift       # Core Data container
│   │   ├── HistoryManager.swift            # Browsing history
│   │   ├── SettingsManager.swift           # User preferences
│   │   └── SessionManager.swift            # Auto-save/restore
│   │
│   ├── Utils/
│   │   ├── GlobalHotkeyManager.swift        # Keyboard shortcuts
│   │   ├── AutoCollapseManager.swift        # Hover detection
│   │   ├── ThemeManager.swift              # Dark/light mode
│   │   ├── ColorExtensions.swift           # Design system colors
│   │   ├── FontExtensions.swift            # Typography
│   │   └── LayoutMetrics.swift             # Spacing constants
│   │
│   └── Resources/
│       ├── Assets.xcassets/
│       │   ├── AppIcon.appiconset/
│       │   ├── Colors/
│       │   └── Icons/
│       └── Preview Content/
│
├── SidePanelTests/
│   ├── PanelManagerTests.swift
│   ├── TabManagerTests.swift
│   └── WebViewTests.swift
│
├── SidePanelUITests/
│   └── SidePanelUITests.swift
│
├── README.md
├── LICENSE
└── SidePanel.specification.md (this file)
```

---

## 8. Implementation Guide

### 8.1 Phase 1: Foundation (Weeks 1-2)

#### Week 1: Project Setup & Window

1. Create Xcode project (macOS App, SwiftUI interface)
2. Configure Info.plist for accessibility permissions
3. Create `FloatingPanel` class extending `NSPanel`
4. Implement basic window behavior:
   - Always on top (`level = .floating`)
   - Borderless style
   - Movable by background
   - Position on right edge of screen
5. Create `ContentView` with placeholder UI
6. Test window positioning and dragging

#### Week 2: Collapse/Expand & State Management

1. Create `PanelManager` singleton
2. Implement PanelState enum and transitions
3. Create `CollapsedButtonWindow` for collapsed state
4. Implement pin/unpin toggle
5. Add animation between states
6. Create `AutoCollapseManager` for hover detection
7. Test state persistence

**Deliverable:** Working floating panel with pin/unpin states

### 8.2 Phase 2: WebView Integration (Weeks 3-4)

#### Week 3: WKWebView Setup

1. Create `WebViewConfiguration` with proper settings
2. Create `WebViewContainer` SwiftUI wrapper
3. Implement `WebViewCoordinator` for navigation delegate
4. Add basic toolbar (back, forward, refresh)
5. Implement address bar with URL parsing
6. Test loading various websites

#### Week 4: Tab System Foundation

1. Create `Tab` SwiftData model
2. Create `TabManager` with create/close/activate
3. Create `TabBarView` UI
4. Implement basic vertical tab strip
5. Connect tabs to WebViews
6. Test multiple tabs

**Deliverable:** Multi-tab browser in floating panel

### 8.3 Phase 3: Tab Management (Weeks 5-6)

#### Week 5: Advanced Tab Features

1. Implement favicon loading (AsyncImage)
2. Add tab reordering (drag-and-drop)
3. Implement pinned tabs
4. Add tab context menus (close, duplicate, mute)
5. Create tab persistence (Core Data)
6. Implement session restore

#### Week 6: UI Polish

1. Implement glassmorphism backgrounds
2. Add dark/light mode support
3. Create `ThemeManager`
4. Polish tab animations
5. Add loading indicators
6. Create tooltips

**Deliverable:** Polished tab system with persistence

### 8.4 Phase 4: System Integration (Weeks 7-8)

#### Week 7: Global Shortcuts

1. Create `GlobalHotkeyManager`
2. Register Carbon hotkeys
3. Implement all shortcut actions
4. Test shortcuts from other apps
5. Add shortcut conflict detection
6. Create permissions prompt UX

#### Week 8: Settings & Preferences

1. Create `SettingsManager`
2. Build all settings views
3. Implement settings persistence
4. Add launch at login (SMLoginItemSetEnabled)
5. Create about/help panel
6. Final UI polish

**Deliverable:** Fully functional with settings

### 8.5 Phase 5: Testing & Distribution (Weeks 9-10)

#### Week 9: Testing

1. Unit tests for managers
2. UI tests for critical paths
3. Multi-display testing
4. Performance profiling (Instruments)
5. Memory leak detection
6. Beta testing with users

#### Week 10: Distribution

1. Code signing setup
2. Create DMG with background image
3. Write README and documentation
4. Create GitHub repository
5. Write release notes
6. Publish GitHub release

**Deliverable:** Shippable application

### 8.6 Critical Implementation Details

#### Creating the Floating Panel Window

```swift
import SwiftUI
import AppKit

class FloatingPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 800),
            styleMask: [.borderless, .nonactivatingPanel, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        // Visual setup
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.shadowColor = NSColor.black.withAlphaComponent(0.3)

        // Behavior
        self.level = .floating
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle,
            .moveToActiveSpace
        ]
        self.isMovableByWindowBackground = true

        // Don't show in dock/app switcher
        self.styleMask.insert(.utilityWindow)

        // Enable drag from background
        self.isMovableByWindowBackground = true
    }

    // Allow becoming key window for text input
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return false  // Don't steal main window status
    }
}
```

#### SwiftUI Integration with AppKit

```swift
struct FloatingPanelView: NSViewRepresentable {
    @Binding var isPinned: Bool
    let onCollapse: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // Setup view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Update based on state
    }
}

// Or use NSHostingController approach
class PanelManager: ObservableObject {
    var panel: FloatingPanel?
    var hostingController: NSHostingController<ContentView>?

    func showPanel() {
        let panel = FloatingPanel()
        let contentView = ContentView()
        let hostingController = NSHostingController(rootView: contentView)

        panel.contentView = hostingController.view
        panel.makeKeyAndOrderFront(nil)

        self.panel = panel
        self.hostingController = hostingController
    }
}
```

#### Handling Permissions

```swift
import Accessibility

class PermissionManager {
    static func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        return accessibilityEnabled
    }

    static func requestAccessibilityPermission() {
        // Show dialog explaining why we need it
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "SidePanel needs accessibility access to:\n• Detect which app is active\n• Enable global keyboard shortcuts\n• Stay visible across all applications"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open Security & Privacy preferences
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
}
```

---

## 9. Testing Strategy

### 9.1 Unit Tests

```swift
import XCTest
@testable import SidePanel

final class TabManagerTests: XCTestCase {
    var tabManager: TabManager!

    override func setUp() {
        super.setUp()
        // Setup in-memory Core Data
        tabManager = TabManager(container: PersistenceController.preview.container)
    }

    func testCreateTab() {
        let initialCount = tabManager.tabs.count
        let tab = tabManager.createTab(url: URL(string: "https://example.com"))

        XCTAssertEqual(tabManager.tabs.count, initialCount + 1)
        XCTAssertEqual(tab.url, "https://example.com")
        XCTAssertEqual(tabManager.activeTabId, tab.id)
    }

    func testCloseTab() {
        let tab = tabManager.createTab()
        let tabId = tab.id

        tabManager.closeTab(tab)

        XCTAssertFalse(tabManager.tabs.contains { $0.id == tabId })
    }

    func testMaxTabsLimit() {
        // Create 50 tabs
        for i in 0..<55 {
            tabManager.createTab(url: URL(string: "https://example\(i).com"))
        }

        // Should be limited to 50
        XCTAssertLessThanOrEqual(tabManager.tabs.count, 50)
    }

    func testTabReordering() {
        let tab1 = tabManager.createTab()
        let tab2 = tabManager.createTab()
        let tab3 = tabManager.createTab()

        // Move tab1 to position 2
        tabManager.reorderTabs(from: IndexSet([0]), to: 2)

        XCTAssertEqual(tabManager.tabs[0].id, tab2.id)
        XCTAssertEqual(tabManager.tabs[1].id, tab1.id)
        XCTAssertEqual(tabManager.tabs[2].id, tab3.id)
    }
}

final class PanelManagerTests: XCTestCase {
    func testStateTransitions() {
        let manager = PanelManager()

        // Initial state
        XCTAssertEqual(manager.state, .pinned(expanded: true))

        // Unpin
        manager.unpin()
        XCTAssertEqual(manager.state, .unpinned)

        // Pin again
        manager.pin()
        XCTAssertEqual(manager.state, .pinned(expanded: true))
    }

    func testTemporaryExpand() {
        let manager = PanelManager()
        manager.unpin()

        // Hover
        manager.handleHover(true)
        XCTAssertEqual(manager.state, .temporarilyExpanded)

        // Leave
        manager.handleHover(false)
        XCTAssertEqual(manager.state, .unpinned)
    }
}
```

### 9.2 UI Tests

```swift
import XCTest

final class SidePanelUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testCreateNewTab() {
        // Tap new tab button
        app.buttons["newTabButton"].tap()

        // Verify new tab exists
        XCTAssertEqual(app.buttons.matching(identifier: "tabButton").count, 2)
    }

    func testAddressBarNavigation() {
        // Focus address bar
        app.textFields["addressBar"].tap()

        // Type URL
        app.typeText("https://example.com")
        app.keyboards.buttons["Return"].tap()

        // Wait for load
        let webView = app.webViews.firstMatch
        XCTAssertTrue(webView.waitForExistence(timeout: 5))
    }

    func testPinUnpin() {
        // Find pin button
        let pinButton = app.buttons["pinButton"]

        // Tap to unpin
        pinButton.tap()

        // Verify collapsed state
        let collapsedButton = app.otherElements["collapsedButton"]
        XCTAssertTrue(collapsedButton.exists)

        // Tap to expand
        collapsedButton.tap()

        // Verify expanded
        XCTAssertTrue(app.otherElements["sidebarView"].exists)
    }

    func testKeyboardShortcuts() {
        // Test Cmd+Shift+N for new tab
        app.keyboards.keys["Command"].press(forDuration: 0.1)
        app.keyboards.keys["Shift"].press(forDuration: 0.1)
        app.keyboards.keys["n"].press(forDuration: 0.1)

        // Verify tab created
        XCTAssertEqual(app.buttons.matching(identifier: "tabButton").count, 2)
    }
}
```

### 9.3 Manual Testing Checklist

#### Window Behavior

- [ ] Panel stays on top of other apps
- [ ] Panel visible across all Spaces
- [ ] Panel doesn't appear in Dock
- [ ] Panel doesn't appear in Cmd+Tab
- [ ] Can drag panel by background
- [ ] Can resize panel from edges
- [ ] Position restored after relaunch

#### Pin/Unpin

- [ ] Pin button expands to full sidebar
- [ ] Unpin collapses to floating icon
- [ ] Hover over icon temporarily expands
- [ ] Mouse leave after delay collapses
- [ ] Click icon toggles pin state
- [ ] Pin state restored after relaunch

#### WebView

- [ ] Google loads correctly
- [ ] YouTube videos play
- [ ] GitHub works
- [ ] Back/forward navigation works
- [ ] Refresh works
- [ ] Address bar updates on navigation
- [ ] New tab opens with default page

#### Tabs

- [ ] Create tab adds to list
- [ ] Close tab removes from list
- [ ] Active tab highlighted
- [ ] Tab switch updates WebView
- [ ] Favicons load
- [ ] Tab order persists
- [ ] Drag to reorder works
- [ ] Pinned tabs don't close

#### Keyboard Shortcuts

- [ ] Cmd+Shift+S toggles sidebar
- [ ] Cmd+Shift+N creates tab
- [ ] Cmd+Shift+W closes tab
- [ ] Cmd+Shift+[ previous tab
- [ ] Cmd+Shift+] next tab
- [ ] Cmd+Shift+L focuses address bar
- [ ] All shortcuts work from other apps

#### Settings

- [ ] Theme changes apply immediately
- [ ] Sidebar width changes apply
- [ ] Auto-collapse delay changes work
- [ ] Launch at login setting works
- [ ] Settings persist after relaunch

#### Multi-Display

- [ ] Panel appears on active display
- [ ] Position maintained per display
- [ ] Dragging between displays works
- [ ] Correct display remembered

#### Performance

- [ ] CPU usage < 5% when idle
- [ ] Memory usage reasonable (< 500MB for 10 tabs)
- [ ] Tab switch < 500ms
- [ ] No memory leaks after extended use

---

## 10. Distribution

### 10.1 Code Signing Setup

```bash
# 1. Create Certificate Signing Request
# Open Keychain Access > Certificate Assistant > Request Certificate

# 2. In Apple Developer Portal:
# - Create Mac Developer certificate
# - Download and install

# 3. In Xcode:
# - Select SidePanel target
# - Signing & Capabilities
# - Team: [Your Team]
# - Certificate: Mac Developer
# - Enable Hardened Runtime

# 4. Build for Release
xcodebuild -project SidePanel.xcodeproj -scheme SidePanel -configuration Release

# 5. Sign the app
codesign --force --deep --sign "Developer ID Application: Your Name" SidePanel.app

# 6. Verify signing
codesign -dv --verbose=4 SidePanel.app
spctl -a -vv SidePanel.app
```

### 10.2 DMG Creation

```bash
#!/bin/bash
# create_dmg.sh

APP_NAME="SidePanel"
DMG_NAME="${APP_NAME}-1.0.dmg"
VOLUME_NAME="${APP_NAME} Installer"

# Create temporary directory
mkdir -p build/dmg
cp -r "build/Release/${APP_NAME}.app" build/dmg/

# Create DMG with custom background
hdiutil create -volname "${VOLUME_NAME}" -srcfolder build/dmg -ov -format UDZO "${DMG_NAME}"

# Mount for customization
hdiutil attach "${DMG_NAME}"

# Copy background image
mkdir "/Volumes/${VOLUME_NAME}/.background"
cp Resources/dmg_background.png "/Volumes/${VOLUME_NAME}/.background/"

# Create alias to Applications
ln -s /Applications "/Volumes/${VOLUME_NAME}/Applications"

# Set custom icon positions (using AppleScript)
osascript <<EOF
tell application "Finder"
    set disk to disk "${VOLUME_NAME}"
    open disk
    set current view of container window of disk to icon view
    set arrangement of icon view options of container window of disk to not arranged
    set icon size of icon view options of container window of disk to 80
    set text size of icon view options of container window of disk to 12
    set position of item "${APP_NAME}.app" of disk to {120, 180}
    set position of item "Applications" of disk to {360, 180}
    set background picture of icon view options of container window of disk to file ".background:dmg_background.png"
    close container window of disk
end tell
EOF

# Unmount
hdiutil detach "/Volumes/${VOLUME_NAME}"

# Compress
hdiutil convert "${DMG_NAME}" -format UDZO -o "${DMG_NAME}"

# Cleanup
rm -rf build/dmg

echo "Created ${DMG_NAME}"
```

### 10.3 GitHub Release Process

```bash
#!/bin/bash
# release.sh

VERSION="1.0.0"
DMG="SidePanel-${VERSION}.dmg"

# 1. Update version in Xcode project
# 2. Build and sign
# 3. Create DMG

# 4. Create GitHub release
gh release create "v${VERSION}" \
  "${DMG}" \
  --title "SidePanel ${VERSION}" \
  --notes-file CHANGELOG.md \
  --draft

# 5. Wait for testing, then publish
gh release edit "v${VERSION}" --draft=false
```

### 10.4 Installation Instructions (for README)

```markdown
# SidePanel

A floating sidebar browser for macOS. Browse the web without leaving your workflow.

## Installation

### Option 1: Download DMG

1. Download `SidePanel-1.0.dmg` from [Releases](../../releases)
2. Open the DMG file
3. Drag SidePanel to your Applications folder
4. Launch SidePanel from Applications

### Option 2: Build from Source

1. Clone this repository
2. Open `SidePanel.xcodeproj` in Xcode 15+
3. Build and run (Cmd+R)

## First Launch

On first launch, SidePanel will request Accessibility permission:

1. Click "Open System Preferences"
2. Click the lock icon (authenticate)
3. Find SidePanel in the list
4. Check the checkbox next to SidePanel
5. Relaunch SidePanel

This permission is required for:

- Global keyboard shortcuts (work from any app)
- Staying visible across all applications

## Usage

**Keyboard Shortcuts:**

- `Cmd+Shift+S` - Toggle sidebar
- `Cmd+Shift+N` - New tab
- `Cmd+Shift+W` - Close tab
- `Cmd+Shift+[` - Previous tab
- `Cmd+Shift+]` - Next tab
- `Cmd+Shift+L` - Focus address bar

**Mouse:**

- Drag the sidebar by its background
- Hover over collapsed button to temporarily expand
- Click pin button to keep sidebar open
- Right-click tabs for options

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac

## License

MIT License - see LICENSE file
```

---

## 11. Future Enhancements (Post-V1)

### 11.1 Version 2.0 Ideas

- Split view (two web views side-by-side)
- Built-in ad blocker
- Picture-in-picture video
- Quick notes panel
- Workspace profiles (separate tab sets)
- iCloud sync across Macs
- Custom CSS/JS injection

### 11.2 Advanced Features

- Plugin system
- Developer tools integration
- Proxy/VPN support
- Download manager
- Password manager integration
- Reader mode
- Translate feature

---

## 12. Appendix

### 12.1 Useful Resources

**Apple Documentation:**

- [NSPanel Documentation](https://developer.apple.com/documentation/appkit/nspanel)
- [WKWebView Documentation](https://developer.apple.com/documentation/webkit/wkwebview)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Global Hotkeys](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/Carbon_Event_Manager/Tasks/CarbonEventsTasks.html)

**Third-Party Libraries (Optional):**

- [Kingfisher](https://github.com/onevcat/Kingfisher) - Async image loading
- [HotKey](https://github.com/soffes/HotKey) - Simplified global shortcuts
- [Preferences](https://github.com/sindresorhus/Preferences) - Settings window

### 12.2 Troubleshooting Guide

**Panel not staying on top:**

- Check `level = .floating` is set
- Verify `collectionBehavior` includes `.canJoinAllSpaces`

**Keyboard shortcuts not working:**

- Verify Accessibility permission is granted
- Check no other app has conflicting shortcuts

**WebView not loading sites:**

- Check internet connection
- Verify `allowsContentJavaScript = true`
- Check console for errors

**High memory usage:**

- Limit max tabs in settings
- Suspend inactive tabs after timeout
- Check for memory leaks with Instruments

### 12.3 Performance Benchmarks

Target metrics for release:

| Metric           | Target  | Maximum |
| ---------------- | ------- | ------- |
| Cold Launch      | < 1.5s  | 2s      |
| Tab Switch       | < 300ms | 500ms   |
| Memory (10 tabs) | < 400MB | 600MB   |
| CPU Idle         | < 3%    | 5%      |
| Resize FPS       | 60fps   | 30fps   |

---

## 13. Conclusion

This specification provides a complete blueprint for building SidePanel, a native macOS floating sidebar browser. The architecture uses Swift/SwiftUI with AppKit for the floating panel behavior, WKWebView for web rendering, and Core Data for persistence.

Key technical achievements:

- Native floating panel that stays on top across all apps
- Full WebKit browser with no iframe restrictions
- Smart pin/unpin with auto-collapse
- Global keyboard shortcuts
- Modern glassmorphism UI
- Session persistence

Development timeline: 10 weeks to v1.0 release.

---

**Document Version:** 1.0  
**Last Updated:** 2025  
**Author:** Sayuru Amarasinghe  
**Status:** Ready for Implementation
