//
//  DefaultBindingUndoManagerTests.swift
//  AccioTests
//

import Testing
@testable import Accio

@Suite
struct DefaultBindingUndoManagerTests {
    @Test func initialState_hasCorrectDefaults() {
        let undoManager = DefaultBindingUndoManager()

        #expect(undoManager.canUndo == false)
        #expect(undoManager.canRedo == false)
        #expect(undoManager.isEnabled == false)
    }

    @Test func enable_setsIsEnabledToTrue() {
        let undoManager = DefaultBindingUndoManager()

        undoManager.enable()

        #expect(undoManager.isEnabled == true)
    }

    @Test func disable_setsIsEnabledToFalse() {
        let undoManager = DefaultBindingUndoManager()
        undoManager.enable()

        undoManager.disable()

        #expect(undoManager.isEnabled == false)
    }

    @Test func registerUndo_updatesCanUndo() {
        let undoManager = DefaultBindingUndoManager()

        undoManager.registerUndo { }

        #expect(undoManager.canUndo == true)
        #expect(undoManager.canRedo == false)
    }

    @Test func undo_whenEnabled_performsUndo() {
        let undoManager = DefaultBindingUndoManager()
        var undoCalled = false
        undoManager.registerUndo { undoCalled = true }
        undoManager.enable()

        undoManager.undo()

        #expect(undoCalled == true)
        #expect(undoManager.canUndo == false)
    }

    @Test func undo_whenDisabled_doesNothing() {
        let undoManager = DefaultBindingUndoManager()
        var undoCalled = false
        undoManager.registerUndo { undoCalled = true }

        undoManager.undo()

        #expect(undoCalled == false)
        #expect(undoManager.canUndo == true)
        #expect(undoManager.canRedo == false)
    }

    @Test func redo_whenEnabled_performsRedo() {
        let undoManager = DefaultBindingUndoManager()
        var value = 0

        // Register an undo that sets value to 1 and registers redo
        undoManager.registerUndo {
            value = 1
            undoManager.registerUndo { value = 0 }
        }
        undoManager.enable()

        undoManager.undo()
        #expect(value == 1)
        #expect(undoManager.canRedo == true)

        undoManager.redo()
        #expect(value == 0)
        #expect(undoManager.canUndo == true)
    }

    @Test func redo_whenDisabled_doesNothing() {
        let undoManager = DefaultBindingUndoManager()
        var value = 0

        undoManager.registerUndo {
            value = 1
            undoManager.registerUndo { value = 0 }
        }
        undoManager.enable()
        undoManager.undo()
        #expect(value == 1)

        undoManager.disable()
        undoManager.redo()

        #expect(value == 1)  // Value unchanged because redo was disabled
        #expect(undoManager.canRedo == true)  // Still has redo available
    }

    @Test func multipleUndos_executesInReverseOrder() {
        let undoManager = DefaultBindingUndoManager()
        var values: [Int] = []
        undoManager.enable()

        undoManager.registerUndo { values.append(1) }
        undoManager.registerUndo { values.append(2) }
        undoManager.registerUndo { values.append(3) }

        #expect(undoManager.canUndo == true)

        undoManager.undo()
        undoManager.undo()
        undoManager.undo()

        // Undos execute in reverse order (LIFO)
        #expect(values == [3, 2, 1])
    }

    @Test func setActionName_doesNotThrow() {
        let undoManager = DefaultBindingUndoManager()
        undoManager.registerUndo { }

        undoManager.setActionName("Test Action")

        #expect(undoManager.canUndo == true)
    }
}
