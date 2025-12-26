//
//  DefaultActionCoordinatorTests.swift
//  AccioTests
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import AppKit
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
    ) -> (MockApplicationManager, MockWindowCycler, MockNotificationPoster) {
        Container.shared.manager.reset(options: .all)

        let mockAppManager = MockApplicationManager(isRunning: isRunning, isFocused: isFocused)
        let mockWindowCycler = MockWindowCycler()
        let mockNotificationPoster = MockNotificationPoster()
        let mockAppMetadataProvider = MockAppMetadataProvider()

        Container.shared.applicationManager.register { mockAppManager }
        Container.shared.windowCycler.register { mockWindowCycler }
        Container.shared.notificationPoster.register { mockNotificationPoster }
        Container.shared.appMetadataProvider.register { mockAppMetadataProvider }
        Container.shared.actionCoordinator.register { DefaultActionCoordinator() }

        return (mockAppManager, mockWindowCycler, mockNotificationPoster)
    }

    // MARK: - When Not Running Tests

    @Test func whenNotRunning_launchApp_launchesTheApp() async {
        let (mockAppManager, _, _) = resetAndRegisterMocks(isRunning: false)

        let coordinator = Container.shared.actionCoordinator()
        let settings = AppBehaviorSettings(
            whenNotRunning: .launchApp,
            whenNotFocused: .focusApp,
            whenFocused: .cycleWindows
        )

        await coordinator.executeAction(for: "com.apple.Safari", settings: settings)

        #expect(mockAppManager.launchCalls == ["com.apple.Safari"])
        #expect(mockAppManager.activateCalls.isEmpty)
        #expect(mockAppManager.hideCalls.isEmpty)
    }

    @Test func whenNotRunning_launchApp_postsNotification() async {
        let (_, _, mockNotificationPoster) = resetAndRegisterMocks(isRunning: false)

        let coordinator = Container.shared.actionCoordinator()
        let settings = AppBehaviorSettings(
            whenNotRunning: .launchApp,
            whenNotFocused: .focusApp,
            whenFocused: .cycleWindows
        )

        await coordinator.executeAction(for: "com.apple.Safari", settings: settings)

        #expect(mockNotificationPoster.postCalls.count == 1)
        #expect(mockNotificationPoster.postCalls.first?.appName == "Test App")
    }

    @Test func whenNotRunning_doNothing_doesNothing() async {
        let (mockAppManager, mockWindowCycler, mockNotificationPoster) = resetAndRegisterMocks(isRunning: false)

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
        #expect(mockNotificationPoster.postCalls.isEmpty)
    }

    // MARK: - When Not Focused Tests

    @Test func whenNotFocused_focusApp_activatesTheApp() async {
        let (mockAppManager, _, mockNotificationPoster) = resetAndRegisterMocks(isRunning: true, isFocused: false)

        let coordinator = Container.shared.actionCoordinator()
        let settings = AppBehaviorSettings(
            whenNotRunning: .launchApp,
            whenNotFocused: .focusApp,
            whenFocused: .cycleWindows        )

        await coordinator.executeAction(for: "com.apple.Safari", settings: settings)

        #expect(mockAppManager.launchCalls.isEmpty)
        #expect(mockAppManager.activateCalls == ["com.apple.Safari"])
        #expect(mockAppManager.hideCalls.isEmpty)
        #expect(mockNotificationPoster.postCalls.isEmpty)
    }

    @Test func whenNotFocused_doNothing_doesNothing() async {
        let (mockAppManager, mockWindowCycler, mockNotificationPoster) = resetAndRegisterMocks(isRunning: true, isFocused: false)

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
        #expect(mockNotificationPoster.postCalls.isEmpty)
    }

    // MARK: - When Focused Tests

    @Test func whenFocused_cycleWindows_cyclesWindows() async {
        let (mockAppManager, mockWindowCycler, mockNotificationPoster) = resetAndRegisterMocks(isRunning: true, isFocused: true)

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
        #expect(mockNotificationPoster.postCalls.isEmpty)
    }

    @Test func whenFocused_hideApp_hidesTheApp() async {
        let (mockAppManager, mockWindowCycler, mockNotificationPoster) = resetAndRegisterMocks(isRunning: true, isFocused: true)

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
        #expect(mockNotificationPoster.postCalls.isEmpty)
    }

    @Test func whenFocused_doNothing_doesNothing() async {
        let (mockAppManager, mockWindowCycler, mockNotificationPoster) = resetAndRegisterMocks(isRunning: true, isFocused: true)

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
        #expect(mockNotificationPoster.postCalls.isEmpty)
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

// MARK: - Mock NotificationPoster

class MockNotificationPoster: NotificationPoster {
    var postCalls: [(appName: String, icon: NSImage?)] = []

    func postAppLaunchingNotification(appName: String, icon: NSImage?) {
        postCalls.append((appName: appName, icon: icon))
    }
}

// MARK: - Mock AppMetadataProvider

class MockAppMetadataProvider: AppMetadataProvider {
    func appName(for bundleIdentifier: String) -> String? {
        return "Test App"
    }

    func appIcon(for bundleIdentifier: String) -> NSImage? {
        return nil
    }

    func appURL(for bundleIdentifier: String) -> URL? {
        return nil
    }

    func isInstalled(_ bundleIdentifier: String) -> Bool {
        return true
    }
}
