//
//  MockAccessibilityPermissionMonitor.swift
//  AccioTests
//
//  Created by Bjorn Orri Saemundsson on 15.12.2025.
//

import Foundation
@testable import Accio

/// Mock implementation for testing
class MockAccessibilityPermissionMonitor: AccessibilityPermissionMonitor {

    // MARK: - Properties

    private var onChange: ((Bool) -> Void)?
    private(set) var hasPermission: Bool

    // MARK: - Call Tracking

    private(set) var requestPermissionCalled = false
    private(set) var checkPermissionCalled = false
    private(set) var startMonitoringCalled = false
    private(set) var stopMonitoringCalled = false

    // MARK: - Initialization

    /// Initialize with configurable permission state
    /// - Parameter hasPermission: Initial permission state (defaults to false)
    init(hasPermission: Bool = false) {
        self.hasPermission = hasPermission
    }

    // MARK: - Protocol Methods

    func onPermissionChange(_ onChange: @escaping (Bool) -> Void) {
        self.onChange = onChange
        // Immediately call with current value
        onChange(hasPermission)
    }

    func requestPermission() {
        requestPermissionCalled = true
    }

    func checkPermission() {
        checkPermissionCalled = true
    }

    func startMonitoring() {
        startMonitoringCalled = true
    }

    func stopMonitoring() {
        stopMonitoringCalled = true
    }

    // MARK: - Test Helpers

    /// Simulate permission being granted or revoked
    /// - Parameter newValue: New permission status
    func simulatePermissionChange(_ newValue: Bool) {
        hasPermission = newValue
        onChange?(newValue)
    }

    /// Reset all call tracking flags
    func reset() {
        requestPermissionCalled = false
        checkPermissionCalled = false
        startMonitoringCalled = false
        stopMonitoringCalled = false
    }
}
