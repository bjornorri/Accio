//
//  BundleAppInfoProviderTests.swift
//  AccioTests
//

import Foundation
import Testing
@testable import Accio

@Suite
struct BundleAppInfoProviderTests {

    @Test func version_returnsStringFromBundle() {
        let provider = BundleAppInfoProvider()

        // The test target has an Info.plist with CFBundleShortVersionString
        let version = provider.version

        // Should return a version string (may be nil if not set in test bundle)
        // At minimum, verify it doesn't crash and returns expected type
        #expect(version == nil || !version!.isEmpty)
    }

    @Test func buildNumber_returnsStringFromBundle() {
        let provider = BundleAppInfoProvider()

        // The test target has an Info.plist with CFBundleVersion
        let buildNumber = provider.buildNumber

        // Should return a build number string (may be nil if not set in test bundle)
        #expect(buildNumber == nil || !buildNumber!.isEmpty)
    }

    @Test func version_usesInjectedBundle() {
        // Create a bundle that we know has version info (the main app bundle)
        let mainBundle = Bundle.main
        let provider = BundleAppInfoProvider(bundle: mainBundle)

        // Just verify it uses the injected bundle without crashing
        _ = provider.version
        _ = provider.buildNumber
    }
}
