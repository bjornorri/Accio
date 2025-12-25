//
//  NSWorkspaceAppMetadataProviderTests.swift
//  AccioTests
//

import AppKit
import Testing

@testable import Accio

@Suite
struct NSWorkspaceAppMetadataProviderTests {
    private let provider = NSWorkspaceAppMetadataProvider()

    // MARK: - isInstalled

    @Test func isInstalled_returnsTrueForFinder() {
        #expect(provider.isInstalled("com.apple.finder"))
    }

    @Test func isInstalled_returnsFalseForNonexistentApp() {
        #expect(!provider.isInstalled("com.nonexistent.app.that.does.not.exist"))
    }

    // MARK: - appURL

    @Test func appURL_returnsURLForFinder() {
        let url = provider.appURL(for: "com.apple.finder")
        #expect(url != nil)
        #expect(url?.lastPathComponent == "Finder.app")
    }

    @Test func appURL_returnsNilForNonexistentApp() {
        let url = provider.appURL(for: "com.nonexistent.app.that.does.not.exist")
        #expect(url == nil)
    }

    // MARK: - appName

    @Test func appName_returnsFinderForFinderBundleId() {
        let name = provider.appName(for: "com.apple.finder")
        #expect(name == "Finder")
    }

    @Test func appName_returnsNilForNonexistentApp() {
        let name = provider.appName(for: "com.nonexistent.app.that.does.not.exist")
        #expect(name == nil)
    }

    // MARK: - appIcon

    @Test func appIcon_returnsIconForFinder() {
        let icon = provider.appIcon(for: "com.apple.finder")
        #expect(icon != nil)
    }

    @Test func appIcon_returnsNilForNonexistentApp() {
        let icon = provider.appIcon(for: "com.nonexistent.app.that.does.not.exist")
        #expect(icon == nil)
    }
}
