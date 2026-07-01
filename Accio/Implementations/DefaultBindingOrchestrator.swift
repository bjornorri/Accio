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
/// Manages hotkey bindings and app groups by:
/// - Observing bindings and groups from Defaults
/// - Registering/unregistering hotkeys with HotkeyManager as they change
/// - Executing actions via ActionCoordinator when hotkeys are triggered
final class DefaultBindingOrchestrator: BindingOrchestrator {
    @Injected(\.hotkeyManager) private var hotkeyManager: HotkeyManager
    @Injected(\.actionCoordinator) private var actionCoordinator: ActionCoordinator
    @Injected(\.applicationManager) private var applicationManager: ApplicationManager

    private var cancellables = Set<AnyCancellable>()
    private var registeredShortcutNames: Set<String> = []

    func start() {
        registerAllBindings()
        registerAllGroups()

        Defaults.publisher(.hotkeyBindings)
            .sink { [weak self] change in
                self?.handleBindingsChange(oldBindings: change.oldValue, newBindings: change.newValue)
            }
            .store(in: &cancellables)

        Defaults.publisher(.appGroups)
            .sink { [weak self] change in
                self?.handleGroupsChange(oldGroups: change.oldValue, newGroups: change.newValue)
            }
            .store(in: &cancellables)
    }

    func stop() {
        cancellables.removeAll()
        unregisterAllShortcuts()
    }

    // MARK: - Bindings

    private func registerAllBindings() {
        for binding in Defaults[.hotkeyBindings] {
            registerBinding(binding)
        }
    }

    func handleBindingsChange(oldBindings: [HotkeyBinding], newBindings: [HotkeyBinding]) {
        let oldSet = Set(oldBindings.map(\.id))
        let newSet = Set(newBindings.map(\.id))

        for id in oldSet.subtracting(newSet) {
            if let binding = oldBindings.first(where: { $0.id == id }) {
                unregisterShortcut(name: binding.shortcutName)
            }
        }

        for id in newSet.subtracting(oldSet) {
            if let binding = newBindings.first(where: { $0.id == id }) {
                registerBinding(binding)
            }
        }

        for id in oldSet.intersection(newSet) {
            guard let oldBinding = oldBindings.first(where: { $0.id == id }),
                  let newBinding = newBindings.first(where: { $0.id == id }),
                  oldBinding != newBinding else { continue }
            unregisterShortcut(name: oldBinding.shortcutName)
            registerBinding(newBinding)
        }
    }

    private func registerBinding(_ binding: HotkeyBinding) {
        guard !binding.appBundleIdentifier.isEmpty else { return }
        guard !registeredShortcutNames.contains(binding.shortcutName) else { return }

        hotkeyManager.register(name: binding.shortcutName) { [weak self] in
            await self?.executeBinding(binding)
        }
        registeredShortcutNames.insert(binding.shortcutName)
    }

    private func executeBinding(_ binding: HotkeyBinding) async {
        let settings = Defaults[.appBehaviorSettings]
        await actionCoordinator.executeAction(for: binding.appBundleIdentifier, settings: settings)
    }

    // MARK: - Groups

    private func registerAllGroups() {
        for group in Defaults[.appGroups] {
            registerGroup(group)
        }
    }

    func handleGroupsChange(oldGroups: [AppGroup], newGroups: [AppGroup]) {
        let oldSet = Set(oldGroups.map(\.id))
        let newSet = Set(newGroups.map(\.id))

        for id in oldSet.subtracting(newSet) {
            if let group = oldGroups.first(where: { $0.id == id }) {
                unregisterShortcut(name: group.shortcutName)
            }
        }

        for id in newSet.subtracting(oldSet) {
            if let group = newGroups.first(where: { $0.id == id }) {
                registerGroup(group)
            }
        }

        for id in oldSet.intersection(newSet) {
            guard let oldGroup = oldGroups.first(where: { $0.id == id }),
                  let newGroup = newGroups.first(where: { $0.id == id }),
                  oldGroup != newGroup else { continue }
            // Re-register so handler closure captures updated group members
            unregisterShortcut(name: oldGroup.shortcutName)
            registerGroup(newGroup)
        }
    }

    private func registerGroup(_ group: AppGroup) {
        guard !registeredShortcutNames.contains(group.shortcutName) else { return }

        hotkeyManager.register(name: group.shortcutName) { [weak self] in
            await self?.executeGroup(group)
        }
        registeredShortcutNames.insert(group.shortcutName)
    }

    private func executeGroup(_ group: AppGroup) async {
        guard !group.members.isEmpty else { return }
        let settings = Defaults[.appBehaviorSettings]

        // Always reload group from store so member order reflects latest activations
        let currentGroup = Defaults[.appGroups].first(where: { $0.id == group.id }) ?? group

        let runningMembers = currentGroup.members.filter {
            applicationManager.isRunning(bundleIdentifier: $0.bundleIdentifier)
        }

        if runningMembers.count > 1,
           let focusedIndex = runningMembers.firstIndex(where: { applicationManager.isFocused(bundleIdentifier: $0.bundleIdentifier) }) {
            // Cycle to the next running member (going backward in recency to visit all members)
            let nextIndex = (focusedIndex - 1 + runningMembers.count) % runningMembers.count
            let nextMember = runningMembers[nextIndex]
            do {
                try applicationManager.activate(bundleIdentifier: nextMember.bundleIdentifier)
            } catch {
                print("Failed to cycle group member focus: \(error)")
            }
        } else if let firstRunning = runningMembers.first {
            await actionCoordinator.executeAction(for: firstRunning.bundleIdentifier, settings: settings)
        } else {
            switch settings.whenNotRunning {
            case .launchApp:
                if let firstMember = currentGroup.members.first {
                    await actionCoordinator.executeAction(for: firstMember.bundleIdentifier, settings: settings)
                }
            case .doNothing:
                break
            }
        }
    }

    // MARK: - Shared

    private func unregisterAllShortcuts() {
        for name in registeredShortcutNames {
            hotkeyManager.unregister(name: name)
        }
        registeredShortcutNames.removeAll()
    }

    private func unregisterShortcut(name: String) {
        hotkeyManager.unregister(name: name)
        registeredShortcutNames.remove(name)
    }

    // MARK: - Conflict Detection

    func findConflict(for shortcutName: String) -> ShortcutConflict? {
        guard let shortcut = KeyboardShortcuts.getShortcut(for: .init(shortcutName)) else { return nil }

        let bindings = Defaults[.hotkeyBindings]
        let groups = Defaults[.appGroups]

        let editedItem: ShortcutConflict.Item
        if let binding = bindings.first(where: { $0.shortcutName == shortcutName }) {
            editedItem = .binding(binding)
        } else if let group = groups.first(where: { $0.shortcutName == shortcutName }) {
            editedItem = .group(group)
        } else {
            return nil
        }

        for binding in bindings where binding.shortcutName != shortcutName {
            if KeyboardShortcuts.getShortcut(for: .init(binding.shortcutName)) == shortcut {
                return ShortcutConflict(editedItem: editedItem, conflictingItem: .binding(binding), shortcut: shortcut)
            }
        }

        for group in groups where group.shortcutName != shortcutName {
            if KeyboardShortcuts.getShortcut(for: .init(group.shortcutName)) == shortcut {
                return ShortcutConflict(editedItem: editedItem, conflictingItem: .group(group), shortcut: shortcut)
            }
        }

        return nil
    }

    func clearShortcut(for item: ShortcutConflict.Item) {
        KeyboardShortcuts.setShortcut(nil, for: .init(item.shortcutName))
    }
}
