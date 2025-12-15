//
//  AccessibilityPermissionManager.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import Foundation

/// Protocol for managing accessibility permissions
protocol AccessibilityPermissionProvider {
    /// Check if the app has accessibility permission
    var hasPermission: Bool { get }

    /// Request accessibility permission from the user
    func requestPermission()
}
