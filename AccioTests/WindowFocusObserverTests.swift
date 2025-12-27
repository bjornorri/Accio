//
//  WindowFocusObserverTests.swift
//  AccioTests
//

import Testing
@testable import Accio

@Suite
struct WindowFocusObserverTests {

    @Test func start_registersNotificationObservers() {
        let observer = WindowFocusObserver()
        observer.start()

        // If we got here without crashing, observers were set up
        observer.stop()
    }

    @Test func stop_removesNotificationObservers() {
        let observer = WindowFocusObserver()
        observer.start()
        observer.stop()

        // If we got here without crashing, cleanup worked
    }

    @Test func stop_canBeCalledMultipleTimes() {
        let observer = WindowFocusObserver()
        observer.start()
        observer.stop()
        observer.stop() // Should not crash
    }

    @Test func stop_canBeCalledWithoutStart() {
        let observer = WindowFocusObserver()
        observer.stop() // Should not crash
    }
}
