//
//  MockAppInfoProvider.swift
//  AccioTests
//

@testable import Accio

final class MockAppInfoProvider: AppInfoProvider {
    var version: String?
    var buildNumber: String?

    init(version: String? = nil, buildNumber: String? = nil) {
        self.version = version
        self.buildNumber = buildNumber
    }
}
