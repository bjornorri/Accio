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
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Configure window with unified toolbar for sidebar integration
        self.title = "Accio Settings"
        self.titlebarAppearsTransparent = false
        self.titleVisibility = .visible
        self.toolbarStyle = .automatic

        // Host SwiftUI view
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        self.contentViewController = hostingController

        // Set content size (this sizes the content area, excluding title bar)
        self.setContentSize(NSSize(width: 600, height: 500))
        self.center() // Center on screen

        // Make window key and order front on creation
        self.isReleasedWhenClosed = false // Keep window instance alive when closed
        self.isRestorable = false // Disable window restoration
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
