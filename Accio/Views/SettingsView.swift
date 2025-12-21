//
//  SettingsView.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import SwiftUI
import FactoryKit
import Defaults
import LaunchAtLogin

/// Settings view with accessibility permissions and app preferences
struct SettingsView: View {
    @Injected(\.permissionMonitor) private var permissionMonitor: AccessibilityPermissionMonitor
    @State private var hasPermission: Bool = false
    @State private var launchAtLoginRefreshTrigger = false

    // Behavior settings using Defaults
    @Default(.appBehaviorSettings) private var behaviorSettings

    var body: some View {
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
