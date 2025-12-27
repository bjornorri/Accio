//
//  BindingListKeyboardHandlerTests.swift
//  AccioTests
//

import Testing
@testable import Accio

@Suite
struct BindingListKeyboardHandlerTests {

    @Test func canHandle_addItem_alwaysReturnsTrue() {
        let handler = BindingListKeyboardHandler(
            hasSelection: { false },
            onAddItem: {},
            onRemoveSelected: {}
        )

        #expect(handler.canHandle(.addItem) == true)
    }

    @Test func canHandle_removeSelected_returnsTrueWhenHasSelection() {
        let handler = BindingListKeyboardHandler(
            hasSelection: { true },
            onAddItem: {},
            onRemoveSelected: {}
        )

        #expect(handler.canHandle(.removeSelected) == true)
    }

    @Test func canHandle_removeSelected_returnsFalseWhenNoSelection() {
        let handler = BindingListKeyboardHandler(
            hasSelection: { false },
            onAddItem: {},
            onRemoveSelected: {}
        )

        #expect(handler.canHandle(.removeSelected) == false)
    }

    @Test func handle_addItem_callsOnAddItem() {
        var called = false
        let handler = BindingListKeyboardHandler(
            hasSelection: { false },
            onAddItem: { called = true },
            onRemoveSelected: {}
        )

        handler.handle(.addItem)

        #expect(called == true)
    }

    @Test func handle_removeSelected_callsOnRemoveSelected() {
        var called = false
        let handler = BindingListKeyboardHandler(
            hasSelection: { true },
            onAddItem: {},
            onRemoveSelected: { called = true }
        )

        handler.handle(.removeSelected)

        #expect(called == true)
    }
}
