//
//  HotkeyBinding.swift
//  Accio
//

import Defaults
import Foundation

/// A hotkey binding that maps a keyboard shortcut to an application
struct HotkeyBinding: Codable, Identifiable, Defaults.Serializable, Equatable {
    /// Unique identifier for this binding
    let id: UUID

    /// Name used for KeyboardShortcuts registration (maps to KeyboardShortcuts.Name)
    let shortcutName: String

    /// Bundle identifier of the target application
    let appBundleIdentifier: String

    init(id: UUID = UUID(), shortcutName: String, appBundleIdentifier: String) {
        self.id = id
        self.shortcutName = shortcutName
        self.appBundleIdentifier = appBundleIdentifier
    }
}
