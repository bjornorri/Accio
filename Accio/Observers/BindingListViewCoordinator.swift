//
//  BindingListViewCoordinator.swift
//  Accio
//

import AppKit

/// Coordinates keyboard handling and focus management for BindingListView.
///
/// This class owns the keyboard handler and focus coordinator, implementing
/// the keyboard handler delegate directly to avoid unnecessary indirection.
final class BindingListViewCoordinator: BindingListKeyboardHandlerDelegate {
    let focusCoordinator = BindingListFocusCoordinator()
    let keyboardHandler = BindingListKeyboardHandler()

    // MARK: - State Callbacks

    /// Returns whether there is at least one selected item
    var checkHasSelection: (() -> Bool)?

    /// Returns whether exactly one item is selected
    var checkHasSingleSelection: (() -> Bool)?

    /// Returns whether a search filter is active
    var checkHasFilter: (() -> Bool)?

    // MARK: - Action Callbacks

    /// Called when the add item action is triggered (Cmd+N)
    var onAddItem: (() -> Void)?

    /// Called when the remove selected action is triggered (Delete/Backspace)
    var onRemoveSelected: (() -> Void)?

    /// Called when the focus search action is triggered (Cmd+F)
    var onFocusSearch: (() -> Void)?

    /// Called when the activate selected action is triggered (Enter/Space)
    var onActivateSelected: (() -> Void)?

    /// Called when the clear filter action is triggered (Escape)
    var onClearFilter: (() -> Void)?

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

    var hasSelection: Bool {
        checkHasSelection?() ?? false
    }

    var hasSingleSelection: Bool {
        checkHasSingleSelection?() ?? false
    }

    var isListFocused: Bool {
        focusCoordinator.isListFocused()
    }

    var hasFilter: Bool {
        checkHasFilter?() ?? false
    }

    func keyboardHandlerDidRequestAddItem() {
        onAddItem?()
    }

    func keyboardHandlerDidRequestRemoveSelected() {
        onRemoveSelected?()
    }

    func keyboardHandlerDidRequestFocusSearch() {
        onFocusSearch?()
    }

    func keyboardHandlerDidRequestActivateSelected() {
        onActivateSelected?()
    }

    func keyboardHandlerDidRequestClearFilter() {
        onClearFilter?()
    }
}
