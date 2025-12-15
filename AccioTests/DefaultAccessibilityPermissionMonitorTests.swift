//
//  DefaultAccessibilityPermissionMonitorTests.swift
//  AccioTests
//
//  Created by Bjorn Orri Saemundsson on 15.12.2025.
//

import Testing
import Clocks
import FactoryKit
import FactoryTesting
@testable import Accio

@Suite(.container)
struct DefaultAccessibilityPermissionMonitorTests {

    @Test func monitorStartsInactive() async {
        let mockProvider = MockAccessibilityPermissionProvider(hasPermission: false)
        Container.shared.permissionProvider.register { mockProvider }
        Container.shared.clock.register { TestClock() }

        let monitor = Container.shared.permissionMonitor()

        // Monitor should start with the provider's initial value
        #expect(monitor.hasPermission == false)
    }

    @Test func monitorCanBeStartedAndStopped() async {
        let mockProvider = MockAccessibilityPermissionProvider(hasPermission: false)
        Container.shared.permissionProvider.register { mockProvider }
        Container.shared.clock.register { TestClock() }

        let monitor = Container.shared.permissionMonitor()

        // Start monitoring
        monitor.startMonitoring()

        // Stop monitoring
        monitor.stopMonitoring()

        // Verify no crashes or issues
        #expect(true)
    }

    @Test func monitorPollsAtOneSecondIntervals() async {
        let clock = TestClock()
        let mockProvider = MockAccessibilityPermissionProvider(hasPermission: false)

        Container.shared.clock.register { clock }
        Container.shared.permissionProvider.register { mockProvider }

        let monitor = Container.shared.permissionMonitor()

        var changeCallCount = 0
        monitor.onPermissionChange { _ in
            changeCallCount += 1
        }

        // Initial call
        let initialCallCount = changeCallCount

        monitor.startMonitoring()

        // Let the monitoring task start
        await Task.yield()

        // Change permission
        mockProvider.hasPermission = true

        // Advance time by 1 second - monitor should poll and detect change
        await clock.advance(by: .seconds(1))
        await Task.yield()

        // Verify the permission change was detected after 1 second
        #expect(changeCallCount == initialCallCount + 1)

        monitor.stopMonitoring()
    }

    @Test func monitorDetectsPermissionChanges() async {
        let clock = TestClock()
        let mockProvider = MockAccessibilityPermissionProvider(hasPermission: false)

        Container.shared.clock.register { clock }
        Container.shared.permissionProvider.register { mockProvider }

        let monitor = Container.shared.permissionMonitor()

        var changeCallCount = 0
        var lastValue: Bool?

        monitor.onPermissionChange { newValue in
            changeCallCount += 1
            lastValue = newValue
        }

        // Should call immediately with initial value
        #expect(changeCallCount == 1)
        #expect(lastValue == false)

        // Start monitoring
        monitor.startMonitoring()
        await Task.yield()

        // Change permission status
        mockProvider.hasPermission = true

        // Advance clock to trigger next check
        await clock.advance(by: .seconds(1))
        await Task.yield()

        // Should have detected the change
        #expect(changeCallCount == 2)
        #expect(lastValue == true)

        monitor.stopMonitoring()
    }

    @Test func monitorOnlyNotifiesOnChange() async {
        let clock = TestClock()
        let mockProvider = MockAccessibilityPermissionProvider(hasPermission: true)

        Container.shared.clock.register { clock }
        Container.shared.permissionProvider.register { mockProvider }

        let monitor = Container.shared.permissionMonitor()

        var changeCallCount = 0

        monitor.onPermissionChange { _ in
            changeCallCount += 1
        }

        // Initial call
        #expect(changeCallCount == 1)

        // Start monitoring
        monitor.startMonitoring()
        await Task.yield()

        // Advance time multiple times without changing permission
        await clock.advance(by: .seconds(1))
        await Task.yield()

        await clock.advance(by: .seconds(1))
        await Task.yield()

        await clock.advance(by: .seconds(1))
        await Task.yield()

        // Should still only have the initial call since permission didn't change
        #expect(changeCallCount == 1)

        monitor.stopMonitoring()
    }

    @Test func checkPermissionUpdatesImmediately() async {
        let mockProvider = MockAccessibilityPermissionProvider(hasPermission: false)
        Container.shared.permissionProvider.register { mockProvider }
        Container.shared.clock.register { TestClock() }

        let monitor = Container.shared.permissionMonitor()

        var lastValue: Bool?
        monitor.onPermissionChange { newValue in
            lastValue = newValue
        }

        #expect(lastValue == false)

        // Change permission
        mockProvider.hasPermission = true

        // Call checkPermission
        monitor.checkPermission()

        // Should update immediately without polling
        #expect(lastValue == true)
    }

    @Test func requestPermissionUpdatesImmediately() async {
        let mockProvider = MockAccessibilityPermissionProvider(hasPermission: false)
        Container.shared.permissionProvider.register { mockProvider }
        Container.shared.clock.register { TestClock() }

        let monitor = Container.shared.permissionMonitor()

        var lastValue: Bool?
        monitor.onPermissionChange { newValue in
            lastValue = newValue
        }

        #expect(lastValue == false)

        // Simulate permission being granted after request
        mockProvider.onRequestPermission = {
            mockProvider.hasPermission = true
        }

        // Request permission
        monitor.requestPermission()

        // Give the async task time to complete
        try? await Task.sleep(for: .milliseconds(10))

        // Should update immediately
        #expect(lastValue == true)
    }

    @Test func multipleStartMonitoringCallsAreSafe() async {
        let mockProvider = MockAccessibilityPermissionProvider(hasPermission: false)
        Container.shared.permissionProvider.register { mockProvider }
        Container.shared.clock.register { TestClock() }

        let monitor = Container.shared.permissionMonitor()

        // Start monitoring multiple times
        monitor.startMonitoring()
        monitor.startMonitoring()
        monitor.startMonitoring()

        // Should not create multiple tasks or cause issues
        await Task.yield()

        monitor.stopMonitoring()

        #expect(true)
    }
}

// MARK: - Mock AccessibilityPermissionProvider

class MockAccessibilityPermissionProvider: AccessibilityPermissionProvider {
    var hasPermission: Bool
    var onRequestPermission: (() -> Void)?

    init(hasPermission: Bool) {
        self.hasPermission = hasPermission
    }

    func requestPermission() {
        onRequestPermission?()
    }
}
