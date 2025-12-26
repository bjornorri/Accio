//
//  SettingsView.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import Defaults
import FactoryKit
import LaunchAtLogin
import SwiftUI

/// Main settings view with tabs for General and Shortcuts settings
struct SettingsView: View {
    fileprivate enum SettingsTab: CaseIterable {
        case general
        case shortcuts
    }

    @State private var selectedTab: SettingsTab = .general

    fileprivate static let allTabs = SettingsTab.allCases

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("General", systemImage: "gear", value: .general) {
                GeneralSettingsView()
            }
            Tab("Shortcuts", systemImage: "keyboard", value: .shortcuts) {
                BindingListView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .frame(minWidth: 600, minHeight: 500)
        .modifier(TabNavigationShortcutsModifier(selectedTab: $selectedTab))
    }
}

/// Modifier that adds Cmd+1/2/... and Cmd+Shift+{/} keyboard shortcuts for tab navigation
private struct TabNavigationShortcutsModifier: ViewModifier {
    @Binding var selectedTab: SettingsView.SettingsTab
    @State private var monitor: Any?

    private var tabs: [SettingsView.SettingsTab] { SettingsView.allTabs }

    func body(content: Content) -> some View {
        content
            .onAppear {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    // Only handle when settings window is key
                    guard let window = event.window,
                          window.isKeyWindow,
                          event.modifierFlags.contains(.command),
                          let characters = event.charactersIgnoringModifiers else {
                        return event
                    }

                    let hasShift = event.modifierFlags.contains(.shift)
                    let hasOption = event.modifierFlags.contains(.option)

                    // Cmd+1, Cmd+2, etc. (no shift, no option)
                    if !hasShift && !hasOption, let number = Int(characters) {
                        let index = number - 1 // Cmd+1 = index 0, Cmd+2 = index 1, etc.
                        if tabs.indices.contains(index) {
                            selectedTab = tabs[index]
                            return nil
                        }
                    }

                    // Cmd+Shift+{ / Cmd+Shift+} (shift, no option) - with wrap around
                    if hasShift && !hasOption {
                        guard let currentIndex = tabs.firstIndex(of: selectedTab) else {
                            return event
                        }

                        switch characters {
                        case "{":
                            let newIndex = currentIndex == tabs.startIndex
                                ? tabs.index(before: tabs.endIndex)
                                : tabs.index(before: currentIndex)
                            selectedTab = tabs[newIndex]
                            return nil
                        case "}":
                            let newIndex = tabs.index(after: currentIndex)
                            selectedTab = newIndex == tabs.endIndex ? tabs[tabs.startIndex] : tabs[newIndex]
                            return nil
                        default:
                            break
                        }
                    }

                    return event
                }
            }
            .onDisappear {
                if let monitor = monitor {
                    NSEvent.removeMonitor(monitor)
                }
            }
    }
}

/// General settings including permissions, behavior, and preferences
struct GeneralSettingsView: View {
    @Injected(\.permissionMonitor) private var permissionMonitor: AccessibilityPermissionMonitor
    @State private var hasPermission: Bool = false
    @State private var launchAtLoginRefreshTrigger = false

    // Behavior settings using Defaults
    @Default(.appBehaviorSettings) private var behaviorSettings

    var body: some View {
        Form {
            Section("Permissions") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: hasPermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(hasPermission ? .green : .red)
                            Text("Accessibility Access")
                        }
                        Text("Required for global hotkeys and app control")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Grant Permission") {
                        permissionMonitor.requestPermission()
                    }
                    .opacity(hasPermission ? 0 : 1)
                    .disabled(hasPermission)
                }
            }

            Section("Startup") {
                LaunchAtLogin.Toggle {
                    Text("Launch at login")
                }
                .toggleStyle(.checkbox)
                .id(launchAtLoginRefreshTrigger)
            }

            Section {
                Picker("When app is not running", selection: $behaviorSettings.whenNotRunning) {
                    ForEach(NotRunningAction.allCases, id: \.self) { action in
                        Text(action.displayName).tag(action)
                    }
                }

                Picker("When app is not focused", selection: $behaviorSettings.whenNotFocused) {
                    ForEach(NotFocusedAction.allCases, id: \.self) { action in
                        Text(action.displayName).tag(action)
                    }
                }

                Picker("When app is focused", selection: $behaviorSettings.whenFocused) {
                    ForEach(FocusedAction.allCases, id: \.self) { action in
                        Text(action.displayName).tag(action)
                    }
                }
            } header: {
                Text("Behavior")
            } footer: {
                Text("Choose what happens when you trigger a shortcut")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            // Register callback and check permission
            permissionMonitor.onPermissionChange { newValue in
                hasPermission = newValue
            }
            permissionMonitor.checkPermission()

            // Refresh launch at login state
            launchAtLoginRefreshTrigger.toggle()
        }
        .onDisappear {
            // Stop monitoring when view disappears (window closed)
            permissionMonitor.stopMonitoring()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            // Stop monitoring and check permission when window gains focus
            permissionMonitor.stopMonitoring()
            permissionMonitor.checkPermission()

            // Refresh launch at login state
            launchAtLoginRefreshTrigger.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            // Start monitoring when window loses focus (user might be in System Settings)
            permissionMonitor.startMonitoring()
        }
    }
}

#Preview {
    SettingsView()
}
