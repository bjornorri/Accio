//
//  KeyboardShortcut.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import Carbon
import Foundation

/// Represents a keyboard shortcut with key code and modifier flags
struct KeyboardShortcut {
    let keyCode: CGKeyCode
    let modifiers: CGEventFlags

    /// Default Cmd+` shortcut (backtick key)
    static let commandBacktick = KeyboardShortcut(
        keyCode: CGKeyCode(kVK_ANSI_Grave),
        modifiers: .maskCommand
    )
}
