//
//  DefaultBindingOrchestrator.swift
//  Accio
//

import Combine
import Defaults
import FactoryKit
import Foundation
import KeyboardShortcuts

/// Default implementation of BindingOrchestrator
///
/// Manages hotkey bindings by:
/// - Observing hotkey bindings from Defaults
/// - Registering/unregistering hotkeys with HotkeyManager as bindings change
/// - Executing actions via ActionCoordinator when hotkeys are triggered
final class DefaultBindingOrchestrator: BindingOrchestrator {
    @Injected(\.hotkeyManager) private var hotkeyManager: HotkeyManager
    @Injected(\.actionCoordinator) private var actionCoordinator: ActionCoordinator

    private var cancellables = Set<AnyCancellable>()
    private var registeredBindings: Set<String> = []

    func start() {
        // Register all existing bindings
        registerAllBindings()

        // Observe changes to bindings
        Defaults.publisher(.hotkeyBindings)
            .sink { [weak self] change in
                self?.handleBindingsChange(oldBindings: change.oldValue, newBindings: change.newValue)
            }
            .store(in: &cancellables)
    }

    func stop() {
        cancellables.removeAll()
        unregisterAllBindings()
    }

    // MARK: - Private Methods

    /// Register all current bindings from Defaults
    private func registerAllBindings() {
        let bindings = Defaults[.hotkeyBindings]
        for binding in bindings {
            registerBinding(binding)
        }
    }

    /// Unregister all currently registered bindings
    private func unregisterAllBindings() {
        for shortcutName in registeredBindings {
            hotkeyManager.unregister(name: shortcutName)
        }
        registeredBindings.removeAll()
    }

    /// Handle changes to the bindings array
    func handleBindingsChange(oldBindings: [HotkeyBinding], newBindings: [HotkeyBinding]) {
        let oldSet = Set(oldBindings.map(\.id))
        let newSet = Set(newBindings.map(\.id))

        // Find removed bindings
        let removedIds = oldSet.subtracting(newSet)
        for id in removedIds {
            if let binding = oldBindings.first(where: { $0.id == id }) {
                unregisterBinding(binding)
            }
        }

        // Find added bindings
        let addedIds = newSet.subtracting(oldSet)
        for id in addedIds {
            if let binding = newBindings.first(where: { $0.id == id }) {
                registerBinding(binding)
            }
        }

        // Handle modified bindings (same ID but different shortcut or app)
        let commonIds = oldSet.intersection(newSet)
        for id in commonIds {
            guard let oldBinding = oldBindings.first(where: { $0.id == id }),
                  let newBinding = newBindings.first(where: { $0.id == id }) else {
                continue
            }

            if oldBinding != newBinding {
                unregisterBinding(oldBinding)
                registerBinding(newBinding)
            }
        }
    }

    /// Register a single binding with the hotkey manager
    private func registerBinding(_ binding: HotkeyBinding) {
        // Only register bindings that have an app selected
        guard !binding.appBundleIdentifier.isEmpty else { return }
        guard !registeredBindings.contains(binding.shortcutName) else { return }

        hotkeyManager.register(name: binding.shortcutName) { [weak self] in
            await self?.executeBinding(binding)
        }

        registeredBindings.insert(binding.shortcutName)
    }

    /// Unregister a single binding from the hotkey manager
    private func unregisterBinding(_ binding: HotkeyBinding) {
        hotkeyManager.unregister(name: binding.shortcutName)
        registeredBindings.remove(binding.shortcutName)
    }

    /// Execute the action for a binding when its hotkey is triggered
    private func executeBinding(_ binding: HotkeyBinding) async {
        let settings = Defaults[.appBehaviorSettings]
        await actionCoordinator.executeAction(for: binding.appBundleIdentifier, settings: settings)
    }

    // MARK: - Conflict Detection

    func findConflict(for bindingId: HotkeyBinding.ID) -> ShortcutConflict? {
        let bindings = Defaults[.hotkeyBindings]

        guard let editedBinding = bindings.first(where: { $0.id == bindingId }),
              let recordedShortcut = KeyboardShortcuts.getShortcut(for: .init(editedBinding.shortcutName)) else {
            return nil
        }

        for other in bindings where other.id != bindingId {
            if KeyboardShortcuts.getShortcut(for: .init(other.shortcutName)) == recordedShortcut {
                return ShortcutConflict(
                    editedBinding: editedBinding,
                    conflictingBinding: other,
                    shortcut: recordedShortcut
                )
            }
        }

        return nil
    }

    func clearShortcut(for bindingId: HotkeyBinding.ID) {
        let bindings = Defaults[.hotkeyBindings]
        if let binding = bindings.first(where: { $0.id == bindingId }) {
            KeyboardShortcuts.setShortcut(nil, for: .init(binding.shortcutName))
        }
    }
}
