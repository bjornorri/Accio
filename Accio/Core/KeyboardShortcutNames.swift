//
//  KeyboardShortcutNames.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 16.12.2025.
//

import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    // Hardcoded Safari hotkey (Cmd+Shift+S)
    static let safari = Self("safari", default: .init(.s, modifiers: [.command, .shift]))
}
