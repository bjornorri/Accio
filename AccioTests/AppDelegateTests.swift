//
//  AppDelegateTests.swift
//  AccioTests
//

import AppKit
import FactoryKit
import FactoryTesting
import Testing
@testable import Accio

@Suite(.container, .serialized)
@MainActor
struct AppDelegateTests {

    @Test func applicationDidFinishLaunching_savesVersionAndBuildNumber() {
        // Arrange
        Container.shared.manager.reset(options: .all)

        let mockAppInfo = MockAppInfoProvider(version: "1.2.3", buildNumber: "42")
        let mockAppSettings = MockAppSettingsStore()
        let mockBindingStore = MockBindingStore(bindings: [])
        let mockOrchestrator = MockBindingOrchestrator()
        let mockWindowManager = MockWindowManager()

        Container.shared.appInfoProvider.register { mockAppInfo }
        Container.shared.appSettingsStore.register { mockAppSettings }
        Container.shared.bindingStore.register { mockBindingStore }
        Container.shared.bindingOrchestrator.register { mockOrchestrator }
        Container.shared.windowManager.register { mockWindowManager }

        let appDelegate = AppDelegate()

        // Act
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        // Assert
        #expect(mockAppSettings.lastKnownAppVersion == "1.2.3")
        #expect(mockAppSettings.lastKnownBuildNumber == "42")
    }

    @Test func applicationDidFinishLaunching_handlesNilVersion() {
        // Arrange
        Container.shared.manager.reset(options: .all)

        let mockAppInfo = MockAppInfoProvider(version: nil, buildNumber: nil)
        let mockAppSettings = MockAppSettingsStore()
        let mockBindingStore = MockBindingStore(bindings: [])
        let mockOrchestrator = MockBindingOrchestrator()
        let mockWindowManager = MockWindowManager()

        Container.shared.appInfoProvider.register { mockAppInfo }
        Container.shared.appSettingsStore.register { mockAppSettings }
        Container.shared.bindingStore.register { mockBindingStore }
        Container.shared.bindingOrchestrator.register { mockOrchestrator }
        Container.shared.windowManager.register { mockWindowManager }

        let appDelegate = AppDelegate()

        // Act
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        // Assert
        #expect(mockAppSettings.lastKnownAppVersion == nil)
        #expect(mockAppSettings.lastKnownBuildNumber == nil)
    }
}

// MARK: - Mock WindowManager

private final class MockWindowManager: WindowManager {
    func showSettings() {}
}
