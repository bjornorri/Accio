//
//  DefaultWindowManager.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import AppKit
import SwiftUI

/// Manages the settings window lifecycle with dynamic dock/app switcher behavior
final class DefaultWindowManager: WindowManager {
    private var settingsWindow: SettingsWindow?

    init() {
        // Set up notification observer for window close
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Shows the settings window, creating it if needed
    /// Makes the app appear in dock and Cmd+Tab switcher
    func showSettings() {
        if settingsWindow == nil {
            // Create new settings window
            settingsWindow = SettingsWindow()
        }

        // Set activation policy to regular (shows in dock and app switcher)
        NSApp.setActivationPolicy(.regular)

        // Activate app and bring window to front
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func windowWillClose(_ notification: Notification) {
        // Check if the closing window is our settings window
        guard let window = notification.object as? NSWindow,
              window === settingsWindow else {
            return
        }

        // Set activation policy back to accessory (hides from dock and app switcher)
        NSApp.setActivationPolicy(.accessory)
    }
}
