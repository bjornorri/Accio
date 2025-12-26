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
            hasSingleSelection: { false },
            onAddItem: {},
            onRemoveSelected: {},
            onFocusSelected: {}
        )

        #expect(handler.canHandle(.addItem) == true)
    }

    @Test func canHandle_removeSelected_returnsTrueWhenHasSelection() {
        let handler = BindingListKeyboardHandler(
            hasSelection: { true },
            hasSingleSelection: { false },
            onAddItem: {},
            onRemoveSelected: {},
            onFocusSelected: {}
        )

        #expect(handler.canHandle(.removeSelected) == true)
    }

    @Test func canHandle_removeSelected_returnsFalseWhenNoSelection() {
        let handler = BindingListKeyboardHandler(
            hasSelection: { false },
            hasSingleSelection: { false },
            onAddItem: {},
            onRemoveSelected: {},
            onFocusSelected: {}
        )

        #expect(handler.canHandle(.removeSelected) == false)
    }

    @Test func canHandle_focusSelected_returnsTrueWhenSingleSelection() {
        let handler = BindingListKeyboardHandler(
            hasSelection: { true },
            hasSingleSelection: { true },
            onAddItem: {},
            onRemoveSelected: {},
            onFocusSelected: {}
        )

        #expect(handler.canHandle(.focusSelected) == true)
    }

    @Test func canHandle_focusSelected_returnsFalseWhenMultipleSelection() {
        let handler = BindingListKeyboardHandler(
            hasSelection: { true },
            hasSingleSelection: { false },
            onAddItem: {},
            onRemoveSelected: {},
            onFocusSelected: {}
        )

        #expect(handler.canHandle(.focusSelected) == false)
    }

    @Test func handle_addItem_callsOnAddItem() {
        var called = false
        let handler = BindingListKeyboardHandler(
            hasSelection: { false },
            hasSingleSelection: { false },
            onAddItem: { called = true },
            onRemoveSelected: {},
            onFocusSelected: {}
        )

        handler.handle(.addItem)

        #expect(called == true)
    }

    @Test func handle_removeSelected_callsOnRemoveSelected() {
        var called = false
        let handler = BindingListKeyboardHandler(
            hasSelection: { true },
            hasSingleSelection: { false },
            onAddItem: {},
            onRemoveSelected: { called = true },
            onFocusSelected: {}
        )

        handler.handle(.removeSelected)

        #expect(called == true)
    }

    @Test func handle_focusSelected_callsOnFocusSelected() {
        var called = false
        let handler = BindingListKeyboardHandler(
            hasSelection: { true },
            hasSingleSelection: { true },
            onAddItem: {},
            onRemoveSelected: {},
            onFocusSelected: { called = true }
        )

        handler.handle(.focusSelected)

        #expect(called == true)
    }
}
