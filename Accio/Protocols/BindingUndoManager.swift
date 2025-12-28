//
//  BindingUndoManager.swift
//  Accio
//

import Foundation

/// Manages undo/redo operations for binding list changes
protocol BindingUndoManager: AnyObject {
    /// Whether an undo operation can be performed
    var canUndo: Bool { get }

    /// Whether a redo operation can be performed
    var canRedo: Bool { get }

    /// Whether the undo manager is currently enabled
    var isEnabled: Bool { get }

    /// Enables the undo manager (responds to undo/redo requests)
    func enable()

    /// Disables the undo manager (ignores undo/redo requests)
    func disable()

    /// Performs an undo operation
    func undo()

    /// Performs a redo operation
    func redo()

    /// Registers an undo operation
    func registerUndo(handler: @escaping () -> Void)

    /// Sets the action name for the most recent undo registration
    func setActionName(_ name: String)
}
