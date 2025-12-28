//
//  MockAppMetadataProvider.swift
//  AccioTests
//

import AppKit
@testable import Accio

final class MockAppMetadataProvider: AppMetadataProvider {
    var appNames: [String: String] = [:]
    var appIcons: [String: NSImage] = [:]
    var installedApps: Set<String> = []
    var appURLs: [String: URL] = [:]

    func appName(for bundleIdentifier: String) -> String? {
        appNames[bundleIdentifier]
    }

    func appIcon(for bundleIdentifier: String) -> NSImage? {
        appIcons[bundleIdentifier]
    }

    func isInstalled(_ bundleIdentifier: String) -> Bool {
        installedApps.contains(bundleIdentifier)
    }

    func appURL(for bundleIdentifier: String) -> URL? {
        appURLs[bundleIdentifier]
    }
}
