//
//  DefaultsKeys.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import Defaults

/// Current settings schema version. Increment when making breaking changes to settings structure.
let currentSettingsSchemaVersion = 1

// MARK: - Defaults Keys

extension Defaults.Keys {
    /// Settings schema version for migrations
    static let settingsSchemaVersion = Key<Int>(
        "settingsSchemaVersion",
        default: currentSettingsSchemaVersion
    )

    /// App version when settings were last saved (for migration purposes)
    static let lastKnownAppVersion = Key<String?>("lastKnownAppVersion")

    /// Build number when settings were last saved (for migration purposes)
    static let lastKnownBuildNumber = Key<String?>("lastKnownBuildNumber")

    /// Global behavior settings for all hotkey bindings
    static let appBehaviorSettings = Key<AppBehaviorSettings>(
        "appBehaviorSettings",
        default: .default
    )

    /// Array of hotkey bindings
    static let hotkeyBindings = Key<[HotkeyBinding]>(
        "hotkeyBindings",
        default: []
    )
}
