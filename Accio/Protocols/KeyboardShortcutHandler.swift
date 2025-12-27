//
//  KeyboardShortcutHandler.swift
//  Accio
//

import AppKit

/// Represents a keyboard shortcut action for list views
enum KeyboardAction {
    case addItem
    case removeSelected
}

/// Protocol for handling keyboard shortcuts in list views
protocol KeyboardShortcutHandler: AnyObject {
    /// Called when a keyboard action is triggered
    func handle(_ action: KeyboardAction)

    /// Whether the handler can currently perform the given action
    func canHandle(_ action: KeyboardAction) -> Bool
}

// MARK: - Keyboard Handler for Binding List

/// Handles keyboard shortcuts for the binding list view
final class BindingListKeyboardHandler: KeyboardShortcutHandler {
    private var monitor: Any?

    private let hasSelection: () -> Bool
    private let onAddItem: () -> Void
    private let onRemoveSelected: () -> Void

    init(
        hasSelection: @escaping () -> Bool,
        onAddItem: @escaping () -> Void,
        onRemoveSelected: @escaping () -> Void
    ) {
        self.hasSelection = hasSelection
        self.onAddItem = onAddItem
        self.onRemoveSelected = onRemoveSelected
    }

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
        switch action {
        case .addItem:
            return true
        case .removeSelected:
            return hasSelection()
        }
    }

    func handle(_ action: KeyboardAction) {
        switch action {
        case .addItem:
            onAddItem()
        case .removeSelected:
            onRemoveSelected()
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

        // Delete/Backspace: Remove selected
        if hasNoModifiers && (event.keyCode == 51 || event.keyCode == 117) {
            if canHandle(.removeSelected) {
                handle(.removeSelected)
                return nil
            }
        }

        return event
    }
}
