//
//  HotkeyManager.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 16.12.2025.
//

import Foundation

/// Manages global hotkey registration and handling
protocol HotkeyManager {
    /// Register a global hotkey with an async handler
    /// - Parameters:
    ///   - name: Unique name for the hotkey
    ///   - handler: Async closure to execute when the hotkey is triggered
    func register(name: String, handler: @escaping () async -> Void)

    /// Unregister a specific hotkey
    /// - Parameter name: The name of the hotkey to unregister
    func unregister(name: String)

    /// Unregister all hotkeys
    func unregisterAll()

    /// Pause all hotkeys temporarily (e.g., during shortcut recording)
    func pauseAll()

    /// Resume all hotkeys after pausing
    func resumeAll()
}
