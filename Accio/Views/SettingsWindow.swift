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
        // Create window with fixed size
        let windowSize = NSSize(width: 600, height: 400)
        let windowRect = NSRect(origin: .zero, size: windowSize)

        super.init(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        // Configure window
        self.title = "Accio Settings"
        self.center() // Center on screen

        // Host SwiftUI view
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        self.contentView = hostingController.view

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
