//
//  AppBehaviorSettings.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import Foundation
import Defaults

// MARK: - Action Enums

/// Action to take when the target app is not running
enum NotRunningAction: String, Codable, Defaults.Serializable, CaseIterable {
    case launchApp
    case doNothing

    var displayName: String {
        switch self {
        case .launchApp: return "Launch App"
        case .doNothing: return "Do Nothing"
        }
    }
}

/// Action to take when the target app is running but not focused
enum NotFocusedAction: String, Codable, Defaults.Serializable, CaseIterable {
    case focusApp
    case doNothing

    var displayName: String {
        switch self {
        case .focusApp: return "Focus App"
        case .doNothing: return "Do Nothing"
        }
    }
}

/// Action to take when the target app is already focused
enum FocusedAction: String, Codable, Defaults.Serializable, CaseIterable {
    case cycleWindows
    case hideApp
    case doNothing

    var displayName: String {
        switch self {
        case .cycleWindows: return "Cycle Windows"
        case .hideApp: return "Hide App"
        case .doNothing: return "Do Nothing"
        }
    }
}

// MARK: - Settings Struct

/// Global behavior settings that apply to all hotkey bindings
struct AppBehaviorSettings: Codable, Defaults.Serializable {
    var whenNotRunning: NotRunningAction
    var whenNotFocused: NotFocusedAction
    var whenFocused: FocusedAction

    /// Default settings matching the most common use case
    static let `default` = AppBehaviorSettings(
        whenNotRunning: .launchApp,
        whenNotFocused: .focusApp,
        whenFocused: .cycleWindows
    )
}
