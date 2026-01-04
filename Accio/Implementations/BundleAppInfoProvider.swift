//
//  BundleAppInfoProvider.swift
//  Accio
//

import Foundation

/// Provides app information from the main bundle.
final class BundleAppInfoProvider: AppInfoProvider {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    var version: String? {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    var buildNumber: String? {
        bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
}
