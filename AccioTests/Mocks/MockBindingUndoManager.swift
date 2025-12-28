//
//  MockBindingUndoManager.swift
//  AccioTests
//

import Foundation
@testable import Accio

final class MockBindingUndoManager: BindingUndoManager {
    var canUndo = false
    var canRedo = false
    var isEnabled = false
    var undoHandlers: [() -> Void] = []
    var actionNames: [String] = []

    func enable() {
        isEnabled = true
    }

    func disable() {
        isEnabled = false
    }

    func undo() {
        guard isEnabled, let handler = undoHandlers.popLast() else { return }
        handler()
    }

    func redo() {}

    func registerUndo(handler: @escaping () -> Void) {
        undoHandlers.append(handler)
        canUndo = true
    }

    func setActionName(_ name: String) {
        actionNames.append(name)
    }
}
