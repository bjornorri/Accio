//
//  DefaultBindingUndoManager.swift
//  Accio
//

import Foundation

/// Default implementation of BindingUndoManager using Foundation's UndoManager
@Observable
final class DefaultBindingUndoManager: BindingUndoManager {
    private let undoManager = UndoManager()
    private(set) var canUndo = false
    private(set) var canRedo = false
    private(set) var isEnabled = false

    func enable() {
        isEnabled = true
    }

    func disable() {
        isEnabled = false
    }

    func undo() {
        guard isEnabled else { return }
        undoManager.undo()
        updateState()
    }

    func redo() {
        guard isEnabled else { return }
        undoManager.redo()
        updateState()
    }

    func registerUndo(handler: @escaping () -> Void) {
        undoManager.registerUndo(withTarget: self) { _ in
            handler()
        }
        updateState()
    }

    func setActionName(_ name: String) {
        undoManager.setActionName(name)
    }

    private func updateState() {
        canUndo = undoManager.canUndo
        canRedo = undoManager.canRedo
    }
}
