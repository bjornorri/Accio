//
//  AppDelegate.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import AppKit
import FactoryKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var bindingOrchestrator: BindingOrchestrator?

    // Inject dependencies via Factory
    @Injected(\.windowManager) private var windowManager: WindowManager
    @Injected(\.permissionProvider) private var permissionProvider: AccessibilityPermissionProvider

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set initial activation policy to accessory (hidden from dock/switcher)
        NSApp.setActivationPolicy(.accessory)

        // Create menu bar item
        setupMenuBar()

        // Initialize the binding orchestrator (manages all hotkey bindings)
        bindingOrchestrator = BindingOrchestrator()

        // Check accessibility permission and open settings if not granted
        if !permissionProvider.hasPermission {
            openSettings()
        }

        #if DEBUG
        // Always open settings window on launch in debug builds
        openSettings()
        #endif
    }

    private func setupMenuBar() {
        // Create status bar item with icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "wand.and.stars", accessibilityDescription: "Accio")
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
}

