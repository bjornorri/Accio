//
//  AppInfoProvider.swift
//  Accio
//

/// Protocol for accessing current app bundle information.
protocol AppInfoProvider {
    /// The app's marketing version (CFBundleShortVersionString), e.g., "1.0.0"
    var version: String? { get }

    /// The app's build number (CFBundleVersion), e.g., "42"
    var buildNumber: String? { get }
}
