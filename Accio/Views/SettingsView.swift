//
//  SettingsView.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import SwiftUI
import Combine
import FactoryKit

/// Settings view with accessibility permissions and app preferences
struct SettingsView: View {
    @Injected(\.permissionManager) private var permissionManager

    @State private var accessibilityPermissionGranted = false
    @State private var timerCancellable: AnyCancellable?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Accessibility Permission Section
            GroupBox(label: Text("Permissions").font(.headline)) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: accessibilityPermissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(accessibilityPermissionGranted ? .green : .red)

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
                        permissionManager.requestPermission()
                    }
                    .opacity(accessibilityPermissionGranted ? 0 : 1)
                    .disabled(accessibilityPermissionGranted)
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
            accessibilityPermissionGranted = permissionManager.hasPermission
        }
        .onDisappear {
            stopTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            stopTimer()
            accessibilityPermissionGranted = permissionManager.hasPermission
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            startTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            accessibilityPermissionGranted = permissionManager.hasPermission
        }
    }

    private func startTimer() {
        guard timerCancellable == nil else { return }

        timerCancellable = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                accessibilityPermissionGranted = permissionManager.hasPermission
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

#Preview {
    SettingsView()
}
