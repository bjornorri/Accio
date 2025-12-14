//
//  ObservableAccessibilityPermissionManager.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import ApplicationServices
import Foundation
import Combine

/// Observable accessibility permission manager with on-demand monitoring
class ObservableAccessibilityPermissionManager: AccessibilityPermissionManager, ObservableObject {
    @Published private(set) var hasPermission: Bool = false
    private var monitoringTask: Task<Void, Never>?

    init() {
        hasPermission = AXIsProcessTrusted()
    }

    /// Start monitoring permission status (call when settings window loses focus)
    func startMonitoring() {
        // Don't start if already monitoring
        guard monitoringTask == nil else { return }

        monitoringTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                print("Checking permission!")
                let currentStatus = AXIsProcessTrusted()
                if currentStatus != hasPermission {
                    hasPermission = currentStatus
                }
            }
        }
    }

    /// Stop monitoring permission status (call when settings window closes or gains focus)
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    /// Check permission status immediately (call when window gains focus)
    func checkPermission() {
        hasPermission = AXIsProcessTrusted()
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        // Check immediately after request
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            hasPermission = AXIsProcessTrusted()
        }
    }

    deinit {
        stopMonitoring()
    }
}
