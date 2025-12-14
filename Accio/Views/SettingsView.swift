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
    @Injected(\.permissionManager) private var permissionManager
    @StateObject private var observablePermissionManager = Container.shared.permissionManager() as! ObservableAccessibilityPermissionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Accessibility Permission Section
            GroupBox(label: Text("Permissions").font(.headline)) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: observablePermissionManager.hasPermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(observablePermissionManager.hasPermission ? .green : .red)

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
                        observablePermissionManager.requestPermission()
                    }
                    .opacity(observablePermissionManager.hasPermission ? 0 : 1)
                    .disabled(observablePermissionManager.hasPermission)
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
            // Check permission when view appears
            observablePermissionManager.checkPermission()
        }
        .onDisappear {
            // Stop monitoring when view disappears (window closed)
            observablePermissionManager.stopMonitoring()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            // Stop monitoring and check permission when window gains focus
            observablePermissionManager.stopMonitoring()
            observablePermissionManager.checkPermission()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            // Start monitoring when window loses focus (user might be in System Settings)
            observablePermissionManager.startMonitoring()
        }
    }
}

#Preview {
    SettingsView()
}
