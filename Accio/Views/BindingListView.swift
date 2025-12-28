//
//  BindingListView.swift
//  Accio
//

import AppKit
import Defaults
import FactoryKit
import KeyboardShortcuts
import SwiftUI
import UniformTypeIdentifiers

/// A view displaying hotkey bindings in macOS Settings style
struct BindingListView: View {
    @Injected(\.appMetadataProvider) private var appMetadataProvider
    @Injected(\.hotkeyManager) private var hotkeyManager
    @Injected(\.bindingOrchestrator) private var bindingOrchestrator
    @Injected(\.bindingUndoManager) private var undoManager
    @Default(.hotkeyBindings) private var bindings
    @State private var selection: Set<HotkeyBinding.ID> = []
    @State private var searchText = ""
    @State private var refreshTrigger = false
    @State private var activeRecorderID: HotkeyBinding.ID?
    @State private var coordinator: BindingListViewCoordinator?
    @State private var recordingBindingID: HotkeyBinding.ID?
    @State private var previousShortcut: KeyboardShortcuts.Shortcut?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        Group {
            if bindings.isEmpty {
                emptyStateView
            } else {
                bindingsList
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        listToolbar
                    }
            }
        }
        .frame(maxWidth: 800)
        .frame(maxWidth: .infinity)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            updateAppMetadata()
            refreshTrigger.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .performFind)) { _ in
            guard undoManager.isEnabled else { return }
            isSearchFocused = true
        }
        .onAppear {
            undoManager.enable()
            setupCoordinator()
        }
        .onDisappear {
            undoManager.disable()
            coordinator?.stop()
            coordinator = nil
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    // MARK: - Setup

    private func setupCoordinator() {
        let newCoordinator = BindingListViewCoordinator()

        // Configure focus coordinator
        newCoordinator.focusCoordinator.onListFocused = { [self] in
            handleListFocused()
        }
        newCoordinator.focusCoordinator.isSearchFocused = { [self] in
            isSearchFocused
        }
        newCoordinator.focusCoordinator.setSearchFocused = { [self] focused in
            isSearchFocused = focused
        }

        // Configure state callbacks
        newCoordinator.checkHasSelection = { [self] in !selection.isEmpty }
        newCoordinator.checkHasSingleSelection = { [self] in selection.count == 1 }
        newCoordinator.checkHasFilter = { [self] in !searchText.isEmpty }

        // Configure action callbacks
        newCoordinator.onAddItem = { [self] in addBinding() }
        newCoordinator.onRemoveSelected = { [self] in removeSelected() }
        newCoordinator.onFocusSearch = { [self] in isSearchFocused = true }
        newCoordinator.onActivateSelected = { [self] in activateSelectedRecorder() }
        newCoordinator.onClearFilter = { [self] in searchText = "" }

        newCoordinator.start()
        coordinator = newCoordinator
    }

    private func handleListFocused() {
        let filteredIDs = Set(filteredBindings.map(\.id))
        let validSelection = selection.intersection(filteredIDs)

        if validSelection.isEmpty, let firstBinding = filteredBindings.first {
            selection = [firstBinding.id]
        } else if validSelection != selection {
            selection = validSelection
        }
    }

    private func activateSelectedRecorder() {
        guard let selectedID = selection.first, selection.count == 1 else { return }
        activateRecorder(for: selectedID)
    }

    private func activateRecorder(for bindingID: HotkeyBinding.ID) {
        activeRecorderID = bindingID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            activeRecorderID = nil
        }
    }

    // MARK: - Drag and Drop

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      url.pathExtension == "app" else {
                    return
                }
                DispatchQueue.main.async {
                    addBindingForApp(at: url)
                }
            }
        }
    }

    private func addBindingForApp(at url: URL) {
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
        bindings.append(newBinding)
        selection = [id]

        undoManager.registerUndo { [self, newBinding] in
            removeBindings([newBinding])
        }
        undoManager.setActionName("Add \(appName)")
    }

    // MARK: - App Metadata

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
            bindings = updatedBindings
        }
    }

    // MARK: - Computed Properties

    private var filteredBindings: [HotkeyBinding] {
        let sorted = bindings.sorted { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter { $0.appName.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Views

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Shortcuts", systemImage: "keyboard")
        } description: {
            Text("Press \(Image(systemName: "command"))N to add an application shortcut\nor drag apps here")
        } actions: {
            Button("Add Shortcut") {
                addBinding()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listToolbar: some View {
        HStack(spacing: 8) {
            Button {
                addBinding()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)

            Button {
                removeSelected()
            } label: {
                Image(systemName: "minus")
            }
            .buttonStyle(.borderless)
            .disabled(selection.isEmpty)

            Spacer()
        }
        .frame(maxWidth: 800)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(.bar)
    }

    private var bindingsList: some View {
        ScrollViewReader { _ in
            List(selection: $selection) {
                ForEach(filteredBindings) { binding in
                    BindingRowView(
                        binding: binding,
                        appMetadataProvider: appMetadataProvider,
                        refreshTrigger: refreshTrigger,
                        shouldActivateRecorder: binding.id == activeRecorderID,
                        onRecorderActivated: { [self] in
                            hotkeyManager.pauseAll()
                            selection = [binding.id]
                            recordingBindingID = binding.id
                            previousShortcut = KeyboardShortcuts.getShortcut(
                                for: .init(binding.shortcutName)
                            )
                        },
                        onRecorderDeactivated: { [self] in
                            hotkeyManager.resumeAll()
                            handleRecordingEnded()
                            coordinator?.focusCoordinator.focusList()
                        }
                    )
                    .tag(binding.id)
                    .id(binding.id)
                    .selectOnRightClick(id: binding.id, selection: $selection) {
                        coordinator?.focusCoordinator.focusList()
                    }
                    .contextMenu {
                        Button("Record Shortcut") {
                            activateRecorder(for: binding.id)
                        }
                        Divider()
                        Button("Remove", role: .destructive) {
                            removeSelected()
                        }
                    }
                }
            }
            .listStyle(.inset)
            .alternatingRowBackgrounds()
            .environment(\.defaultMinListRowHeight, 40)
            .searchable(text: $searchText, placement: .toolbar)
            .searchFocused($isSearchFocused)
            .onChange(of: isSearchFocused) { _, isFocused in
                if !isFocused {
                    coordinator?.focusCoordinator.handleSearchFocusLost()
                }
            }
        }
    }

    // MARK: - Actions

    private func handleRecordingEnded() {
        guard let bindingID = recordingBindingID,
              let binding = bindings.first(where: { $0.id == bindingID }) else { return }
        let savedPreviousShortcut = previousShortcut
        let editedName = KeyboardShortcuts.Name(binding.shortcutName)
        let newShortcut = KeyboardShortcuts.getShortcut(for: editedName)

        recordingBindingID = nil
        previousShortcut = nil

        // Check if shortcut actually changed
        guard newShortcut != savedPreviousShortcut else { return }

        // Check for conflicts
        if let conflict = bindingOrchestrator.findConflict(for: bindingID) {
            // Restore previous shortcut before showing dialog so UI doesn't change prematurely
            KeyboardShortcuts.setShortcut(savedPreviousShortcut, for: editedName)

            let alert = NSAlert()
            alert.messageText = "Shortcut Already in Use"
            alert.informativeText = "This shortcut is already assigned to \(conflict.conflictingBinding.appName). Do you want to reassign it to \(conflict.editedBinding.appName)?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Reassign")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()

            if response == .alertFirstButtonReturn {
                // Reassign: apply the new shortcut and clear it from the conflicting binding
                let conflictingName = KeyboardShortcuts.Name(conflict.conflictingBinding.shortcutName)
                let conflictingPreviousShortcut = KeyboardShortcuts.getShortcut(for: conflictingName)

                KeyboardShortcuts.setShortcut(newShortcut, for: editedName)
                bindingOrchestrator.clearShortcut(for: conflict.conflictingBinding.id)

                // Register undo for both changes
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
            }
            // If cancelled, previous shortcut is already restored, nothing to undo
        } else {
            // No conflict - register undo for the shortcut change
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
            // Register undo again for the next undo
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

    private func addBinding() {
        let wasSearchFocused = isSearchFocused
        let wasListFocused = coordinator?.focusCoordinator.isListFocused() ?? false

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Choose applications"
        panel.prompt = "Add"

        if panel.runModal() == .OK {
            var addedIDs: [HotkeyBinding.ID] = []

            for url in panel.urls {
                guard let bundle = Bundle(url: url),
                      let bundleIdentifier = bundle.bundleIdentifier,
                      !bindings.contains(where: { $0.appBundleIdentifier == bundleIdentifier }) else {
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
                bindings.append(newBinding)
                addedIDs.append(id)
            }

            if let firstID = addedIDs.first {
                selection = [firstID]
                DispatchQueue.main.async {
                    coordinator?.focusCoordinator.focusList()
                }
            }

            // Register undo for all added bindings
            if !addedIDs.isEmpty {
                let addedBindings = bindings.filter { addedIDs.contains($0.id) }
                let actionName = addedBindings.count == 1
                    ? "Add \(addedBindings[0].appName)"
                    : "Add \(addedBindings.count) Shortcuts"
                undoManager.registerUndo { [self, addedBindings] in
                    removeBindings(addedBindings)
                }
                undoManager.setActionName(actionName)
            }
        } else {
            if wasSearchFocused {
                isSearchFocused = true
            } else if wasListFocused {
                DispatchQueue.main.async {
                    coordinator?.focusCoordinator.focusList()
                }
            }
        }
    }

    private func removeSelected() {
        guard !selection.isEmpty else { return }

        // Find the index to select after removal
        let currentList = filteredBindings
        let selectedIndices = selection.compactMap { id in
            currentList.firstIndex { $0.id == id }
        }.sorted()

        // Determine the next item to select
        let nextSelectionID: HotkeyBinding.ID? = {
            guard let lastSelectedIndex = selectedIndices.last else { return nil }
            let remainingCount = currentList.count - selection.count
            guard remainingCount > 0 else { return nil }

            // Try to select the next item after the last selected one
            let nextIndex = lastSelectedIndex + 1
            if nextIndex < currentList.count {
                // Find the next item that isn't being removed
                for i in nextIndex..<currentList.count {
                    let id = currentList[i].id
                    if !selection.contains(id) {
                        return id
                    }
                }
            }

            // Fall back to the previous item before the first selected one
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

        // Save bindings and their shortcuts for undo
        let removedBindings = bindings.filter { selection.contains($0.id) }
        var savedShortcuts: [HotkeyBinding.ID: KeyboardShortcuts.Shortcut] = [:]
        for binding in removedBindings {
            let name = KeyboardShortcuts.Name(binding.shortcutName)
            if let shortcut = KeyboardShortcuts.getShortcut(for: name) {
                savedShortcuts[binding.id] = shortcut
            }
        }

        // Clear shortcuts for removed bindings
        for binding in removedBindings {
            let name = KeyboardShortcuts.Name(binding.shortcutName)
            KeyboardShortcuts.setShortcut(nil, for: name)
        }

        bindings.removeAll { selection.contains($0.id) }

        if let nextID = nextSelectionID {
            selection = [nextID]
        } else {
            selection = []
        }

        // Register undo
        let actionName = removedBindings.count == 1
            ? "Remove \(removedBindings[0].appName)"
            : "Remove \(removedBindings.count) Shortcuts"
        undoManager.registerUndo { [self, removedBindings, savedShortcuts] in
            addBindings(removedBindings, shortcuts: savedShortcuts)
        }
        undoManager.setActionName(actionName)
    }

    private func removeBindings(_ bindingsToRemove: [HotkeyBinding]) {
        let idsToRemove = Set(bindingsToRemove.map(\.id))

        // Clear shortcuts
        for binding in bindingsToRemove {
            let name = KeyboardShortcuts.Name(binding.shortcutName)
            KeyboardShortcuts.setShortcut(nil, for: name)
        }

        bindings.removeAll { idsToRemove.contains($0.id) }
        selection = selection.subtracting(idsToRemove)

        // Register undo to add them back
        let actionName = bindingsToRemove.count == 1
            ? "Remove \(bindingsToRemove[0].appName)"
            : "Remove \(bindingsToRemove.count) Shortcuts"
        undoManager.registerUndo { [self, bindingsToRemove] in
            addBindings(bindingsToRemove, shortcuts: [:])
        }
        undoManager.setActionName(actionName)
    }

    private func addBindings(_ bindingsToAdd: [HotkeyBinding], shortcuts: [HotkeyBinding.ID: KeyboardShortcuts.Shortcut]) {
        for binding in bindingsToAdd {
            if !bindings.contains(where: { $0.id == binding.id }) {
                bindings.append(binding)
            }
        }

        // Restore shortcuts
        for (id, shortcut) in shortcuts {
            if let binding = bindingsToAdd.first(where: { $0.id == id }) {
                let name = KeyboardShortcuts.Name(binding.shortcutName)
                KeyboardShortcuts.setShortcut(shortcut, for: name)
            }
        }

        if let firstID = bindingsToAdd.first?.id {
            selection = [firstID]
        }

        // Register undo to remove them
        let actionName = bindingsToAdd.count == 1
            ? "Add \(bindingsToAdd[0].appName)"
            : "Add \(bindingsToAdd.count) Shortcuts"
        undoManager.registerUndo { [self, bindingsToAdd] in
            removeBindings(bindingsToAdd)
        }
        undoManager.setActionName(actionName)
    }
}

#Preview {
    BindingListView()
        .frame(width: 450, height: 350)
}
