//
//  BindingListKeyboardHandlerTests.swift
//  AccioTests
//

import Testing
@testable import Accio

// MARK: - Mock Delegate

final class MockBindingListKeyboardHandlerDelegate: BindingListKeyboardHandlerDelegate {
    var addItemCalled = false

    func keyboardHandlerDidRequestAddItem() { addItemCalled = true }
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

    @Test func canHandle_returnsFalseWhenNoDelegate() {
        let handler = BindingListKeyboardHandler()
        // No delegate set

        #expect(handler.canHandle(.addItem) == false)
    }

    // MARK: - handle Tests

    @Test func handle_addItem_callsDelegate() {
        let handler = BindingListKeyboardHandler()
        let delegate = MockBindingListKeyboardHandlerDelegate()
        handler.delegate = delegate

        handler.handle(.addItem)

        #expect(delegate.addItemCalled == true)
    }
}
