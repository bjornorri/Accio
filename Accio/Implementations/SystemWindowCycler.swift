//
//  SystemWindowCycler.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import CoreGraphics
import FactoryKit
import Foundation

/// Window cycler that triggers the system's window cycling shortcut
class SystemWindowCycler: WindowCycler {
    @Injected(\.systemShortcutReader) private var shortcutReader: SystemShortcutReader

    func cycleWindows(for bundleIdentifier: String) throws {
        let shortcut = shortcutReader.readWindowCyclingShortcut()

        // Create key down event
        guard let keyDown = CGEvent(
            keyboardEventSource: nil,
            virtualKey: shortcut.keyCode,
            keyDown: true
        ) else {
            throw WindowCyclerError.failedToCreateEvent
        }

        // Create key up event
        guard let keyUp = CGEvent(
            keyboardEventSource: nil,
            virtualKey: shortcut.keyCode,
            keyDown: false
        ) else {
            throw WindowCyclerError.failedToCreateEvent
        }

        // Set modifier flags
        keyDown.flags = shortcut.modifiers
        keyUp.flags = shortcut.modifiers

        // Post events to the system
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

enum WindowCyclerError: Error {
    case failedToCreateEvent
}
