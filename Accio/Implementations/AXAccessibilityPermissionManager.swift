//
//  AXAccessibilityPermissionManager.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import ApplicationServices
import Foundation

/// Accessibility permission manager using the AX (Accessibility) API
class AXAccessibilityPermissionManager: AccessibilityPermissionManager {
    var hasPermission: Bool {
        AXIsProcessTrusted()
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
