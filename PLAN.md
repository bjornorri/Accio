# Accio - macOS Hotkey App Implementation Plan

## Overview

Accio is a macOS menu bar app that lets users bind global hotkeys to applications with configurable behavior based on app state (not running, not focused, focused). Built with SwiftUI, protocol-based architecture with Factory DI, and Defaults library for persistence.

## Third-Party Libraries

### Core Dependencies

1. **[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)** (v2.0+)

   - **Function**: Global hotkey registration and management
   - **Features**: Built-in SwiftUI recorder component, conflict detection, UserDefaults integration
   - **URL**: `https://github.com/sindresorhus/KeyboardShortcuts.git`

2. **[Factory](https://github.com/hmlongco/Factory)** (v2.0+)

   - **Function**: Dependency injection container
   - **Features**: Compile-time safe, lightweight, great for SwiftUI
   - **URL**: `https://github.com/hmlongco/Factory.git`

3. **[Defaults](https://github.com/sindresorhus/Defaults)** (v8.0+)

   - **Function**: Type-safe UserDefaults wrapper
   - **Features**: Strongly-typed preferences, SwiftUI integration with @Default property wrapper
   - **URL**: `https://github.com/sindresorhus/Defaults.git`

4. **[LaunchAtLogin-Modern](https://github.com/sindresorhus/LaunchAtLogin-Modern)** (v1.0+)
   - **Function**: Launch at login functionality
   - **Features**: Modern SMAppService API wrapper, SwiftUI toggle component
   - **URL**: `https://github.com/sindresorhus/LaunchAtLogin-Modern.git`

### Testing Dependencies

5. **[swift-clocks](https://github.com/pointfreeco/swift-clocks)** (v1.0+)
   - **Function**: Testable time abstraction using Swift's `Clock` protocol
   - **Features**: `TestClock` for deterministic time control in tests, `ImmediateClock` for instant execution
   - **URL**: `https://github.com/pointfreeco/swift-clocks.git`
   - **Usage**: Production code uses `ContinuousClock`, tests use `TestClock` to advance time without waiting

### Window Management Strategy

**System Cmd+` for window cycling** (initial implementation)

- Use native macOS window cycling behavior
- Send Cmd+` programmatically via CGEvent when needed
- **Interface design**: Keep protocol flexible to allow custom implementation later

## Key Technical Decisions

| Decision                 | Choice                                    | Rationale                                                                |
| ------------------------ | ----------------------------------------- | ------------------------------------------------------------------------ |
| **Hotkey Library**       | KeyboardShortcuts by Sindre Sorhus        | Modern Swift/SwiftUI, built-in recorder UI component, conflict detection |
| **Dependency Injection** | Factory library                           | Compile-time safe, lightweight, excellent SwiftUI integration            |
| **Storage**              | Defaults library (type-safe UserDefaults) | Strongly-typed, SwiftUI property wrapper support                         |
| **Launch at Login**      | LaunchAtLogin-Modern                      | Modern SMAppService API wrapper                                          |
| **UI Pattern**           | MenuBarExtra + Custom Settings Window     | Menu bar for quick access, custom window for full dock/switcher control  |
| **Architecture**         | Protocol-based with Factory DI            | Maximum testability, mockable interfaces                                 |
| **Window Cycling**       | System Cmd+` (initially)                  | Simple, reliable, replaceable via protocol later                         |
| **App Sandbox**          | **DISABLED** (critical)                   | Required for global hotkeys and Accessibility API                        |
| **Distribution**         | Outside Mac App Store                     | Sandbox incompatible; use Developer ID + notarization                    |

## Required Permissions & Entitlements

### 1. Disable App Sandbox

```xml
<!-- Accio.entitlements -->
<key>com.apple.security.app-sandbox</key>
<false/>
```

### 2. Accessibility Permission

- Required for global hotkeys and window management
- User must manually grant in System Settings > Privacy & Security > Accessibility
- Check with `AXIsProcessTrusted()`
- Show permission prompt UI on first launch

### 3. Info.plist Configuration

```xml
<key>LSUIElement</key>
<true/>  <!-- Hide dock icon for menu bar-only mode -->
```

## Core Architecture

### Protocol Abstractions

```
HotkeyManager          → Register/unregister global hotkeys (supports async handlers)
ApplicationManager     → Launch (async), focus apps; check app state; enumerate installed apps
WindowCyclingStrategy  → Trigger window cycling (initially: send Cmd+`, replaceable later)
AccessibilityPermissionManager → Check/request accessibility permissions
ActionCoordinator      → Execute hotkey actions based on global behavior settings
```

### Data Models

**New Settings Model**: Global behavior based on app state

```swift
// Per-app hotkey binding
HotkeyBinding {
    id: UUID
    shortcutName: String  // Maps to KeyboardShortcuts.Name
    appBundleIdentifier: String
}

// Global behavior settings (apply to all bindings)
AppBehaviorSettings {
    whenNotRunning: NotRunningAction     // .doNothing | .launchApp
    whenNotFocused: NotFocusedAction     // .doNothing | .focusApp
    whenFocused: FocusedAction           // .doNothing | .cycleWindows | .hideApp
    showNotificationWhenLaunching: Bool
}

enum NotRunningAction: String, Codable {
    case doNothing
    case launchApp
}

enum NotFocusedAction: String, Codable {
    case doNothing
    case focusApp
}

enum FocusedAction: String, Codable {
    case doNothing
    case cycleWindows
    case hideApp
}

ApplicationInfo {
    id: String  // bundle identifier
    name: String
    iconPath: String?
    bundleURL: URL
}

AppPreferences {
    launchAtLogin: Bool
}
```

### Dependency Injection with Factory

Use Factory library for compile-time safe DI:

```swift
extension Container {
    var hotkeyManager: Factory<HotkeyManager> {
        self { KeyboardShortcutsHotkeyManager() }
    }

    var applicationManager: Factory<ApplicationManager> {
        self { NSWorkspaceApplicationManager() }
    }

    var windowCyclingStrategy: Factory<WindowCyclingStrategy> {
        self { SystemWindowCyclingStrategy() }  // Sends Cmd+`
    }

    var permissionManager: Factory<AccessibilityPermissionManager> {
        self { AXAccessibilityPermissionManager() }
    }

    var actionCoordinator: Factory<ActionCoordinator> {
        self { DefaultActionCoordinator() }
    }
}
```

### Central Coordinator

`BindingOrchestrator`:

- Loads bindings and behavior settings from Defaults on init
- Registers all bindings with HotkeyManager
- Connects hotkey triggers → ActionCoordinator
- ActionCoordinator checks app state and executes based on global behavior settings
- Handles add/remove/update binding operations
- Persists changes immediately via Defaults

## Implementation Steps

Each step builds a complete, testable feature. You'll have working functionality at the end of each phase.

### Step 1: Project Setup & Boilerplate 🎯

**Goal**: Clean foundation with dependency injection ready to use.

**What you'll build**:

- Clean Xcode project with no SwiftData clutter
- All 4 Swift packages installed and working
- Factory DI container set up with empty/stub implementations

**Tasks**:

1. Delete `Item.swift`
2. Remove all SwiftData code from `AccioApp.swift` and `ContentView.swift`
3. Add Swift Package Dependencies:
   - `https://github.com/sindresorhus/KeyboardShortcuts.git` (v2.0+)
   - `https://github.com/hmlongco/Factory.git` (v2.0+)
   - `https://github.com/sindresorhus/Defaults.git` (v8.0+)
   - `https://github.com/sindresorhus/LaunchAtLogin-Modern.git` (v1.0+)
4. Create `Core/DependencyContainer.swift` with Factory extensions (stub implementations for now)
5. Verify project compiles successfully

**Files**: `AccioApp.swift`, `ContentView.swift`, `Core/DependencyContainer.swift`

**Success criteria**: ✅ Project builds with no errors

---

### Step 2: Configure Project Settings 🎯

**Goal**: Disable sandbox and prepare for global hotkeys.

**What you'll build**:

- Proper entitlements for hotkey access
- App configured to request accessibility permissions

**Tasks**:

1. Create `Accio.entitlements`
2. Set `com.apple.security.app-sandbox = false`
3. Update Xcode project to reference entitlements file
4. Verify hardened runtime is enabled
5. Build and verify entitlements are applied

**Files**: `Accio.entitlements`, Xcode project settings

**Success criteria**: ✅ App builds with sandbox disabled

---

### Step 3: Settings Window Behavior 🎯

**Goal**: Working menu bar app with settings window that shows/hides from dock.

**What you'll build**:

- Menu bar icon with dropdown
- Custom settings window (placeholder content for now)
- Dynamic dock/app switcher behavior (appears when settings open, hides when closed)
- Single window instance management
- Qmd+Q closes the settings window, but does not quit the app

**Tasks**:

1. Create `AppDelegate.swift`:
   - NSStatusBar menu bar item with SF Symbol `wand.and.stars`
   - Menu with "Settings..." and "Quit"
   - Set initial activation policy to `.accessory`
2. Update `AccioApp.swift` to use `@NSApplicationDelegateAdaptor`
3. Create `Core/WindowManager.swift`:
   - Singleton managing settings window lifecycle
   - `showSettings()`: creates/shows window, sets policy to `.regular`
   - Observes window close to set policy back to `.accessory`
4. Create `Views/SettingsWindow.swift`: NSWindow subclass (600x400, centered)
5. Create `Views/SettingsView.swift`: Placeholder SwiftUI view (just "Settings" text)
6. Wire menu bar "Settings..." to `WindowManager.shared.showSettings()`

**Files**: `AppDelegate.swift`, `Core/WindowManager.swift`, `Views/SettingsWindow.swift`, `Views/SettingsView.swift`

**Success criteria**:

- ✅ Menu bar icon appears
- ✅ Click "Settings..." opens window
- ✅ App shows in dock/Cmd+Tab when window is open
- ✅ App hides from dock/Cmd+Tab when window is closed
- ✅ Opening settings twice doesn't create duplicate window
- ✅ Settings window closes on Qmd+Q, but app keeps running

---

### Step 4: Accessibility Permission UI 🎯

**Goal**: Permission status display with guided permission flow.

**What you'll build**:

- Permission manager checking `AXIsProcessTrusted()`
- UI showing permission status in settings window
- Button to open System Settings
- Real-time permission status updates

**Tasks**:

1. Create `Protocols/AccessibilityPermissionManager.swift`
2. Create `Implementations/AXAccessibilityPermissionManager.swift`:
   - `hasPermission`: Use `AXIsProcessTrusted()`
   - `requestPermission()`: Show system prompt
   - `observePermissionChanges()`: Poll every 1 second
3. Register with Factory DI in `DependencyContainer.swift`
4. Update `Views/SettingsView.swift`:
   - Show green ✓ "Permission Granted" OR yellow ⚠️ "Permission Required"
   - "Open System Settings" button (when not granted)
   - Real-time updates using `@State` and permission observer
5. Test permission flow end-to-end

**Files**: `Protocols/AccessibilityPermissionManager.swift`, `Implementations/AXAccessibilityPermissionManager.swift`, `Views/SettingsView.swift`, `Core/DependencyContainer.swift`

**Success criteria**:

- ✅ Permission status displays correctly
- ✅ Button opens System Settings to correct pane
- ✅ Status updates automatically when permission granted

---

### Step 5: Hardcoded Safari Hotkey (Cmd+Shift+S) 🎯

**Goal**: End-to-end hotkey working for Safari. Press Cmd+Shift+S → Safari launches/focuses.

**What you'll build**:

- Application manager that can launch and focus Safari
- Hotkey manager that listens for Cmd+Shift+S
- Working integration: hotkey press → Safari launches/focuses

**Tasks**:

1. Create `Protocols/ApplicationManager.swift`
2. Create `Implementations/NSWorkspaceApplicationManager.swift`:
   - `launch(bundleIdentifier:) async`: Launch Safari (activates immediately)
   - `activate(bundleIdentifier:)`: Focus Safari
   - `isRunning()`, `isFocused()`: Check Safari state
3. Create `Protocols/HotkeyManager.swift` (supports async handlers)
4. Create `Implementations/KeyboardShortcutsHotkeyManager.swift`:
   - Wraps async handlers in Task for KeyboardShortcuts library
   - Uses `KeyboardShortcuts.removeHandler(for:)` and `.removeAllHandlers()` for cleanup
5. Create `Core/KeyboardShortcutNames.swift`: Define `.safari` shortcut (Cmd+Shift+S)
6. Register both with Factory DI
7. In `AppDelegate.didFinishLaunching`: register the hardcoded Cmd+Shift+S → Safari hotkey
8. Test: Press Cmd+Shift+S → Safari should launch/focus

**Files**: `Protocols/ApplicationManager.swift`, `Implementations/NSWorkspaceApplicationManager.swift`, `Protocols/HotkeyManager.swift`, `Implementations/KeyboardShortcutsHotkeyManager.swift`, `Core/KeyboardShortcutNames.swift`, `AppDelegate.swift`

**Success criteria**:

- ✅ Press Cmd+Shift+S anywhere on system
- ✅ Safari launches (if not running)
- ✅ Safari focuses (if running but not focused)

**Implementation notes**:

- `ApplicationManager.launch()` is async because `NSWorkspace.openApplication()` is async
- Launch configuration sets `activates = true` to immediately focus the app when launching
- `HotkeyManager` accepts async handlers, wrapping them in `Task` for the synchronous KeyboardShortcuts library
- KeyboardShortcuts provides `removeHandler(for:)` and `removeAllHandlers()` for proper cleanup
- Hide functionality deferred to later (not in ApplicationManager protocol yet)
- macOS 14+ compatibility: `.activateIgnoringOtherApps` is deprecated, use empty options

---

### Step 6: Behavior Settings UI 🎯

**Goal**: UI to configure global behavior settings.

**What you'll build**:

- Data models for behavior settings
- Defaults persistence
- UI with pickers for all three states + notification toggle
- Settings save automatically

**Tasks**:

1. Create `Models/AppBehaviorSettings.swift`:
   - `NotRunningAction` enum (.doNothing, .launchApp)
   - `NotFocusedAction` enum (.doNothing, .focusApp)
   - `FocusedAction` enum (.doNothing, .cycleWindows, .hideApp)
   - `AppBehaviorSettings` struct with all three + notification bool
2. Create `Core/DefaultsKeys.swift`:
   - Define `Defaults.Key` for behavior settings
   - Make settings conform to `Defaults.Serializable`
3. Update `Views/SettingsView.swift`:
   - Add "Behavior" section with:
     - Picker: "When app is not running" → [Do nothing, Launch app]
     - Picker: "When app is not focused" → [Do nothing, Focus app]
     - Picker: "When app is focused" → [Do nothing, Cycle Windows, Hide app]
     - Toggle: "Show notification when launching"
   - Use `@Default(\.appBehaviorSettings)` property wrapper
4. Test: Change settings → close app → reopen → settings persisted

**Files**: `Models/AppBehaviorSettings.swift`, `Core/DefaultsKeys.swift`, `Views/SettingsView.swift`

**Success criteria**:

- ✅ All three pickers and toggle display
- ✅ Changes save automatically to UserDefaults
- ✅ Settings persist across app restarts

---

### Step 7: Safari with Behavior Settings 🎯

**Goal**: Safari hotkey behavior changes based on global settings.

**What you'll build**:

- Action coordinator that reads behavior settings
- Safari behavior changes based on settings
- Window cycling for Safari (using Cmd+`)
- Hide app functionality (deferred - not implemented in Step 5)

**Tasks**:

1. Create `Protocols/WindowCyclingStrategy.swift`
2. Create `Implementations/SystemWindowCyclingStrategy.swift`:
   - Send Cmd+` via CGEvent
3. Create `Protocols/ActionCoordinator.swift`
4. Create `Implementations/DefaultActionCoordinator.swift`:
   - Inject `ApplicationManager` and `WindowCyclingStrategy`
   - `executeAction(for bundleIdentifier:, settings:)`:
     - Check if Safari is running and focused
     - Apply appropriate action based on settings
5. Register with Factory DI
6. Update hardcoded Safari hotkey in `AppDelegate`:
   - Read behavior settings from Defaults
   - Call `ActionCoordinator.executeAction()` instead of directly launching
7. Test all combinations:
   - Safari not running + "Launch app" → launches
   - Safari not running + "Do nothing" → nothing happens
   - Safari running but not focused + "Focus app" → focuses
   - Safari focused + "Cycle Windows" → cycles (if multiple windows)
   - Safari focused + "Hide app" → (deferred - implement hide() in ApplicationManager first)

**Files**: `Protocols/WindowCyclingStrategy.swift`, `Implementations/SystemWindowCyclingStrategy.swift`, `Protocols/ActionCoordinator.swift`, `Implementations/DefaultActionCoordinator.swift`, `AppDelegate.swift`

**Success criteria**:

- ✅ All behavior setting combinations work for Safari (except hide - deferred)
- ✅ Window cycling works with multiple Safari windows

---

### Step 8: Hotkey Bindings Settings UI 🎯

**Goal**: UI to configure which apps get which hotkeys.

**What you'll build**:

- Data model for hotkey bindings
- UI to add/edit/delete bindings
- Persistence via Defaults
- Application picker

**Tasks**:

1. Create `Models/HotkeyBinding.swift`:
   - `id`, `shortcutName`, `appBundleIdentifier`
   - Conform to `Codable`, `Identifiable`
2. Create `Models/ApplicationInfo.swift` (for picker)
3. Update `Core/DefaultsKeys.swift`: Add key for `hotkeyBindings` array
4. Create `Views/ApplicationPickerView.swift`:
   - Scan `/Applications` for installed apps
   - List with app icons and names
   - Search/filter
5. Create `Views/BindingEditorView.swift`:
   - Sheet with ApplicationPicker
   - `KeyboardShortcuts.Recorder` component
   - Save/Cancel buttons
   - Validate: no duplicate shortcuts
6. Create `Views/BindingListView.swift`:
   - List of bindings from `@Default(\.hotkeyBindings)`
   - Show app icon, name, shortcut
   - Add button (opens BindingEditorView)
   - Delete swipe action
7. Update `Views/SettingsView.swift`:
   - Add "Hotkeys" tab with BindingListView

**Files**: `Models/HotkeyBinding.swift`, `Models/ApplicationInfo.swift`, `Views/ApplicationPickerView.swift`, `Views/BindingEditorView.swift`, `Views/BindingListView.swift`, `Views/SettingsView.swift`

**Success criteria**:

- ✅ Can add new hotkey binding for any app
- ✅ Can delete bindings
- ✅ Bindings persist across app restarts
- ✅ Can't create duplicate shortcuts (validation works)

---

### Step 9: Generalize to All Configured Apps 🎯

**Goal**: All configured app bindings work, not just Safari.

**What you'll build**:

- Binding orchestrator that loads all bindings and registers hotkeys
- Dynamic hotkey registration for all configured apps
- Complete end-to-end flow

**Tasks**:

1. Create `Core/BindingOrchestrator.swift`:
   - Observe `@Default(\.hotkeyBindings)` and `@Default(\.appBehaviorSettings)`
   - On init: register all bindings with HotkeyManager
   - On binding added: register new hotkey
   - On binding removed: unregister hotkey
   - On hotkey triggered: call ActionCoordinator with current behavior settings
2. Initialize `BindingOrchestrator` in `AppDelegate.didFinishLaunching`
3. Remove hardcoded Safari hotkey code
4. Test complete flow:
   - Add binding for Chrome with Cmd+Shift+C
   - Add binding for Terminal with Cmd+Shift+T
   - Press each hotkey → respective app launches/focuses
   - Change behavior settings → all apps respect new settings
   - Delete binding → hotkey stops working
   - Restart app → all bindings still work

**Files**: `Core/BindingOrchestrator.swift`, `AppDelegate.swift`

**Success criteria**:

- ✅ Can configure hotkeys for any number of apps
- ✅ All hotkeys work simultaneously
- ✅ Behavior settings apply to all apps
- ✅ Adding/removing bindings updates hotkeys immediately
- ✅ Everything persists across app restarts

---

### Step 10: Polish & Edge Cases 🎯

**Goal**: Handle edge cases and improve UX.

**What you'll add**:

- Launch at login support
- App not installed detection
- Hotkey conflict warnings
- Notifications when launching apps
- Better error handling

**Tasks**:

1. Add "General" tab to settings with `LaunchAtLogin.Toggle`
2. In `ActionCoordinator`: Check `FileManager.fileExists()` before launching
3. Show system notification when app missing
4. In `BindingListView`: Gray out bindings for missing apps
5. In `BindingEditorView`: Check for duplicate shortcuts, show confirmation alert
6. Implement notification system for app launches (when enabled in behavior settings)
7. Add rate limiting for notifications
8. Test all edge cases

**Files**: Various existing files

**Success criteria**:

- ✅ Launch at login toggle works
- ✅ Missing apps are handled gracefully
- ✅ Duplicate shortcut warnings work
- ✅ Notifications show when enabled

---

### Step 11: Testing & Distribution 🎯

**Goal**: Prepare for release.

**Tasks**:

1. Create mock implementations for all protocols (for testing)
2. Write unit tests for ActionCoordinator behavior logic
3. Write integration test: add binding → restart app → verify hotkey works
4. Manual testing checklist
5. Code signing setup
6. Notarization
7. Create DMG
8. Write README

**Success criteria**: ✅ Ready to distribute

## Critical Files to Create/Modify

### Phase 1 Priority (Menu Bar + Settings Window)

1. **`/Users/bjornorri/Developer/Accio/Accio/AppDelegate.swift`**

   - NSStatusBar menu bar item
   - Menu with Settings and Quit actions
   - Bridges AppKit and SwiftUI

2. **`/Users/bjornorri/Developer/Accio/Accio/Core/WindowManager.swift`**

   - Manages settings window lifecycle (0 or 1 instance)
   - Dynamic activation policy for dock/app switcher behavior
   - Singleton pattern

3. **`/Users/bjornorri/Developer/Accio/Accio/Views/SettingsWindow.swift`**
   - NSWindow subclass for custom settings window
   - Hosts SwiftUI SettingsView

### Core Architecture Files

4. **`/Users/bjornorri/Developer/Accio/Accio/Core/BindingOrchestrator.swift`**

   - Central coordinator connecting all components
   - Loads bindings and behavior settings from Defaults
   - Registers hotkeys and coordinates actions
   - The "brain" of the application

5. **`/Users/bjornorri/Developer/Accio/Accio/Core/DependencyContainer.swift`**

   - Factory DI container
   - Registers all protocol implementations
   - Supports mock registrations for testing

6. **`/Users/bjornorri/Developer/Accio/Accio/Implementations/DefaultActionCoordinator.swift`**
   - Executes hotkey actions based on app state and global behavior settings
   - Coordinates ApplicationManager and WindowCyclingStrategy
   - Decision logic for whenNotRunning/whenNotFocused/whenFocused

### UI Files

7. **`/Users/bjornorri/Developer/Accio/Accio/Views/SettingsView.swift`**

   - Main settings interface with tabs
   - Permission status, bindings list, behavior settings, general preferences
   - Uses @Default and @Injected property wrappers

8. **`/Users/bjornorri/Developer/Accio/Accio/Views/BindingEditorView.swift`**
   - Add/edit hotkey binding interface
   - ApplicationPicker + KeyboardShortcuts.Recorder
   - Conflict validation

## File Structure

```
Accio/
├── Accio/
│   ├── AccioApp.swift (modified: uses AppDelegate)
│   ├── AppDelegate.swift (new: menu bar + app lifecycle)
│   ├── Accio.entitlements (new: sandbox disabled)
│   │
│   ├── Models/
│   │   ├── HotkeyBinding.swift (simplified: id, shortcutName, appBundleIdentifier)
│   │   ├── ApplicationInfo.swift
│   │   ├── AppBehaviorSettings.swift (with enums for each state)
│   │   └── AppPreferences.swift
│   │
│   ├── Protocols/
│   │   ├── HotkeyManager.swift
│   │   ├── ApplicationManager.swift
│   │   ├── WindowCyclingStrategy.swift (replaceable implementation)
│   │   ├── AccessibilityPermissionManager.swift
│   │   └── ActionCoordinator.swift
│   │
│   ├── Implementations/
│   │   ├── KeyboardShortcutsHotkeyManager.swift
│   │   ├── NSWorkspaceApplicationManager.swift
│   │   ├── SystemWindowCyclingStrategy.swift (sends Cmd+`)
│   │   ├── AXAccessibilityPermissionManager.swift
│   │   └── DefaultActionCoordinator.swift (behavior settings logic)
│   │
│   ├── Core/
│   │   ├── DependencyContainer.swift (Factory DI)
│   │   ├── WindowManager.swift (settings window lifecycle)
│   │   ├── BindingOrchestrator.swift (central coordinator)
│   │   ├── DefaultsKeys.swift (Defaults library keys)
│   │   └── Errors.swift
│   │
│   ├── Views/
│   │   ├── SettingsWindow.swift (NSWindow subclass)
│   │   ├── SettingsView.swift (SwiftUI with tabs)
│   │   ├── BindingListView.swift
│   │   ├── BindingEditorView.swift
│   │   └── ApplicationPickerView.swift
│   │
│   └── Assets.xcassets/
│
├── AccioTests/
│   ├── Mocks/
│   │   ├── MockHotkeyManager.swift
│   │   ├── MockApplicationManager.swift
│   │   ├── MockWindowCyclingStrategy.swift
│   │   └── MockPermissionManager.swift
│   ├── UnitTests/
│   │   ├── ActionCoordinatorTests.swift
│   │   ├── BindingOrchestratorTests.swift
│   │   └── ModelTests.swift
│   └── IntegrationTests/
│       └── EndToEndTests.swift
│
└── AccioUITests/
    └── SettingsUITests.swift
```

## Key Edge Cases to Handle

1. **App Not Installed**: Check `FileManager.fileExists()` before executing, show notification, gray out in UI
2. **Hotkey Conflicts**: Validate before saving, warn user about internal conflicts, KeyboardShortcuts handles system conflicts
3. **App State Transitions**: Handle all combinations of whenNotRunning/whenNotFocused/whenFocused smoothly
4. **Permission Revoked**: Monitor continuously (1s polling), show warning, disable execution gracefully
5. **Settings Persistence**: Defaults library handles automatically, add version flag for future migrations
6. **Notification Rate Limiting**: Don't spam user with launch notifications
7. **Window Cycling Edge Cases**: Single window, no windows, app has multiple spaces

## Testing Strategy

### Factory Testing Setup

Tests use Factory's recommended pattern with `FactoryTesting`:

```swift
import Testing
import Clocks
import FactoryKit
import FactoryTesting
@testable import Accio

@Suite(.container)  // Isolates each test with fresh container
struct MyTests {
    @Test func example() async {
        // Register mocks
        Container.shared.someService.register { MockService() }

        // Get instance via container
        let sut = Container.shared.myComponent()

        // Test...
    }
}
```

**Key imports:**
- `FactoryKit` - provides `Container` type
- `FactoryTesting` - provides `.container` trait for test isolation
- `Clocks` - provides `TestClock` for time-based testing

**Test isolation:** The `@Suite(.container)` trait automatically resets the container for each test, enabling parallel test execution.

### Time-Based Testing

For components using `Task.sleep` or timers, inject `Clock` via Factory:

```swift
// DependencyContainer.swift
var clock: Factory<any Clock<Duration>> {
    self { ContinuousClock() }
        .singleton
}

// In tests
let clock = TestClock()
Container.shared.clock.register { clock }

// Advance time without waiting
await clock.advance(by: .seconds(1))
```

### Test Types

- **Unit Tests**: Factory DI supports test registrations; mock all protocols
- **Integration Tests**: End-to-end flows with behavior settings
- **Manual Tests**: Hotkey triggering, dock/app switcher behavior, permission flow
- **Mock Data**: Use Factory test containers with mock implementations

## Implementation Priority Summary

**🎯 PRIORITY 1 (Phase 1)**: Menu Bar + Settings Window Foundation

- Get the UI shell working first
- Dynamic dock/app switcher behavior
- Single settings window instance management

**🎯 PRIORITY 2 (Phase 2)**: Accessibility Permissions UI

- Permission status indicator in settings
- Real-time permission monitoring
- Guided permission flow

**Phases 3-7**: Core functionality (models, managers, hotkeys, complete UI)

**Phases 8-10**: Polish, testing, distribution

## Summary of Changes from Original Plan

✅ **Factory DI** instead of custom AppDependencies class
✅ **Defaults library** for type-safe settings persistence
✅ **LaunchAtLogin-Modern** for launch at login functionality
✅ **Simplified data model**: Global behavior settings instead of per-binding actions
✅ **System Cmd+` for window cycling** with replaceable protocol
✅ **Reorganized priorities**: Menu bar + settings window first, then permissions
✅ **Custom settings window** with dynamic dock behavior (no native Settings scene)
✅ **Dedicated third-party libraries section** with clear purposes
