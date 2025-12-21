//
//  KeyboardEventPoster.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import CoreGraphics

/// Posts keyboard events to the system
protocol KeyboardEventPoster {
    /// Post a key press (key down + key up) with the specified modifiers
    /// - Parameters:
    ///   - keyCode: The virtual key code to press
    ///   - modifiers: The modifier flags (Command, Shift, etc.)
    /// - Throws: Error if the event cannot be created or posted
    func postKeyPress(keyCode: CGKeyCode, modifiers: CGEventFlags) throws
}
