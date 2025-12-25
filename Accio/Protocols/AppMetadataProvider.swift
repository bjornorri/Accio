//
//  AppMetadataProvider.swift
//  Accio
//

import AppKit

/// Provides metadata about installed applications
protocol AppMetadataProvider {
    /// Returns the display name of the application, or nil if not installed
    func appName(for bundleIdentifier: String) -> String?

    /// Returns the application icon, or nil if not installed
    func appIcon(for bundleIdentifier: String) -> NSImage?

    /// Returns whether the application is currently installed
    func isInstalled(_ bundleIdentifier: String) -> Bool

    /// Returns the URL of the application bundle, or nil if not installed
    func appURL(for bundleIdentifier: String) -> URL?
}
