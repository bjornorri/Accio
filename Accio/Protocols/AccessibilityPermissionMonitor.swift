//
//  AccessibilityPermissionMonitor.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import Foundation

/// Protocol for managing accessibility permissions
protocol AccessibilityPermissionMonitor {
    /// Check if the app has accessibility permission
    var hasPermission: Bool { get }

    /// Register callback to be notified of permission changes
    /// - Parameter onChange: Closure called when permission status changes
    func onPermissionChange(_ onChange: @escaping (Bool) -> Void)

    /// Request accessibility permission from the user
    func requestPermission()

    /// Check permission status immediately (call when window gains focus)
    func checkPermission()

    /// Start monitoring permission status
    func startMonitoring()

    /// Stop monitoring permission status
    func stopMonitoring()
}
