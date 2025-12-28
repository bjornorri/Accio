//
//  KeyboardShortcutHandler.swift
//  Accio
//

import AppKit

/// Represents a keyboard shortcut action for list views
enum KeyboardAction {
    case addItem
    case removeSelected
    case focusSearch
    case activateSelected
    case clearFilter
}

/// Protocol for handling keyboard shortcuts in list views
protocol KeyboardShortcutHandler: AnyObject {
    /// Called when a keyboard action is triggered
    func handle(_ action: KeyboardAction)

    /// Whether the handler can currently perform the given action
    func canHandle(_ action: KeyboardAction) -> Bool
}

// MARK: - Delegate Protocol

/// Delegate protocol for BindingListKeyboardHandler
protocol BindingListKeyboardHandlerDelegate: AnyObject {
    /// Returns whether there is at least one selected item
    var hasSelection: Bool { get }

    /// Returns whether exactly one item is selected
    var hasSingleSelection: Bool { get }

    /// Returns whether the list is currently focused
    var isListFocused: Bool { get }

    /// Returns whether a search filter is active
    var hasFilter: Bool { get }

    /// Called when the add item action is triggered (Cmd+N)
    func keyboardHandlerDidRequestAddItem()

    /// Called when the remove selected action is triggered (Delete/Backspace)
    func keyboardHandlerDidRequestRemoveSelected()

    /// Called when the focus search action is triggered (Cmd+F)
    func keyboardHandlerDidRequestFocusSearch()

    /// Called when the activate selected action is triggered (Enter/Space)
    func keyboardHandlerDidRequestActivateSelected()

    /// Called when the clear filter action is triggered (Escape)
    func keyboardHandlerDidRequestClearFilter()
}

// MARK: - Keyboard Handler for Binding List

/// Handles keyboard shortcuts for the binding list view
final class BindingListKeyboardHandler: KeyboardShortcutHandler {
    private var monitor: Any?
    weak var delegate: BindingListKeyboardHandlerDelegate?

    func start() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event) ?? event
        }
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    func canHandle(_ action: KeyboardAction) -> Bool {
        guard let delegate else { return false }

        switch action {
        case .addItem, .focusSearch:
            return true
        case .removeSelected:
            return delegate.isListFocused && delegate.hasSelection
        case .activateSelected:
            return delegate.isListFocused && delegate.hasSingleSelection
        case .clearFilter:
            return delegate.isListFocused && delegate.hasFilter
        }
    }

    func handle(_ action: KeyboardAction) {
        guard let delegate else { return }

        switch action {
        case .addItem:
            delegate.keyboardHandlerDidRequestAddItem()
        case .removeSelected:
            delegate.keyboardHandlerDidRequestRemoveSelected()
        case .focusSearch:
            delegate.keyboardHandlerDidRequestFocusSearch()
        case .activateSelected:
            delegate.keyboardHandlerDidRequestActivateSelected()
        case .clearFilter:
            delegate.keyboardHandlerDidRequestClearFilter()
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard let window = event.window, window.isKeyWindow else {
            return event
        }

        let hasCommand = event.modifierFlags.contains(.command)
        let hasNoModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty

        // Cmd+N: Add item
        if hasCommand && event.charactersIgnoringModifiers == "n" {
            if canHandle(.addItem) {
                handle(.addItem)
                return nil
            }
        }

        // Cmd+F is handled by Edit > Find menu item

        // Delete/Backspace: Remove selected
        if hasNoModifiers && (event.keyCode == 51 || event.keyCode == 117) {
            if canHandle(.removeSelected) {
                handle(.removeSelected)
                return nil
            }
        }

        // Return/Enter/Space: Activate selected item's recorder
        if hasNoModifiers && (event.keyCode == 36 || event.keyCode == 76 || event.keyCode == 49) {
            if canHandle(.activateSelected) {
                handle(.activateSelected)
                return nil
            }
        }

        // Escape: Clear filter when list is focused
        if hasNoModifiers && event.keyCode == 53 {
            if canHandle(.clearFilter) {
                handle(.clearFilter)
                return nil
            }
        }

        return event
    }
}
