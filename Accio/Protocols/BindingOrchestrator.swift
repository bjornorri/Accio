//
//  BindingOrchestrator.swift
//  Accio
//

import Foundation

/// Manages the lifecycle of hotkey bindings and app groups
///
/// Responsibilities:
/// - Observes hotkey bindings and app groups from storage
/// - Registers/unregisters hotkeys as bindings/groups change
/// - Executes actions when hotkeys are triggered
protocol BindingOrchestrator: AnyObject {
    /// Start observing binding changes and register existing bindings
    func start()

    /// Stop observing and unregister all bindings
    func stop()

    /// Find a shortcut conflict for any item (binding or group) with the given shortcut name
    /// - Parameter shortcutName: The shortcut name string to check
    /// - Returns: A conflict if another item already uses the same shortcut, nil otherwise
    func findConflict(for shortcutName: String) -> ShortcutConflict?

    /// Clear the shortcut for a conflict item
    /// - Parameter item: The item whose shortcut should be cleared
    func clearShortcut(for item: ShortcutConflict.Item)
}
