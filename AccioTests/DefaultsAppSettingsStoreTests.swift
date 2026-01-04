//
//  DefaultsAppSettingsStoreTests.swift
//  AccioTests
//

import Defaults
import Testing
@testable import Accio

@Suite(.serialized)
struct DefaultsAppSettingsStoreTests {

    init() {
        // Reset to default values before each test
        Defaults.reset(.lastKnownAppVersion, .lastKnownBuildNumber)
    }

    // MARK: - lastKnownAppVersion

    @Test func lastKnownAppVersion_defaultsToNil() {
        let store = DefaultsAppSettingsStore()

        #expect(store.lastKnownAppVersion == nil)
    }

    @Test func lastKnownAppVersion_canBeSet() {
        let store = DefaultsAppSettingsStore()

        store.lastKnownAppVersion = "1.0.0"

        #expect(store.lastKnownAppVersion == "1.0.0")
    }

    @Test func lastKnownAppVersion_canBeSetToNil() {
        let store = DefaultsAppSettingsStore()
        store.lastKnownAppVersion = "1.0.0"

        store.lastKnownAppVersion = nil

        #expect(store.lastKnownAppVersion == nil)
    }

    @Test func lastKnownAppVersion_persistsToDefaults() {
        let store = DefaultsAppSettingsStore()

        store.lastKnownAppVersion = "2.0.0"

        #expect(Defaults[.lastKnownAppVersion] == "2.0.0")
    }

    // MARK: - lastKnownBuildNumber

    @Test func lastKnownBuildNumber_defaultsToNil() {
        let store = DefaultsAppSettingsStore()

        #expect(store.lastKnownBuildNumber == nil)
    }

    @Test func lastKnownBuildNumber_canBeSet() {
        let store = DefaultsAppSettingsStore()

        store.lastKnownBuildNumber = "42"

        #expect(store.lastKnownBuildNumber == "42")
    }

    @Test func lastKnownBuildNumber_canBeSetToNil() {
        let store = DefaultsAppSettingsStore()
        store.lastKnownBuildNumber = "42"

        store.lastKnownBuildNumber = nil

        #expect(store.lastKnownBuildNumber == nil)
    }

    @Test func lastKnownBuildNumber_persistsToDefaults() {
        let store = DefaultsAppSettingsStore()

        store.lastKnownBuildNumber = "99"

        #expect(Defaults[.lastKnownBuildNumber] == "99")
    }
}
