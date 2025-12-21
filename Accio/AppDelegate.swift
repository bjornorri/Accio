//
//  AppDelegate.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import AppKit
import SwiftUI
import FactoryKit
import KeyboardShortcuts

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    // Inject dependencies via Factory
    @Injected(\.windowManager) private var windowManager: WindowManager
    @Injected(\.permissionProvider) private var permissionProvider: AccessibilityPermissionProvider
    @Injected(\.hotkeyManager) private var hotkeyManager: HotkeyManager
    @Injected(\.applicationManager) private var applicationManager: ApplicationManager

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
        let safariBundle = "com.apple.Safari"

        do {
            if !applicationManager.isRunning(bundleIdentifier: safariBundle) {
                // Safari is not running, launch it
                try await applicationManager.launch(bundleIdentifier: safariBundle)
            }

            if !applicationManager.isFocused(bundleIdentifier: safariBundle) {
                // Safari is running but not focused, activate it
                try applicationManager.activate(bundleIdentifier: safariBundle)
            }
        } catch {
            print("Error handling Safari hotkey: \(error)")
        }
    }

    @objc private func openSettings() {
        windowManager.showSettings()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

