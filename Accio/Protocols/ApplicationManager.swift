//
//  ApplicationManager.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 16.12.2025.
//

import Foundation

/// Manages application launching, activation, and state checking
protocol ApplicationManager {
    /// Launch an application by its bundle identifier
    /// - Parameter bundleIdentifier: The bundle identifier of the app to launch
    /// - Throws: Error if the application cannot be launched
    func launch(bundleIdentifier: String) async throws

    /// Activate (focus) an application by its bundle identifier
    /// - Parameter bundleIdentifier: The bundle identifier of the app to activate
    /// - Throws: Error if the application cannot be activated
    @MainActor func activate(bundleIdentifier: String) throws

    /// Check if an application is currently running
    /// - Parameter bundleIdentifier: The bundle identifier of the app to check
    /// - Returns: True if the application is running, false otherwise
    @MainActor func isRunning(bundleIdentifier: String) -> Bool

    /// Check if an application is currently focused (frontmost)
    /// - Parameter bundleIdentifier: The bundle identifier of the app to check
    /// - Returns: True if the application is focused, false otherwise
    @MainActor func isFocused(bundleIdentifier: String) -> Bool

    /// Hide an application by its bundle identifier
    /// - Parameter bundleIdentifier: The bundle identifier of the app to hide
    /// - Throws: Error if the application cannot be hidden
    @MainActor func hide(bundleIdentifier: String) throws
}
