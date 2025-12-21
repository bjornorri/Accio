//
//  DefaultsKeys.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import Defaults

// MARK: - Defaults Keys

extension Defaults.Keys {
    /// Global behavior settings for all hotkey bindings
    static let appBehaviorSettings = Key<AppBehaviorSettings>(
        "appBehaviorSettings",
        default: .default
    )
}
