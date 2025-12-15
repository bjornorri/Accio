//
//  ObservableAccessibilityPermissionManager.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import FactoryKit
import Foundation

/// Observable accessibility permission manager with on-demand monitoring
class DefaultAccessibilityPermissionMonitor: AccessibilityPermissionMonitor {

    @Injected(\.permissionProvider) private var permissionProvider
    private var _hasPermission: Bool = false
    private var onChange: ((Bool) -> Void)?
    private var monitoringTask: Task<Void, Never>?

    var hasPermission: Bool {
        _hasPermission
    }

    init() {
        _hasPermission = permissionProvider.hasPermission
    }

    /// Register callback to be notified of permission changes
    func onPermissionChange(_ onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange
        // Immediately call with current value
        onChange(_hasPermission)
    }

    private func updatePermission(_ newValue: Bool) {
        guard _hasPermission != newValue else { return }
        _hasPermission = newValue
        onChange?(newValue)
    }

    /// Start monitoring permission status (call when settings window loses focus)
    func startMonitoring() {
        // Don't start if already monitoring
        guard monitoringTask == nil else { return }

        monitoringTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                print("Checking permission!")
                let currentStatus = permissionProvider.hasPermission
                updatePermission(currentStatus)
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
        updatePermission(permissionProvider.hasPermission)
    }

    func requestPermission() {
        permissionProvider.requestPermission()
        // Check immediately after request
        Task { @MainActor in
            updatePermission(permissionProvider.hasPermission)
        }
    }

    deinit {
        stopMonitoring()
    }
}
