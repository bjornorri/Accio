//
//  SettingsView.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import SwiftUI
import FactoryKit

/// Settings view with accessibility permissions and app preferences
struct SettingsView: View {
    @Injected(\.permissionMonitor) private var permissionMonitor: AccessibilityPermissionMonitor
    @State private var hasPermission: Bool = false

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

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            // Register callback and check permission
            permissionMonitor.onPermissionChange { newValue in
                hasPermission = newValue
            }
            permissionMonitor.checkPermission()
        }
        .onDisappear {
            // Stop monitoring when view disappears (window closed)
            permissionMonitor.stopMonitoring()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            // Stop monitoring and check permission when window gains focus
            permissionMonitor.stopMonitoring()
            permissionMonitor.checkPermission()
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
