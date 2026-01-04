//
//  AppSettingsStore.swift
//  Accio
//

/// Protocol for storing app-level settings.
protocol AppSettingsStore {
    /// App version when settings were last saved
    var lastKnownAppVersion: String? { get set }

    /// Build number when settings were last saved
    var lastKnownBuildNumber: String? { get set }
}
