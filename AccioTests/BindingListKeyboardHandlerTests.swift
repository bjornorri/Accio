//
//  BindingListKeyboardHandlerTests.swift
//  AccioTests
//

import Testing
@testable import Accio

// MARK: - Mock Delegate

final class MockBindingListKeyboardHandlerDelegate: BindingListKeyboardHandlerDelegate {
    var hasSelection = false
    var hasSingleSelection = false
    var isListFocused = false
    var hasFilter = false

    var addItemCalled = false
    var removeSelectedCalled = false
    var focusSearchCalled = false
    var activateSelectedCalled = false
    var clearFilterCalled = false

    func keyboardHandlerDidRequestAddItem() { addItemCalled = true }
    func keyboardHandlerDidRequestRemoveSelected() { removeSelectedCalled = true }
    func keyboardHandlerDidRequestFocusSearch() { focusSearchCalled = true }
    func keyboardHandlerDidRequestActivateSelected() { activateSelectedCalled = true }
    func keyboardHandlerDidRequestClearFilter() { clearFilterCalled = true }
}

// MARK: - Tests

@Suite
struct BindingListKeyboardHandlerTests {

    // MARK: - canHandle Tests

    @Test func canHandle_addItem_alwaysReturnsTrue() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        handler.delegate = delegate

        #expect(handler.canHandle(.addItem) == true)
    }

    @Test func canHandle_focusSearch_alwaysReturnsTrue() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        handler.delegate = delegate

        #expect(handler.canHandle(.focusSearch) == true)
    }

    @Test func canHandle_removeSelected_returnsTrueWhenListFocusedAndHasSelection() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        delegate.hasSelection = true
        delegate.isListFocused = true
        handler.delegate = delegate

        #expect(handler.canHandle(.removeSelected) == true)
    }

    @Test func canHandle_removeSelected_returnsFalseWhenNoSelection() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        delegate.hasSelection = false
        delegate.isListFocused = true
        handler.delegate = delegate

        #expect(handler.canHandle(.removeSelected) == false)
    }

    @Test func canHandle_removeSelected_returnsFalseWhenListNotFocused() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        delegate.hasSelection = true
        delegate.isListFocused = false
        handler.delegate = delegate

        #expect(handler.canHandle(.removeSelected) == false)
    }

    @Test func canHandle_activateSelected_returnsTrueWhenListFocusedAndSingleSelection() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        delegate.hasSingleSelection = true
        delegate.isListFocused = true
        handler.delegate = delegate

        #expect(handler.canHandle(.activateSelected) == true)
    }

    @Test func canHandle_activateSelected_returnsFalseWhenMultipleSelection() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        delegate.hasSingleSelection = false
        delegate.isListFocused = true
        handler.delegate = delegate

        #expect(handler.canHandle(.activateSelected) == false)
    }

    @Test func canHandle_activateSelected_returnsFalseWhenListNotFocused() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        delegate.hasSingleSelection = true
        delegate.isListFocused = false
        handler.delegate = delegate

        #expect(handler.canHandle(.activateSelected) == false)
    }

    @Test func canHandle_clearFilter_returnsTrueWhenListFocusedAndHasFilter() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        delegate.hasFilter = true
        delegate.isListFocused = true
        handler.delegate = delegate

        #expect(handler.canHandle(.clearFilter) == true)
    }

    @Test func canHandle_clearFilter_returnsFalseWhenListNotFocused() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        delegate.hasFilter = true
        delegate.isListFocused = false
        handler.delegate = delegate

        #expect(handler.canHandle(.clearFilter) == false)
    }

    @Test func canHandle_clearFilter_returnsFalseWhenNoFilter() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        delegate.hasFilter = false
        delegate.isListFocused = true
        handler.delegate = delegate

        #expect(handler.canHandle(.clearFilter) == false)
    }

    @Test func canHandle_returnsFalseWhenNoDelegate() {
        let handler = BindingListKeyboardHandler()
        // No delegate set

        #expect(handler.canHandle(.addItem) == false)
        #expect(handler.canHandle(.removeSelected) == false)
        #expect(handler.canHandle(.focusSearch) == false)
        #expect(handler.canHandle(.activateSelected) == false)
        #expect(handler.canHandle(.clearFilter) == false)
    }

    // MARK: - handle Tests

    @Test func handle_addItem_callsDelegate() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        handler.delegate = delegate

        handler.handle(.addItem)

        #expect(delegate.addItemCalled == true)
    }

    @Test func handle_removeSelected_callsDelegate() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        handler.delegate = delegate

        handler.handle(.removeSelected)

        #expect(delegate.removeSelectedCalled == true)
    }

    @Test func handle_focusSearch_callsDelegate() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        handler.delegate = delegate

        handler.handle(.focusSearch)

        #expect(delegate.focusSearchCalled == true)
    }

    @Test func handle_activateSelected_callsDelegate() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        handler.delegate = delegate

        handler.handle(.activateSelected)

        #expect(delegate.activateSelectedCalled == true)
    }

    @Test func handle_clearFilter_callsDelegate() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        handler.delegate = delegate

        handler.handle(.clearFilter)

        #expect(delegate.clearFilterCalled == true)
    }
}
