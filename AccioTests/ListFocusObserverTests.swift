//
//  ListFocusObserverTests.swift
//  AccioTests
//

import Testing
@testable import Accio

@Suite
struct ListFocusObserverTests {

    @Test func init_setsCallback() {
        var callbackInvoked = false
        let observer = ListFocusObserver {
            callbackInvoked = true
        }

        // The callback shouldn't be invoked during init
        #expect(callbackInvoked == false)
        _ = observer // Silence unused variable warning
    }

    @Test func start_registersNotificationObserver() {
        let observer = ListFocusObserver {}
        observer.start()

        // If we got here without crashing, the observer was set up
        observer.stop()
    }

    @Test func stop_removesNotificationObserver() {
        let observer = ListFocusObserver {}
        observer.start()
        observer.stop()

        // If we got here without crashing, cleanup worked
    }

    @Test func stop_canBeCalledMultipleTimes() {
        let observer = ListFocusObserver {}
        observer.start()
        observer.stop()
        observer.stop() // Should not crash

        // If we got here without crashing, multiple stops are safe
    }

    @Test func stop_canBeCalledWithoutStart() {
        let observer = ListFocusObserver {}
        observer.stop() // Should not crash

        // If we got here without crashing, stop without start is safe
    }
}
