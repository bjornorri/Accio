//
//  ShortcutConflict.swift
//  Accio
//

import KeyboardShortcuts

/// Represents a conflict where two bindings have the same shortcut
struct ShortcutConflict {
    /// The binding that was just edited
    let editedBinding: HotkeyBinding
    /// The binding that already has this shortcut
    let conflictingBinding: HotkeyBinding
    /// The conflicting shortcut
    let shortcut: KeyboardShortcuts.Shortcut
}
