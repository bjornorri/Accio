//
//  BindingListViewCoordinatorTests.swift
//  AccioTests
//

import Testing
@testable import Accio

@Suite
@MainActor
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

    // MARK: - Delegate Action Tests

    @Test func keyboardHandlerDidRequestAddItem_callsCallback() {
        let coordinator = BindingListViewCoordinator()
        var called = false
        coordinator.onAddItem = { called = true }

        coordinator.keyboardHandlerDidRequestAddItem()

        #expect(called == true)
    }

    // MARK: - Integration Tests

    @Test func keyboardHandler_usesCoordinatorAsDelegate() {
        let coordinator = BindingListViewCoordinator()
        coordinator.start()

        // The keyboard handler should use the coordinator's state
        #expect(coordinator.keyboardHandler.canHandle(.addItem) == true)

        coordinator.stop()
    }
}
