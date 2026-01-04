//
//  MockAppSettingsStore.swift
//  AccioTests
//

@testable import Accio

final class MockAppSettingsStore: AppSettingsStore {
    var lastKnownAppVersion: String?
    var lastKnownBuildNumber: String?
}
