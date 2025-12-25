//
//  NSWorkspaceAppMetadataProvider.swift
//  Accio
//

import AppKit

/// AppMetadataProvider implementation using NSWorkspace
final class NSWorkspaceAppMetadataProvider: AppMetadataProvider {
    private let workspace: NSWorkspace

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    func appName(for bundleIdentifier: String) -> String? {
        guard let appURL = appURL(for: bundleIdentifier),
              let bundle = Bundle(url: appURL) else {
            return nil
        }

        return bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? appURL.deletingPathExtension().lastPathComponent
    }

    func appIcon(for bundleIdentifier: String) -> NSImage? {
        guard let appURL = appURL(for: bundleIdentifier) else {
            return nil
        }
        return workspace.icon(forFile: appURL.path)
    }

    func isInstalled(_ bundleIdentifier: String) -> Bool {
        appURL(for: bundleIdentifier) != nil
    }

    func appURL(for bundleIdentifier: String) -> URL? {
        workspace.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }
}
