//
//  BindingListViewCoordinator.swift
//  Accio
//

import AppKit

/// Coordinates keyboard handling and focus management for BindingListView.
///
/// This class owns the keyboard handler and focus coordinator, implementing
/// the keyboard handler delegate directly to avoid unnecessary indirection.
@MainActor
final class BindingListViewCoordinator: BindingListKeyboardHandlerDelegate {
    let focusCoordinator = BindingListFocusCoordinator()
    let keyboardHandler = BindingListKeyboardHandler()

    // MARK: - Action Callbacks

    /// Called when the add item action is triggered (Cmd+N)
    var onAddItem: (() -> Void)?

    // MARK: - Lifecycle

    func start() {
        keyboardHandler.delegate = self
        keyboardHandler.start()
        focusCoordinator.start()
        focusCoordinator.clearSavedState()
    }

    func stop() {
        keyboardHandler.stop()
        focusCoordinator.stop()
    }

    // MARK: - BindingListKeyboardHandlerDelegate

    func keyboardHandlerDidRequestAddItem() {
        onAddItem?()
    }
}
