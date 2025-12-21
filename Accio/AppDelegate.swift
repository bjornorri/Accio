//
//  AppDelegate.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import AppKit
import Defaults
import FactoryKit
import KeyboardShortcuts
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    // Inject dependencies via Factory
    @Injected(\.windowManager) private var windowManager: WindowManager
    @Injected(\.permissionProvider) private var permissionProvider: AccessibilityPermissionProvider
    @Injected(\.hotkeyManager) private var hotkeyManager: HotkeyManager
    @Injected(\.actionCoordinator) private var actionCoordinator: ActionCoordinator

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set initial activation policy to accessory (hidden from dock/switcher)
        NSApp.setActivationPolicy(.accessory)

        // Create menu bar item
        setupMenuBar()

        // Register hardcoded Safari hotkey (Cmd+Shift+S)
        registerSafariHotkey()

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

    private func registerSafariHotkey() {
        hotkeyManager.register(name: KeyboardShortcuts.Name.safari.rawValue) { [weak self] in
            guard let self = self else { return }
            await self.handleSafariHotkey()
        }
    }

    private func handleSafariHotkey() async {
        let settings = Defaults[.appBehaviorSettings]
        await actionCoordinator.executeAction(for: "com.apple.Safari", settings: settings)
    }

    @objc private func openSettings() {
        windowManager.showSettings()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

