//
//  BindingListViewModel.swift
//  Accio
//

import AppKit
import Combine
import Defaults
import FactoryKit
import KeyboardShortcuts
import SwiftUI
import UniformTypeIdentifiers

@Observable
@MainActor
final class BindingListViewModel {
    // MARK: - Dependencies

    @ObservationIgnored
    @Injected(\.appMetadataProvider) private var appMetadataProvider

    @ObservationIgnored
    @Injected(\.hotkeyManager) private var hotkeyManager

    @ObservationIgnored
    @Injected(\.bindingOrchestrator) private var bindingOrchestrator

    @ObservationIgnored
    @Injected(\.bindingUndoManager) private var undoManager

    // MARK: - Published State

    var selection: Set<HotkeyBinding.ID> = []
    var searchText = ""
    var scrollToID: HotkeyBinding.ID?
    var activeRecorderID: HotkeyBinding.ID?

    // MARK: - Internal State

    private(set) var refreshTrigger = false
    private var recordingBindingID: HotkeyBinding.ID?
    private var previousShortcut: KeyboardShortcuts.Shortcut?

    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Bindings Access

    private(set) var bindings: [HotkeyBinding] = []

    init() {
        bindings = Defaults[.hotkeyBindings]
        Defaults.publisher(.hotkeyBindings)
            .sink { [weak self] change in
                Task { @MainActor in
                    self?.bindings = change.newValue
                }
            }
            .store(in: &cancellables)
    }

    private func updateBindings(_ newBindings: [HotkeyBinding]) {
        bindings = newBindings
        Defaults[.hotkeyBindings] = newBindings
    }

    var isEmpty: Bool {
        bindings.isEmpty
    }

    var filteredBindings: [HotkeyBinding] {
        let sorted = bindings.sorted { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter { $0.appName.localizedCaseInsensitiveContains(searchText) }
    }

    var hasSelection: Bool {
        !selection.isEmpty
    }

    // MARK: - Undo Manager

    func enableUndo() {
        undoManager.enable()
    }

    func disableUndo() {
        undoManager.disable()
    }

    var isUndoEnabled: Bool {
        undoManager.isEnabled
    }

    // MARK: - App Metadata

    func refreshMetadata() {
        updateAppMetadata()
        refreshTrigger.toggle()
    }

    private func updateAppMetadata() {
        var updated = false
        var updatedBindings = bindings

        for (index, binding) in updatedBindings.enumerated() {
            if let currentName = appMetadataProvider.appName(for: binding.appBundleIdentifier),
               binding.appName != currentName {
                updatedBindings[index] = HotkeyBinding(
                    id: binding.id,
                    shortcutName: binding.shortcutName,
                    appBundleIdentifier: binding.appBundleIdentifier,
                    appName: currentName
                )
                updated = true
            }
        }

        if updated {
            updateBindings(updatedBindings)
        }
    }

    // MARK: - Selection

    func handleListFocused() {
        let filteredIDs = Set(filteredBindings.map(\.id))
        let validSelection = selection.intersection(filteredIDs)

        if validSelection.isEmpty, let firstBinding = filteredBindings.first {
            selection = [firstBinding.id]
        } else if validSelection != selection {
            selection = validSelection
        }
    }

    // MARK: - Recorder

    func activateSelectedRecorder() {
        guard let selectedID = selection.first, selection.count == 1 else { return }
        activateRecorder(for: selectedID)
    }

    func activateRecorder(for bindingID: HotkeyBinding.ID) {
        activeRecorderID = bindingID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.activeRecorderID = nil
        }
    }

    func onRecorderActivated(for binding: HotkeyBinding) {
        hotkeyManager.pauseAll()
        selection = [binding.id]
        recordingBindingID = binding.id
        previousShortcut = KeyboardShortcuts.getShortcut(for: .init(binding.shortcutName))
    }

    func onRecorderDeactivated() {
        hotkeyManager.resumeAll()
        handleRecordingEnded()
    }

    private func handleRecordingEnded() {
        guard let bindingID = recordingBindingID,
              let binding = bindings.first(where: { $0.id == bindingID }) else { return }
        let savedPreviousShortcut = previousShortcut
        let editedName = KeyboardShortcuts.Name(binding.shortcutName)
        let newShortcut = KeyboardShortcuts.getShortcut(for: editedName)

        recordingBindingID = nil
        previousShortcut = nil

        guard newShortcut != savedPreviousShortcut else { return }

        if let conflict = bindingOrchestrator.findConflict(for: bindingID) {
            let alert = NSAlert()
            alert.messageText = "Shortcut Already in Use"
            alert.informativeText = "This shortcut is already assigned to \(conflict.conflictingBinding.appName). Do you want to reassign it to \(conflict.editedBinding.appName)?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Reassign")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()

            if response == .alertFirstButtonReturn {
                let conflictingName = KeyboardShortcuts.Name(conflict.conflictingBinding.shortcutName)
                let conflictingPreviousShortcut = KeyboardShortcuts.getShortcut(for: conflictingName)

                bindingOrchestrator.clearShortcut(for: conflict.conflictingBinding.id)

                undoManager.registerUndo { [self, binding, savedPreviousShortcut, conflict, conflictingPreviousShortcut] in
                    KeyboardShortcuts.setShortcut(savedPreviousShortcut, for: editedName)
                    if let conflictingPrevious = conflictingPreviousShortcut {
                        KeyboardShortcuts.setShortcut(conflictingPrevious, for: conflictingName)
                    }
                    registerRedoForShortcutChange(
                        binding: binding,
                        fromShortcut: savedPreviousShortcut,
                        toShortcut: newShortcut,
                        conflictingBinding: conflict.conflictingBinding,
                        conflictingPreviousShortcut: conflictingPreviousShortcut
                    )
                }
                undoManager.setActionName("Record Shortcut")
            } else {
                // User cancelled - revert to previous shortcut
                KeyboardShortcuts.setShortcut(savedPreviousShortcut, for: editedName)
            }
        } else {
            undoManager.registerUndo { [self, binding, savedPreviousShortcut, newShortcut] in
                KeyboardShortcuts.setShortcut(savedPreviousShortcut, for: editedName)
                registerRedoForShortcutChange(binding: binding, fromShortcut: savedPreviousShortcut, toShortcut: newShortcut, conflictingBinding: nil, conflictingPreviousShortcut: nil)
            }
            undoManager.setActionName("Record Shortcut")
        }
    }

    private func registerRedoForShortcutChange(
        binding: HotkeyBinding,
        fromShortcut: KeyboardShortcuts.Shortcut?,
        toShortcut: KeyboardShortcuts.Shortcut?,
        conflictingBinding: HotkeyBinding?,
        conflictingPreviousShortcut: KeyboardShortcuts.Shortcut?
    ) {
        let editedName = KeyboardShortcuts.Name(binding.shortcutName)
        undoManager.registerUndo { [self] in
            KeyboardShortcuts.setShortcut(toShortcut, for: editedName)
            if let conflicting = conflictingBinding {
                let conflictingName = KeyboardShortcuts.Name(conflicting.shortcutName)
                KeyboardShortcuts.setShortcut(nil, for: conflictingName)
            }
            undoManager.registerUndo { [self] in
                KeyboardShortcuts.setShortcut(fromShortcut, for: editedName)
                if let conflicting = conflictingBinding, let prevShortcut = conflictingPreviousShortcut {
                    let conflictingName = KeyboardShortcuts.Name(conflicting.shortcutName)
                    KeyboardShortcuts.setShortcut(prevShortcut, for: conflictingName)
                }
                registerRedoForShortcutChange(binding: binding, fromShortcut: fromShortcut, toShortcut: toShortcut, conflictingBinding: conflictingBinding, conflictingPreviousShortcut: conflictingPreviousShortcut)
            }
            undoManager.setActionName("Record Shortcut")
        }
        undoManager.setActionName("Record Shortcut")
    }

    // MARK: - Add Bindings

    func addBindingFromDrop(url: URL) {
        guard let bundle = Bundle(url: url),
              let bundleIdentifier = bundle.bundleIdentifier,
              !bindings.contains(where: { $0.appBundleIdentifier == bundleIdentifier }) else {
            return
        }

        let appName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent

        let id = UUID()
        let newBinding = HotkeyBinding(
            id: id,
            shortcutName: "binding-\(id.uuidString)",
            appBundleIdentifier: bundleIdentifier,
            appName: appName
        )
        updateBindings(bindings + [newBinding])
        selection = [id]
        scrollToID = id

        undoManager.registerUndo { [self, newBinding] in
            removeBindingsInternal([newBinding])
        }
        undoManager.setActionName("Add \(appName)")
    }

    func addBindingFromPanel() -> Bool {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Choose applications"
        panel.prompt = "Add"

        guard panel.runModal() == .OK else {
            return false
        }

        var newBindings: [HotkeyBinding] = []

        for url in panel.urls {
            guard let bundle = Bundle(url: url),
                  let bundleIdentifier = bundle.bundleIdentifier,
                  !bindings.contains(where: { $0.appBundleIdentifier == bundleIdentifier }),
                  !newBindings.contains(where: { $0.appBundleIdentifier == bundleIdentifier }) else {
                continue
            }

            let appName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? url.deletingPathExtension().lastPathComponent

            let id = UUID()
            let newBinding = HotkeyBinding(
                id: id,
                shortcutName: "binding-\(id.uuidString)",
                appBundleIdentifier: bundleIdentifier,
                appName: appName
            )
            newBindings.append(newBinding)
        }

        guard !newBindings.isEmpty else {
            return false
        }

        updateBindings(bindings + newBindings)

        if let firstID = newBindings.first?.id {
            selection = [firstID]
            scrollToID = firstID
        }

        let actionName = newBindings.count == 1
            ? "Add \(newBindings[0].appName)"
            : "Add \(newBindings.count) Shortcuts"
        undoManager.registerUndo { [self, newBindings] in
            removeBindingsInternal(newBindings)
        }
        undoManager.setActionName(actionName)

        return true
    }

    // MARK: - Remove Bindings

    func removeSelected() {
        guard !selection.isEmpty else { return }

        let currentList = filteredBindings
        let selectedIndices = selection.compactMap { id in
            currentList.firstIndex { $0.id == id }
        }.sorted()

        let nextSelectionID: HotkeyBinding.ID? = {
            guard let lastSelectedIndex = selectedIndices.last else { return nil }
            let remainingCount = currentList.count - selection.count
            guard remainingCount > 0 else { return nil }

            let nextIndex = lastSelectedIndex + 1
            if nextIndex < currentList.count {
                for i in nextIndex..<currentList.count {
                    let id = currentList[i].id
                    if !selection.contains(id) {
                        return id
                    }
                }
            }

            if let firstSelectedIndex = selectedIndices.first, firstSelectedIndex > 0 {
                for i in stride(from: firstSelectedIndex - 1, through: 0, by: -1) {
                    let id = currentList[i].id
                    if !selection.contains(id) {
                        return id
                    }
                }
            }

            return nil
        }()

        let removedBindings = bindings.filter { selection.contains($0.id) }
        var savedShortcuts: [HotkeyBinding.ID: KeyboardShortcuts.Shortcut] = [:]
        for binding in removedBindings {
            let name = KeyboardShortcuts.Name(binding.shortcutName)
            if let shortcut = KeyboardShortcuts.getShortcut(for: name) {
                savedShortcuts[binding.id] = shortcut
            }
        }

        for binding in removedBindings {
            let name = KeyboardShortcuts.Name(binding.shortcutName)
            KeyboardShortcuts.setShortcut(nil, for: name)
        }

        updateBindings(bindings.filter { !selection.contains($0.id) })

        if let nextID = nextSelectionID {
            selection = [nextID]
        } else {
            selection = []
        }

        let actionName = removedBindings.count == 1
            ? "Remove \(removedBindings[0].appName)"
            : "Remove \(removedBindings.count) Shortcuts"
        undoManager.registerUndo { [self, removedBindings, savedShortcuts] in
            addBindingsInternal(removedBindings, shortcuts: savedShortcuts)
        }
        undoManager.setActionName(actionName)
    }

    private func removeBindingsInternal(_ bindingsToRemove: [HotkeyBinding]) {
        let idsToRemove = Set(bindingsToRemove.map(\.id))

        for binding in bindingsToRemove {
            let name = KeyboardShortcuts.Name(binding.shortcutName)
            KeyboardShortcuts.setShortcut(nil, for: name)
        }

        updateBindings(bindings.filter { !idsToRemove.contains($0.id) })
        selection = selection.subtracting(idsToRemove)

        let actionName = bindingsToRemove.count == 1
            ? "Remove \(bindingsToRemove[0].appName)"
            : "Remove \(bindingsToRemove.count) Shortcuts"
        undoManager.registerUndo { [self, bindingsToRemove] in
            addBindingsInternal(bindingsToRemove, shortcuts: [:])
        }
        undoManager.setActionName(actionName)
    }

    private func addBindingsInternal(_ bindingsToAdd: [HotkeyBinding], shortcuts: [HotkeyBinding.ID: KeyboardShortcuts.Shortcut]) {
        let existingIDs = Set(bindings.map(\.id))
        let newBindings = bindingsToAdd.filter { !existingIDs.contains($0.id) }

        if !newBindings.isEmpty {
            updateBindings(bindings + newBindings)
        }

        for (id, shortcut) in shortcuts {
            if let binding = bindingsToAdd.first(where: { $0.id == id }) {
                let name = KeyboardShortcuts.Name(binding.shortcutName)
                KeyboardShortcuts.setShortcut(shortcut, for: name)
            }
        }

        if let firstID = bindingsToAdd.first?.id {
            selection = [firstID]
            scrollToID = firstID
        }

        let actionName = bindingsToAdd.count == 1
            ? "Add \(bindingsToAdd[0].appName)"
            : "Add \(bindingsToAdd.count) Shortcuts"
        undoManager.registerUndo { [self, bindingsToAdd] in
            removeBindingsInternal(bindingsToAdd)
        }
        undoManager.setActionName(actionName)
    }
}
