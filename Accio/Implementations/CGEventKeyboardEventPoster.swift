//
//  CGEventKeyboardEventPoster.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import CoreGraphics

/// Posts keyboard events using CGEvent
final class CGEventKeyboardEventPoster: KeyboardEventPoster {

    enum KeyboardEventPosterError: Error {
        case failedToCreateEvent
    }

    func postKeyPress(keyCode: CGKeyCode, modifiers: CGEventFlags) throws {
        // Create key down event
        guard let keyDown = CGEvent(
            keyboardEventSource: nil,
            virtualKey: keyCode,
            keyDown: true
        ) else {
            throw KeyboardEventPosterError.failedToCreateEvent
        }

        // Create key up event
        guard let keyUp = CGEvent(
            keyboardEventSource: nil,
            virtualKey: keyCode,
            keyDown: false
        ) else {
            throw KeyboardEventPosterError.failedToCreateEvent
        }

        // Set modifier flags
        keyDown.flags = modifiers
        keyUp.flags = modifiers

        // Post events to the system
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
