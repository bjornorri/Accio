//
//  DefaultBindingOrchestratorTests.swift
//  AccioTests
//

import Defaults
import FactoryKit
import FactoryTesting
import Foundation
import Testing
@testable import Accio

@Suite(.container, .serialized)
@MainActor
struct DefaultBindingOrchestratorTests {

    private func createOrchestrator() -> (DefaultBindingOrchestrator, MockHotkeyManager) {
        Container.shared.manager.reset(options: .all)

        let mockHotkeyManager = MockHotkeyManager()
        Container.shared.hotkeyManager.register { mockHotkeyManager }

        let orchestrator = DefaultBindingOrchestrator()
        return (orchestrator, mockHotkeyManager)
    }

    private func createOrchestrator(
        appManager: ApplicationManager,
        actionCoordinator: ActionCoordinator
    ) -> (DefaultBindingOrchestrator, MockHotkeyManager) {
        Container.shared.manager.reset(options: .all)

        let mockHotkeyManager = MockHotkeyManager()
        Container.shared.hotkeyManager.register { mockHotkeyManager }
        Container.shared.applicationManager.register { appManager }
        Container.shared.actionCoordinator.register { actionCoordinator }

        let orchestrator = DefaultBindingOrchestrator()
        return (orchestrator, mockHotkeyManager)
    }

    // MARK: - Adding Bindings Tests

    @Test func addingBinding_registersHotkey() {
        let (orchestrator, mockHotkeyManager) = createOrchestrator()

        let binding = HotkeyBinding(shortcutName: "safari", appBundleIdentifier: "com.apple.Safari")

        orchestrator.handleBindingsChange(oldBindings: [], newBindings: [binding])

        #expect(mockHotkeyManager.registeredNames == ["safari"])
        #expect(mockHotkeyManager.unregisteredNames.isEmpty)
    }

    @Test func addingMultipleBindings_registersAllHotkeys() {
        let (orchestrator, mockHotkeyManager) = createOrchestrator()

        let binding1 = HotkeyBinding(shortcutName: "safari", appBundleIdentifier: "com.apple.Safari")
        let binding2 = HotkeyBinding(shortcutName: "chrome", appBundleIdentifier: "com.google.Chrome")

        orchestrator.handleBindingsChange(oldBindings: [], newBindings: [binding1, binding2])

        #expect(Set(mockHotkeyManager.registeredNames) == Set(["safari", "chrome"]))
    }

    @Test func addingBindingWithEmptyAppId_doesNotRegister() {
        let (orchestrator, mockHotkeyManager) = createOrchestrator()

        let binding = HotkeyBinding(shortcutName: "empty", appBundleIdentifier: "")

        orchestrator.handleBindingsChange(oldBindings: [], newBindings: [binding])

        #expect(mockHotkeyManager.registeredNames.isEmpty)
    }

    // MARK: - Removing Bindings Tests

    @Test func removingBinding_unregistersHotkey() {
        let (orchestrator, mockHotkeyManager) = createOrchestrator()

        let binding = HotkeyBinding(shortcutName: "safari", appBundleIdentifier: "com.apple.Safari")

        // First add the binding
        orchestrator.handleBindingsChange(oldBindings: [], newBindings: [binding])
        mockHotkeyManager.registeredNames.removeAll()

        // Then remove it
        orchestrator.handleBindingsChange(oldBindings: [binding], newBindings: [])

        #expect(mockHotkeyManager.unregisteredNames == ["safari"])
    }

    // MARK: - Modifying Bindings Tests

    @Test func modifyingBinding_unregistersOldAndRegistersNew() {
        let (orchestrator, mockHotkeyManager) = createOrchestrator()

        let bindingId = UUID()
        let oldBinding = HotkeyBinding(id: bindingId, shortcutName: "old", appBundleIdentifier: "com.old.App")
        let newBinding = HotkeyBinding(id: bindingId, shortcutName: "new", appBundleIdentifier: "com.new.App")

        // First add the old binding
        orchestrator.handleBindingsChange(oldBindings: [], newBindings: [oldBinding])
        mockHotkeyManager.registeredNames.removeAll()

        // Then modify it
        orchestrator.handleBindingsChange(oldBindings: [oldBinding], newBindings: [newBinding])

        #expect(mockHotkeyManager.unregisteredNames == ["old"])
        #expect(mockHotkeyManager.registeredNames == ["new"])
    }

    @Test func unchangedBinding_doesNotReregister() {
        let (orchestrator, mockHotkeyManager) = createOrchestrator()

        let binding = HotkeyBinding(shortcutName: "safari", appBundleIdentifier: "com.apple.Safari")

        // Add the binding
        orchestrator.handleBindingsChange(oldBindings: [], newBindings: [binding])
        mockHotkeyManager.registeredNames.removeAll()
        mockHotkeyManager.unregisteredNames.removeAll()

        // Same binding in both old and new
        orchestrator.handleBindingsChange(oldBindings: [binding], newBindings: [binding])

        #expect(mockHotkeyManager.registeredNames.isEmpty)
        #expect(mockHotkeyManager.unregisteredNames.isEmpty)
    }

    // MARK: - Duplicate Prevention Tests

    @Test func duplicateShortcutName_doesNotRegisterTwice() {
        let (orchestrator, mockHotkeyManager) = createOrchestrator()

        let binding = HotkeyBinding(shortcutName: "safari", appBundleIdentifier: "com.apple.Safari")

        // Add the same binding twice
        orchestrator.handleBindingsChange(oldBindings: [], newBindings: [binding])
        orchestrator.handleBindingsChange(oldBindings: [binding], newBindings: [binding])

        // Should only be registered once
        #expect(mockHotkeyManager.registeredNames == ["safari"])
    }

    // MARK: - App Group Execution Tests

    @Test func executeGroup_whenNoAppsRunning_executesActionOnFirstMember() async {
        let testAppManager = TestApplicationManager()
        let testActionCoordinator = TestActionCoordinator()
        let (orchestrator, mockHotkeyManager) = createOrchestrator(appManager: testAppManager, actionCoordinator: testActionCoordinator)
        
        let appA = AppGroupMember(bundleIdentifier: "com.app.A", appName: "App A")
        let appB = AppGroupMember(bundleIdentifier: "com.app.B", appName: "App B")
        let group = AppGroup(id: UUID(), name: "Test Group")
        var mutableGroup = group
        mutableGroup.members = [appA, appB]
        
        Defaults[.appGroups] = [mutableGroup]
        
        orchestrator.handleGroupsChange(oldGroups: [], newGroups: [mutableGroup])
        
        if let handler = mockHotkeyManager.handlers[mutableGroup.shortcutName] {
            await handler()
        }
        
        // Should execute action (launch) on the first member (App A)
        #expect(testActionCoordinator.executedCalls == ["com.app.A"])
        #expect(testAppManager.activateCalls.isEmpty)
    }

    @Test func executeGroup_whenOneAppRunningAndNotFocused_executesActionOnRunningApp() async {
        let testAppManager = TestApplicationManager()
        testAppManager.runningApps = ["com.app.B"]
        let testActionCoordinator = TestActionCoordinator()
        let (orchestrator, mockHotkeyManager) = createOrchestrator(appManager: testAppManager, actionCoordinator: testActionCoordinator)
        
        let appA = AppGroupMember(bundleIdentifier: "com.app.A", appName: "App A")
        let appB = AppGroupMember(bundleIdentifier: "com.app.B", appName: "App B")
        let group = AppGroup(id: UUID(), name: "Test Group")
        var mutableGroup = group
        mutableGroup.members = [appA, appB]
        
        Defaults[.appGroups] = [mutableGroup]
        
        orchestrator.handleGroupsChange(oldGroups: [], newGroups: [mutableGroup])
        
        if let handler = mockHotkeyManager.handlers[mutableGroup.shortcutName] {
            await handler()
        }
        
        // Should execute action on the running member (App B)
        #expect(testActionCoordinator.executedCalls == ["com.app.B"])
        #expect(testAppManager.activateCalls.isEmpty)
    }

    @Test func executeGroup_whenMultipleAppsRunningAndNoneFocused_executesActionOnFirstRunning() async {
        let testAppManager = TestApplicationManager()
        testAppManager.runningApps = ["com.app.A", "com.app.B"]
        let testActionCoordinator = TestActionCoordinator()
        let (orchestrator, mockHotkeyManager) = createOrchestrator(appManager: testAppManager, actionCoordinator: testActionCoordinator)
        
        let appA = AppGroupMember(bundleIdentifier: "com.app.A", appName: "App A")
        let appB = AppGroupMember(bundleIdentifier: "com.app.B", appName: "App B")
        let group = AppGroup(id: UUID(), name: "Test Group")
        var mutableGroup = group
        mutableGroup.members = [appA, appB]
        
        Defaults[.appGroups] = [mutableGroup]
        
        orchestrator.handleGroupsChange(oldGroups: [], newGroups: [mutableGroup])
        
        if let handler = mockHotkeyManager.handlers[mutableGroup.shortcutName] {
            await handler()
        }
        
        // Since none are focused, it should execute action on the first running app (App A)
        #expect(testActionCoordinator.executedCalls == ["com.app.A"])
        #expect(testAppManager.activateCalls.isEmpty)
    }

    @Test func executeGroup_whenMultipleAppsRunningAndOneFocused_cyclesToNext() async {
        let testAppManager = TestApplicationManager()
        testAppManager.runningApps = ["com.app.A", "com.app.B", "com.app.C"]
        let testActionCoordinator = TestActionCoordinator()
        let (orchestrator, mockHotkeyManager) = createOrchestrator(appManager: testAppManager, actionCoordinator: testActionCoordinator)
        
        let appA = AppGroupMember(bundleIdentifier: "com.app.A", appName: "App A")
        let appB = AppGroupMember(bundleIdentifier: "com.app.B", appName: "App B")
        let appC = AppGroupMember(bundleIdentifier: "com.app.C", appName: "App C")
        let group = AppGroup(id: UUID(), name: "Test Group")
        var mutableGroup = group
        mutableGroup.members = [appA, appB, appC]
        
        Defaults[.appGroups] = [mutableGroup]
        
        orchestrator.handleGroupsChange(oldGroups: [], newGroups: [mutableGroup])
        
        // Scenario 1: App A (index 0) is focused -> should cycle to App C (index 2)
        testAppManager.focusedApp = "com.app.A"
        testAppManager.activateCalls.removeAll()
        if let handler = mockHotkeyManager.handlers[mutableGroup.shortcutName] {
            await handler()
        }
        #expect(testActionCoordinator.executedCalls.isEmpty)
        #expect(testAppManager.activateCalls == ["com.app.C"])
        
        // Scenario 2: App B (index 1) is focused -> should cycle to App A (index 0)
        testAppManager.focusedApp = "com.app.B"
        testAppManager.activateCalls.removeAll()
        if let handler = mockHotkeyManager.handlers[mutableGroup.shortcutName] {
            await handler()
        }
        #expect(testActionCoordinator.executedCalls.isEmpty)
        #expect(testAppManager.activateCalls == ["com.app.A"])
        
        // Scenario 3: App C (index 2) is focused -> should cycle to App B (index 1)
        testAppManager.focusedApp = "com.app.C"
        testAppManager.activateCalls.removeAll()
        if let handler = mockHotkeyManager.handlers[mutableGroup.shortcutName] {
            await handler()
        }
        #expect(testActionCoordinator.executedCalls.isEmpty)
        #expect(testAppManager.activateCalls == ["com.app.B"])
    }
}

// MARK: - Test Helpers

private final class TestApplicationManager: ApplicationManager {
    var runningApps: Set<String> = []
    var focusedApp: String? = nil
    var activateCalls: [String] = []

    func launch(bundleIdentifier: String) async throws {
        runningApps.insert(bundleIdentifier)
    }

    func activate(bundleIdentifier: String) throws {
        activateCalls.append(bundleIdentifier)
        focusedApp = bundleIdentifier
    }

    func isRunning(bundleIdentifier: String) -> Bool {
        runningApps.contains(bundleIdentifier)
    }

    func isFocused(bundleIdentifier: String) -> Bool {
        focusedApp == bundleIdentifier
    }

    func hide(bundleIdentifier: String) throws {}

    func hasWindows(bundleIdentifier: String) -> Bool { true }
}

private final class TestActionCoordinator: ActionCoordinator {
    var executedCalls: [String] = []

    func executeAction(for bundleIdentifier: String, settings: AppBehaviorSettings) async {
        executedCalls.append(bundleIdentifier)
    }
}
