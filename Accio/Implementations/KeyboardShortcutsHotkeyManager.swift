//
//  KeyboardShortcutsHotkeyManager.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 16.12.2025.
//

import Foundation
import KeyboardShortcuts

/// KeyboardShortcuts-based implementation of HotkeyManager
final class KeyboardShortcutsHotkeyManager: HotkeyManager {
    func register(name: String, handler: @escaping () async -> Void) {
        // Convert the string name to a KeyboardShortcuts.Name
        let shortcutName = KeyboardShortcuts.Name(name)

        // Register the handler with KeyboardShortcuts
        // KeyboardShortcuts expects a synchronous closure, so we wrap the async call in a Task
        KeyboardShortcuts.onKeyDown(for: shortcutName) {
            Task {
                await handler()
            }
        }
    }

    func unregister(name: String) {
        // Remove the handler from the KeyboardShortcuts library
        // This removes the entire closure we registered, including the captured handler
        let shortcutName = KeyboardShortcuts.Name(name)
        KeyboardShortcuts.removeHandler(for: shortcutName)
    }

    func unregisterAll() {
        // Remove all handlers from the KeyboardShortcuts library
        KeyboardShortcuts.removeAllHandlers()
    }
}
