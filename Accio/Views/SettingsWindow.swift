//
//  SettingsWindow.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import AppKit
import SwiftUI

/// Custom settings window that hosts the SwiftUI SettingsView
class SettingsWindow: NSWindow {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        // Configure window
        self.title = "Accio Settings"

        // Host SwiftUI view
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        self.contentViewController = hostingController

        // Set content size (this sizes the content area, excluding title bar)
        self.setContentSize(NSSize(width: 600, height: 450))
        self.center() // Center on screen

        // Make window key and order front on creation
        self.isReleasedWhenClosed = false // Keep window instance alive when closed
    }

    /// Override Cmd+Q to close window instead of quitting app
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Check if this is Cmd+Q
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "q" {
            // Just close the window, don't quit the app
            self.close()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
