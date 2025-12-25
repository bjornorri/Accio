//
//  HotkeyBinding.swift
//  Accio
//

import AppKit
import Defaults
import Foundation

/// A hotkey binding that maps a keyboard shortcut to an application
struct HotkeyBinding: Codable, Identifiable, Defaults.Serializable, Equatable {
    /// Unique identifier for this binding
    let id: UUID

    /// Name used for KeyboardShortcuts registration (maps to KeyboardShortcuts.Name)
    let shortcutName: String

    /// Bundle identifier of the target application
    let appBundleIdentifier: String

    /// Cached display name of the application (captured at binding creation)
    let appName: String

    init(id: UUID = UUID(), shortcutName: String, appBundleIdentifier: String, appName: String? = nil) {
        self.id = id
        self.shortcutName = shortcutName
        self.appBundleIdentifier = appBundleIdentifier
        self.appName = appName ?? appBundleIdentifier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        shortcutName = try container.decode(String.self, forKey: .shortcutName)
        appBundleIdentifier = try container.decode(String.self, forKey: .appBundleIdentifier)

        // Migration: if appName is missing, try to resolve it or fall back to bundle identifier
        if let name = try container.decodeIfPresent(String.self, forKey: .appName) {
            appName = name
        } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appBundleIdentifier),
                  let bundle = Bundle(url: appURL) {
            appName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? appURL.deletingPathExtension().lastPathComponent
        } else {
            appName = appBundleIdentifier
        }
    }
}
