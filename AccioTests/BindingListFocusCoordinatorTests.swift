//
//  BindingListFocusCoordinatorTests.swift
//  AccioTests
//

import Testing
@testable import Accio

@Suite
@MainActor
struct BindingListFocusCoordinatorTests {

    @Test func start_startsInternalObservers() {
        let coordinator = BindingListFocusCoordinator()
        coordinator.start()

        // If we got here without crashing, observers were started
        coordinator.stop()
    }

    @Test func stop_stopsInternalObservers() {
        let coordinator = BindingListFocusCoordinator()
        coordinator.start()
        coordinator.stop()

        // If we got here without crashing, cleanup worked
    }

    @Test func stop_canBeCalledMultipleTimes() {
        let coordinator = BindingListFocusCoordinator()
        coordinator.start()
        coordinator.stop()
        coordinator.stop() // Should not crash
    }

    @Test func clearSavedState_doesNotCrash() {
        let coordinator = BindingListFocusCoordinator()
        coordinator.start()
        coordinator.clearSavedState()
        coordinator.stop()
    }

    @Test func onListFocused_canBeSet() {
        let coordinator = BindingListFocusCoordinator()
        var called = false

        coordinator.onListFocused = {
            called = true
        }

        // Callback is set but not invoked automatically
        #expect(called == false)
    }

    @Test func isSearchFocused_canBeSet() {
        let coordinator = BindingListFocusCoordinator()

        coordinator.isSearchFocused = { true }

        #expect(coordinator.isSearchFocused?() == true)
    }

    @Test func setSearchFocused_canBeSet() {
        let coordinator = BindingListFocusCoordinator()
        var focusValue = false

        coordinator.setSearchFocused = { value in
            focusValue = value
        }

        coordinator.setSearchFocused?(true)
        #expect(focusValue == true)
    }

}
