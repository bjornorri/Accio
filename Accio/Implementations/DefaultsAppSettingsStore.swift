//
//  DefaultsAppSettingsStore.swift
//  Accio
//

import Defaults

/// Stores app settings using Defaults (UserDefaults wrapper).
final class DefaultsAppSettingsStore: AppSettingsStore {
    var lastKnownAppVersion: String? {
        get { Defaults[.lastKnownAppVersion] }
        set { Defaults[.lastKnownAppVersion] = newValue }
    }

    var lastKnownBuildNumber: String? {
        get { Defaults[.lastKnownBuildNumber] }
        set { Defaults[.lastKnownBuildNumber] = newValue }
    }
}
