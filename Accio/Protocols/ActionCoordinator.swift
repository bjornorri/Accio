//
//  ActionCoordinator.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import Foundation

/// Coordinates hotkey actions based on app state and behavior settings
protocol ActionCoordinator {
    /// Execute the appropriate action for an application based on its state and settings
    /// - Parameters:
    ///   - bundleIdentifier: The bundle identifier of the target app
    ///   - settings: The behavior settings to apply
    func executeAction(for bundleIdentifier: String, settings: AppBehaviorSettings) async
}
