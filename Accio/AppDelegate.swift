//
//  AppDelegate.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import AppKit
import FactoryKit
import SwiftUI

extension Notification.Name {
    static let performFind = Notification.Name("performFind")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    // Inject dependencies via Factory
    @Injected(\.windowManager) private var windowManager: WindowManager
    @Injected(\.bindingOrchestrator) private var bindingOrchestrator: BindingOrchestrator

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set initial activation policy to accessory (hidden from dock/switcher)
        NSApp.setActivationPolicy(.accessory)

        // Create menu bar item
        setupMenuBar()

        // Start the binding orchestrator (manages all hotkey bindings)
        bindingOrchestrator.start()

        #if DEBUG
        // Always open settings window on launch in debug builds
        openSettings()
        #endif
    }

    private func setupMenuBar() {
        // Create status bar item with icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            let image = NSImage(resource: .menuBarIcon)
            image.size = NSSize(width: 22, height: 22)
            button.image = image
        }

        // Create menu
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Accio", action: #selector(quit), keyEquivalent: ""))

        statusItem?.menu = menu
    }

    @objc private func openSettings() {
        windowManager.showSettings()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    // Called when user tries to launch the app again while it's already running
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return false
    }

}

