//
//  KeyboardShortcutHandler.swift
//  Accio
//

import AppKit

/// Represents a keyboard shortcut action for list views
enum KeyboardAction {
    case addItem
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
    /// Called when the add item action is triggered (Cmd+N)
    func keyboardHandlerDidRequestAddItem()
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
        guard delegate != nil else { return false }

        switch action {
        case .addItem:
            return true
        }
    }

    func handle(_ action: KeyboardAction) {
        guard let delegate else { return }

        switch action {
        case .addItem:
            delegate.keyboardHandlerDidRequestAddItem()
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard let window = event.window, window.isKeyWindow else {
            return event
        }

        // Cmd+N: Add item
        let hasCommand = event.modifierFlags.contains(.command)
        if hasCommand && event.charactersIgnoringModifiers == "n" {
            if canHandle(.addItem) {
                handle(.addItem)
                return nil
            }
        }

        return event
    }
}
