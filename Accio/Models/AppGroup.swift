//
//  AppGroup.swift
//  Accio
//

import Defaults
import Foundation

/// A member application in an app group
struct AppGroupMember: Codable, Equatable {
    /// The bundle identifier of the application
    let bundleIdentifier: String
    /// Cached display name of the application
    let appName: String
}

/// A named group of applications bound to a keyboard shortcut
struct AppGroup: Codable, Identifiable, Defaults.Serializable, Equatable {
    /// Unique identifier for this group
    let id: UUID
    /// Name used for KeyboardShortcuts registration
    let shortcutName: String
    /// User-visible name of the group
    var name: String
    /// Member applications, ordered by most recently active first
    var members: [AppGroupMember]

    init(id: UUID = UUID(), name: String = "New Group") {
        self.id = id
        self.shortcutName = "group-\(id.uuidString)"
        self.name = name
        self.members = []
    }
}
