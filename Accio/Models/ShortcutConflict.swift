//
//  ShortcutConflict.swift
//  Accio
//

import KeyboardShortcuts

/// Represents a conflict where two items have the same shortcut
struct ShortcutConflict {
    /// An item that can hold a shortcut — either a binding or a group
    enum Item {
        case binding(HotkeyBinding)
        case group(AppGroup)

        var shortcutName: String {
            switch self {
            case .binding(let b): return b.shortcutName
            case .group(let g): return g.shortcutName
            }
        }

        var displayName: String {
            switch self {
            case .binding(let b): return b.appName
            case .group(let g): return g.name
            }
        }
    }

    /// The item that was just edited
    let editedItem: Item
    /// The item that already has this shortcut
    let conflictingItem: Item
    /// The conflicting shortcut
    let shortcut: KeyboardShortcuts.Shortcut
}
