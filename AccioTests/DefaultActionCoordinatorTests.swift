//
//  DefaultActionCoordinatorTests.swift
//  AccioTests
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import FactoryKit
import FactoryTesting
import Testing
@testable import Accio

@Suite(.container, .serialized)
@MainActor
struct DefaultActionCoordinatorTests {

    private func resetAndRegisterMocks(
        isRunning: Bool = false,
        isFocused: Bool = false
    ) -> (MockApplicationManager, MockWindowCycler) {
        Container.shared.manager.reset(options: .all)

        let mockAppManager = MockApplicationManager(isRunning: isRunning, isFocused: isFocused)
        let mockWindowCycler = MockWindowCycler()

        Container.shared.applicationManager.register { mockAppManager }
        Container.shared.windowCycler.register { mockWindowCycler }
        Container.shared.actionCoordinator.register { DefaultActionCoordinator() }

        return (mockAppManager, mockWindowCycler)
    }

    // MARK: - When Not Running Tests

    @Test func whenNotRunning_launchApp_launchesTheApp() async {
        let (mockAppManager, _) = resetAndRegisterMocks(isRunning: false)

        let coordinator = Container.shared.actionCoordinator()
        let settings = AppBehaviorSettings(
            whenNotRunning: .launchApp,
            whenNotFocused: .focusApp,
            whenFocused: .cycleWindows        )

        await coordinator.executeAction(for: "com.apple.Safari", settings: settings)

        #expect(mockAppManager.launchCalls == ["com.apple.Safari"])
        #expect(mockAppManager.activateCalls.isEmpty)
        #expect(mockAppManager.hideCalls.isEmpty)
    }

    @Test func whenNotRunning_doNothing_doesNothing() async {
        let (mockAppManager, mockWindowCycler) = resetAndRegisterMocks(isRunning: false)

        let coordinator = Container.shared.actionCoordinator()
        let settings = AppBehaviorSettings(
            whenNotRunning: .doNothing,
            whenNotFocused: .focusApp,
            whenFocused: .cycleWindows        )

        await coordinator.executeAction(for: "com.apple.Safari", settings: settings)

        #expect(mockAppManager.launchCalls.isEmpty)
        #expect(mockAppManager.activateCalls.isEmpty)
        #expect(mockAppManager.hideCalls.isEmpty)
        #expect(mockWindowCycler.cycleWindowsCalls.isEmpty)
    }

    // MARK: - When Not Focused Tests

    @Test func whenNotFocused_focusApp_activatesTheApp() async {
        let (mockAppManager, _) = resetAndRegisterMocks(isRunning: true, isFocused: false)

        let coordinator = Container.shared.actionCoordinator()
        let settings = AppBehaviorSettings(
            whenNotRunning: .launchApp,
            whenNotFocused: .focusApp,
            whenFocused: .cycleWindows        )

        await coordinator.executeAction(for: "com.apple.Safari", settings: settings)

        #expect(mockAppManager.launchCalls.isEmpty)
        #expect(mockAppManager.activateCalls == ["com.apple.Safari"])
        #expect(mockAppManager.hideCalls.isEmpty)
    }

    @Test func whenNotFocused_doNothing_doesNothing() async {
        let (mockAppManager, mockWindowCycler) = resetAndRegisterMocks(isRunning: true, isFocused: false)

        let coordinator = Container.shared.actionCoordinator()
        let settings = AppBehaviorSettings(
            whenNotRunning: .launchApp,
            whenNotFocused: .doNothing,
            whenFocused: .cycleWindows        )

        await coordinator.executeAction(for: "com.apple.Safari", settings: settings)

        #expect(mockAppManager.launchCalls.isEmpty)
        #expect(mockAppManager.activateCalls.isEmpty)
        #expect(mockAppManager.hideCalls.isEmpty)
        #expect(mockWindowCycler.cycleWindowsCalls.isEmpty)
    }

    // MARK: - When Focused Tests

    @Test func whenFocused_cycleWindows_cyclesWindows() async {
        let (mockAppManager, mockWindowCycler) = resetAndRegisterMocks(isRunning: true, isFocused: true)

        let coordinator = Container.shared.actionCoordinator()
        let settings = AppBehaviorSettings(
            whenNotRunning: .launchApp,
            whenNotFocused: .focusApp,
            whenFocused: .cycleWindows        )

        await coordinator.executeAction(for: "com.apple.Safari", settings: settings)

        #expect(mockAppManager.launchCalls.isEmpty)
        #expect(mockAppManager.activateCalls.isEmpty)
        #expect(mockAppManager.hideCalls.isEmpty)
        #expect(mockWindowCycler.cycleWindowsCalls == ["com.apple.Safari"])
    }

    @Test func whenFocused_hideApp_hidesTheApp() async {
        let (mockAppManager, mockWindowCycler) = resetAndRegisterMocks(isRunning: true, isFocused: true)

        let coordinator = Container.shared.actionCoordinator()
        let settings = AppBehaviorSettings(
            whenNotRunning: .launchApp,
            whenNotFocused: .focusApp,
            whenFocused: .hideApp        )

        await coordinator.executeAction(for: "com.apple.Safari", settings: settings)

        #expect(mockAppManager.launchCalls.isEmpty)
        #expect(mockAppManager.activateCalls.isEmpty)
        #expect(mockAppManager.hideCalls == ["com.apple.Safari"])
        #expect(mockWindowCycler.cycleWindowsCalls.isEmpty)
    }

    @Test func whenFocused_doNothing_doesNothing() async {
        let (mockAppManager, mockWindowCycler) = resetAndRegisterMocks(isRunning: true, isFocused: true)

        let coordinator = Container.shared.actionCoordinator()
        let settings = AppBehaviorSettings(
            whenNotRunning: .launchApp,
            whenNotFocused: .focusApp,
            whenFocused: .doNothing        )

        await coordinator.executeAction(for: "com.apple.Safari", settings: settings)

        #expect(mockAppManager.launchCalls.isEmpty)
        #expect(mockAppManager.activateCalls.isEmpty)
        #expect(mockAppManager.hideCalls.isEmpty)
        #expect(mockWindowCycler.cycleWindowsCalls.isEmpty)
    }
}

// MARK: - Mock ApplicationManager

class MockApplicationManager: ApplicationManager {
    var isRunningValue: Bool
    var isFocusedValue: Bool

    var launchCalls: [String] = []
    var activateCalls: [String] = []
    var hideCalls: [String] = []

    init(isRunning: Bool = false, isFocused: Bool = false) {
        self.isRunningValue = isRunning
        self.isFocusedValue = isFocused
    }

    func launch(bundleIdentifier: String) async throws {
        launchCalls.append(bundleIdentifier)
    }

    func activate(bundleIdentifier: String) throws {
        activateCalls.append(bundleIdentifier)
    }

    func isRunning(bundleIdentifier: String) -> Bool {
        return isRunningValue
    }

    func isFocused(bundleIdentifier: String) -> Bool {
        return isFocusedValue
    }

    func hide(bundleIdentifier: String) throws {
        hideCalls.append(bundleIdentifier)
    }
}

// MARK: - Mock WindowCycler

class MockWindowCycler: WindowCycler {
    var cycleWindowsCalls: [String] = []

    func cycleWindows(for bundleIdentifier: String) throws {
        cycleWindowsCalls.append(bundleIdentifier)
    }
}
