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
    fileprivate enum Tab: CaseIterable {
        case general
        case shortcuts
    }

    @State private var selectedTab: Tab = .general

    fileprivate static let allTabs = Tab.allCases

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tab.general)

            BindingListView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
                .tag(Tab.shortcuts)
        }
        .frame(minWidth: 500, minHeight: 450)
        .modifier(TabNavigationShortcutsModifier(selectedTab: $selectedTab))
    }
}

/// Modifier that adds Cmd+1/2/... and Cmd+Shift+{/} keyboard shortcuts for tab navigation
private struct TabNavigationShortcutsModifier: ViewModifier {
    @Binding var selectedTab: SettingsView.Tab
    @State private var monitor: Any?

    private var tabs: [SettingsView.Tab] { SettingsView.allTabs }

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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Accessibility Permission Section
                GroupBox(label: Text("Permissions").font(.headline)) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: hasPermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(hasPermission ? .green : .red)

                                Text("Accessibility Access")
                            }

                            Text("Required for global hotkeys and app control")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Button("Grant Permission") {
                            permissionMonitor.requestPermission()
                        }
                        .opacity(hasPermission ? 0 : 1)
                        .disabled(hasPermission)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                }

                // Behavior Settings Section
                GroupBox(label: Text("Behavior").font(.headline)) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Launch at login
                        VStack(alignment: .leading, spacing: 4) {
                            LaunchAtLogin.Toggle {
                                Text("Launch at login")
                            }
                            .toggleStyle(.checkbox)
                            .id(launchAtLoginRefreshTrigger)

                            Text("Automatically start Accio when you log in")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 12)

                        Divider()

                        // Show notifications
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Show notifications", isOn: $behaviorSettings.showNotificationWhenLaunching)
                                .toggleStyle(.checkbox)

                            Text("Display a notification when launching apps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 12)

                        Divider()

                        // When app is not running
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("When app is not running")
                                Text("Action to take when the target app is not running")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Picker("", selection: $behaviorSettings.whenNotRunning) {
                                ForEach(NotRunningAction.allCases, id: \.self) { action in
                                    Text(action.displayName).tag(action)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 150)
                            .fixedSize()
                        }
                        .padding(.vertical, 12)

                        Divider()

                        // When app is running but not focused
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("When app is not focused")
                                Text("Action to take when the target app is running but not focused")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Picker("", selection: $behaviorSettings.whenNotFocused) {
                                ForEach(NotFocusedAction.allCases, id: \.self) { action in
                                    Text(action.displayName).tag(action)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 150)
                            .fixedSize()
                        }
                        .padding(.vertical, 12)

                        Divider()

                        // When app is already focused
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("When app is focused")
                                Text("Action to take when the target app is already focused")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Picker("", selection: $behaviorSettings.whenFocused) {
                                ForEach(FocusedAction.allCases, id: \.self) { action in
                                    Text(action.displayName).tag(action)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 150)
                            .fixedSize()
                        }
                        .padding(.vertical, 12)
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
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
