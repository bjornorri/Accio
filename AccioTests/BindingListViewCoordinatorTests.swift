//
//  BindingListViewCoordinatorTests.swift
//  AccioTests
//

import Testing
@testable import Accio

@Suite
struct BindingListViewCoordinatorTests {

    // MARK: - Lifecycle Tests

    @Test func start_startsKeyboardHandlerAndFocusCoordinator() {
        let coordinator = BindingListViewCoordinator()
        coordinator.start()

        // Verify keyboard handler has delegate set
        #expect(coordinator.keyboardHandler.delegate != nil)

        coordinator.stop()
    }

    @Test func stop_stopsKeyboardHandlerAndFocusCoordinator() {
        let coordinator = BindingListViewCoordinator()
        coordinator.start()
        coordinator.stop()

        // If we got here without crashing, cleanup worked
    }

    // MARK: - Delegate State Tests

    @Test func hasSelection_returnsFalseByDefault() {
        let coordinator = BindingListViewCoordinator()

        #expect(coordinator.hasSelection == false)
    }

    @Test func hasSelection_usesCallback() {
        let coordinator = BindingListViewCoordinator()
        coordinator.checkHasSelection = { true }

        #expect(coordinator.hasSelection == true)
    }

    @Test func hasSingleSelection_returnsFalseByDefault() {
        let coordinator = BindingListViewCoordinator()

        #expect(coordinator.hasSingleSelection == false)
    }

    @Test func hasSingleSelection_usesCallback() {
        let coordinator = BindingListViewCoordinator()
        coordinator.checkHasSingleSelection = { true }

        #expect(coordinator.hasSingleSelection == true)
    }

    @Test func hasFilter_returnsFalseByDefault() {
        let coordinator = BindingListViewCoordinator()

        #expect(coordinator.hasFilter == false)
    }

    @Test func hasFilter_usesCallback() {
        let coordinator = BindingListViewCoordinator()
        coordinator.checkHasFilter = { true }

        #expect(coordinator.hasFilter == true)
    }

    @Test func isListFocused_delegatesToFocusCoordinator() {
        let coordinator = BindingListViewCoordinator()

        // Without a key window, should return false
        #expect(coordinator.isListFocused == false)
    }

    // MARK: - Delegate Action Tests

    @Test func keyboardHandlerDidRequestAddItem_callsCallback() {
        let coordinator = BindingListViewCoordinator()
        var called = false
        coordinator.onAddItem = { called = true }

        coordinator.keyboardHandlerDidRequestAddItem()

        #expect(called == true)
    }

    @Test func keyboardHandlerDidRequestRemoveSelected_callsCallback() {
        let coordinator = BindingListViewCoordinator()
        var called = false
        coordinator.onRemoveSelected = { called = true }

        coordinator.keyboardHandlerDidRequestRemoveSelected()

        #expect(called == true)
    }

    @Test func keyboardHandlerDidRequestFocusSearch_callsCallback() {
        let coordinator = BindingListViewCoordinator()
        var called = false
        coordinator.onFocusSearch = { called = true }

        coordinator.keyboardHandlerDidRequestFocusSearch()

        #expect(called == true)
    }

    @Test func keyboardHandlerDidRequestActivateSelected_callsCallback() {
        let coordinator = BindingListViewCoordinator()
        var called = false
        coordinator.onActivateSelected = { called = true }

        coordinator.keyboardHandlerDidRequestActivateSelected()

        #expect(called == true)
    }

    @Test func keyboardHandlerDidRequestClearFilter_callsCallback() {
        let coordinator = BindingListViewCoordinator()
        var called = false
        coordinator.onClearFilter = { called = true }

        coordinator.keyboardHandlerDidRequestClearFilter()

        #expect(called == true)
    }

    // MARK: - Integration Tests

    @Test func keyboardHandler_usesCoordinatorAsDelegate() {
        let coordinator = BindingListViewCoordinator()
        coordinator.checkHasSelection = { true }
        coordinator.checkHasSingleSelection = { true }
        coordinator.checkHasFilter = { true }
        coordinator.start()

        // The keyboard handler should use the coordinator's state
        #expect(coordinator.keyboardHandler.canHandle(.addItem) == true)
        #expect(coordinator.keyboardHandler.canHandle(.focusSearch) == true)

        coordinator.stop()
    }
}
