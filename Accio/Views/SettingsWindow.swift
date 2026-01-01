//
//  SettingsWindow.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import AppKit
import SwiftUI

extension NSWindow {
    /// Checks if the first responder is an NSTableView or a view within one
    var isTableViewFocused: Bool {
        guard let firstResponder = firstResponder else { return false }
        if firstResponder is NSTableView { return true }
        if let view = firstResponder as? NSView {
            var superview = view.superview
            while let current = superview {
                if current is NSTableView { return true }
                superview = current.superview
            }
        }
        return false
    }
}

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

        // Set content size and constraints
        self.setContentSize(NSSize(width: 600, height: 500))
        self.contentMinSize = NSSize(width: 600, height: 500)
        self.center() // Center on screen

        // Make window key and order front on creation
        self.isReleasedWhenClosed = false // Keep window instance alive when closed
        self.isRestorable = false // Disable window restoration
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Cmd+Q: Close window instead of quitting app
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "q" {
            self.close()
            return true
        }

        // Return/Enter: Consume when table view is focused to prevent system beep
        let isReturnOrEnter = event.keyCode == 36 || event.keyCode == 76
        let hasNoActionModifiers = event.modifierFlags.intersection([.command, .control, .option]).isEmpty
        if isReturnOrEnter && hasNoActionModifiers && isTableViewFocused {
            return true
        }

        return super.performKeyEquivalent(with: event)
    }
}
