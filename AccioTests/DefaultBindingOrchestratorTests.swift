//
//  DefaultBindingOrchestratorTests.swift
//  AccioTests
//

import FactoryKit
import FactoryTesting
import Foundation
import Testing
@testable import Accio

@Suite(.container, .serialized)
struct DefaultBindingOrchestratorTests {

    private func createOrchestrator() -> (DefaultBindingOrchestrator, MockHotkeyManager) {
        Container.shared.manager.reset(options: .all)

        let mockHotkeyManager = MockHotkeyManager()
        Container.shared.hotkeyManager.register { mockHotkeyManager }

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
}

// MARK: - Mock HotkeyManager

class MockHotkeyManager: HotkeyManager {
    var registeredNames: [String] = []
    var unregisteredNames: [String] = []
    var handlers: [String: () async -> Void] = [:]

    func register(name: String, handler: @escaping () async -> Void) {
        registeredNames.append(name)
        handlers[name] = handler
    }

    func unregister(name: String) {
        unregisteredNames.append(name)
        handlers.removeValue(forKey: name)
    }

    func unregisterAll() {
        unregisteredNames.append(contentsOf: handlers.keys)
        handlers.removeAll()
    }

    func pauseAll() {}

    func resumeAll() {}
}
