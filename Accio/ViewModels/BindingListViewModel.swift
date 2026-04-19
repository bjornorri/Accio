//
//  BindingListViewModel.swift
//  Accio
//

import AppKit
import Combine
import FactoryKit
import KeyboardShortcuts
import SwiftUI
import UniformTypeIdentifiers

// MARK: - BindingListItem

/// A flat list item that can be a binding, a group header, a group member, or an "Add App" button
enum BindingListItem: Identifiable {
    case binding(HotkeyBinding)
    case group(AppGroup)
    case groupMember(AppGroupMember, groupID: AppGroup.ID, showMostRecentLabel: Bool)
    case addAppToGroup(AppGroup.ID)

    var id: String {
        switch self {
        case .binding(let b): return "binding:\(b.id.uuidString)"
        case .group(let g): return "group:\(g.id.uuidString)"
        case .groupMember(let m, let gid, _): return "member:\(gid.uuidString):\(m.bundleIdentifier)"
        case .addAppToGroup(let gid): return "addapp:\(gid.uuidString)"
        }
    }
}

// MARK: - BindingListViewModel

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

    @ObservationIgnored
    @Injected(\.bindingStore) private var bindingStore

    @ObservationIgnored
    @Injected(\.appGroupStore) private var groupStore

    // MARK: - Published State

    var selection: Set<String> = []
    var searchText = ""
    var scrollToID: String?
    var activeRecorderID: UUID?
    var expandedGroupIDs: Set<AppGroup.ID> = []
    var renamingGroupID: AppGroup.ID?
    var pendingGroupName: String = ""

    // MARK: - Internal State

    private(set) var refreshTrigger = false
    private var recordingTarget: RecordingTarget?
    private var previousShortcut: KeyboardShortcuts.Shortcut?

    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Recording Target

    private enum RecordingTarget {
        case binding(HotkeyBinding)
        case group(AppGroup)

        var shortcutName: String {
            switch self {
            case .binding(let b): return b.shortcutName
            case .group(let g): return g.shortcutName
            }
        }

        var id: UUID {
            switch self {
            case .binding(let b): return b.id
            case .group(let g): return g.id
            }
        }
    }

    // MARK: - Data Access

    private(set) var bindings: [HotkeyBinding] = []
    private(set) var groups: [AppGroup] = []

    init() {
        bindings = bindingStore.bindings
        groups = groupStore.groups

        bindingStore.bindingsPublisher
            .sink { [weak self] newBindings in
                Task { @MainActor in
                    self?.bindings = newBindings
                }
            }
            .store(in: &cancellables)

        groupStore.groupsPublisher
            .sink { [weak self] newGroups in
                Task { @MainActor in
                    self?.groups = newGroups
                }
            }
            .store(in: &cancellables)
    }

    private func updateBindings(_ newBindings: [HotkeyBinding]) {
        bindings = newBindings
        bindingStore.bindings = newBindings
    }

    private func updateGroups(_ newGroups: [AppGroup]) {
        groups = newGroups
        groupStore.groups = newGroups
    }

    var isEmpty: Bool {
        bindings.isEmpty && groups.isEmpty
    }

    // MARK: - Filtered Items

    var filteredItems: [BindingListItem] {
        var combined: [(name: String, item: BindingListItem)] = []

        for binding in bindings {
            if searchText.isEmpty || binding.appName.localizedCaseInsensitiveContains(searchText) {
                combined.append((binding.appName, .binding(binding)))
            }
        }

        for group in groups {
            if searchText.isEmpty || group.name.localizedCaseInsensitiveContains(searchText) {
                combined.append((group.name, .group(group)))
            }
        }

        combined.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        var result: [BindingListItem] = []
        for (_, item) in combined {
            result.append(item)
            if case .group(let group) = item, expandedGroupIDs.contains(group.id) {
                for (index, member) in group.members.enumerated() {
                    let showLabel = index == 0 && group.members.count > 1
                    result.append(.groupMember(member, groupID: group.id, showMostRecentLabel: showLabel))
                }
                result.append(.addAppToGroup(group.id))
            }
        }
        return result
    }

    /// Binding-only filtered list — preserved for backwards compatibility
    var filteredBindings: [HotkeyBinding] {
        filteredItems.compactMap {
            if case .binding(let b) = $0 { return b }
            return nil
        }
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

        var updatedGroups = groups
        var groupsUpdated = false

        for (gi, group) in updatedGroups.enumerated() {
            var updatedMembers = group.members
            for (mi, member) in updatedMembers.enumerated() {
                if let currentName = appMetadataProvider.appName(for: member.bundleIdentifier),
                   member.appName != currentName {
                    updatedMembers[mi] = AppGroupMember(bundleIdentifier: member.bundleIdentifier, appName: currentName)
                    groupsUpdated = true
                }
            }
            updatedGroups[gi].members = updatedMembers
        }

        if groupsUpdated {
            updateGroups(updatedGroups)
        }
    }

    // MARK: - Selection

    func handleListFocused() {
        let selectableIDs = Set(filteredItems.compactMap { item -> String? in
            if case .addAppToGroup = item { return nil }
            return item.id
        })
        let validSelection = selection.intersection(selectableIDs)

        if validSelection.isEmpty, let firstID = filteredItems.first(where: {
            switch $0 {
            case .binding, .group: return true
            default: return false
            }
        })?.id {
            selection = [firstID]
        } else if validSelection != selection {
            selection = validSelection
        }
    }

    // MARK: - Expand / Collapse

    func toggleExpanded(_ groupID: AppGroup.ID) {
        if expandedGroupIDs.contains(groupID) {
            expandedGroupIDs.remove(groupID)
        } else {
            expandedGroupIDs.insert(groupID)
        }
    }

    // MARK: - Recorder

    func activateSelectedRecorder() {
        guard let selectedID = selection.first, selection.count == 1 else { return }
        let uuid: UUID?
        if selectedID.hasPrefix("binding:") {
            uuid = UUID(uuidString: String(selectedID.dropFirst("binding:".count)))
        } else if selectedID.hasPrefix("group:") {
            uuid = UUID(uuidString: String(selectedID.dropFirst("group:".count)))
        } else {
            uuid = nil
        }
        guard let id = uuid else { return }
        activateRecorder(for: id)
    }

    func activateRecorder(for itemID: UUID) {
        activeRecorderID = itemID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.activeRecorderID = nil
        }
    }

    func onRecorderActivated(for binding: HotkeyBinding) {
        hotkeyManager.pauseAll()
        selection = ["binding:\(binding.id.uuidString)"]
        recordingTarget = .binding(binding)
        previousShortcut = KeyboardShortcuts.getShortcut(for: .init(binding.shortcutName))
    }

    func onGroupRecorderActivated(for group: AppGroup) {
        hotkeyManager.pauseAll()
        selection = ["group:\(group.id.uuidString)"]
        recordingTarget = .group(group)
        previousShortcut = KeyboardShortcuts.getShortcut(for: .init(group.shortcutName))
    }

    func onRecorderDeactivated() {
        hotkeyManager.resumeAll()
        handleRecordingEnded()
    }

    private func handleRecordingEnded() {
        guard let target = recordingTarget else { return }
        let savedPreviousShortcut = previousShortcut
        let editedName = KeyboardShortcuts.Name(target.shortcutName)
        let newShortcut = KeyboardShortcuts.getShortcut(for: editedName)

        recordingTarget = nil
        previousShortcut = nil

        guard newShortcut != savedPreviousShortcut else { return }

        if let conflict = bindingOrchestrator.findConflict(for: target.shortcutName) {
            let alert = NSAlert()
            alert.messageText = "Shortcut Already in Use"
            alert.informativeText = "This shortcut is already assigned to \(conflict.conflictingItem.displayName). Do you want to reassign it to \(conflict.editedItem.displayName)?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Reassign")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()

            if response == .alertFirstButtonReturn {
                let conflictingName = KeyboardShortcuts.Name(conflict.conflictingItem.shortcutName)
                let conflictingPreviousShortcut = KeyboardShortcuts.getShortcut(for: conflictingName)

                bindingOrchestrator.clearShortcut(for: conflict.conflictingItem)

                undoManager.registerUndo { [self, savedPreviousShortcut, conflict, conflictingPreviousShortcut] in
                    KeyboardShortcuts.setShortcut(savedPreviousShortcut, for: editedName)
                    if let conflictingPrevious = conflictingPreviousShortcut {
                        KeyboardShortcuts.setShortcut(conflictingPrevious, for: conflictingName)
                    }
                    registerRedoForShortcutChange(
                        shortcutName: target.shortcutName,
                        fromShortcut: savedPreviousShortcut,
                        toShortcut: newShortcut,
                        conflictingShortcutName: conflict.conflictingItem.shortcutName,
                        conflictingPreviousShortcut: conflictingPreviousShortcut
                    )
                }
                undoManager.setActionName("Record Shortcut")
            } else {
                KeyboardShortcuts.setShortcut(savedPreviousShortcut, for: editedName)
            }
        } else {
            undoManager.registerUndo { [self, savedPreviousShortcut, newShortcut] in
                KeyboardShortcuts.setShortcut(savedPreviousShortcut, for: editedName)
                registerRedoForShortcutChange(
                    shortcutName: target.shortcutName,
                    fromShortcut: savedPreviousShortcut,
                    toShortcut: newShortcut,
                    conflictingShortcutName: nil,
                    conflictingPreviousShortcut: nil
                )
            }
            undoManager.setActionName("Record Shortcut")
        }
    }

    private func registerRedoForShortcutChange(
        shortcutName: String,
        fromShortcut: KeyboardShortcuts.Shortcut?,
        toShortcut: KeyboardShortcuts.Shortcut?,
        conflictingShortcutName: String?,
        conflictingPreviousShortcut: KeyboardShortcuts.Shortcut?
    ) {
        let editedName = KeyboardShortcuts.Name(shortcutName)
        undoManager.registerUndo { [self] in
            KeyboardShortcuts.setShortcut(toShortcut, for: editedName)
            if let conflicting = conflictingShortcutName {
                KeyboardShortcuts.setShortcut(nil, for: .init(conflicting))
            }
            undoManager.registerUndo { [self] in
                KeyboardShortcuts.setShortcut(fromShortcut, for: editedName)
                if let conflicting = conflictingShortcutName, let prevShortcut = conflictingPreviousShortcut {
                    KeyboardShortcuts.setShortcut(prevShortcut, for: .init(conflicting))
                }
                registerRedoForShortcutChange(
                    shortcutName: shortcutName,
                    fromShortcut: fromShortcut,
                    toShortcut: toShortcut,
                    conflictingShortcutName: conflictingShortcutName,
                    conflictingPreviousShortcut: conflictingPreviousShortcut
                )
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
        selection = ["binding:\(id.uuidString)"]
        scrollToID = "binding:\(id.uuidString)"

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

        if let first = newBindings.first {
            selection = ["binding:\(first.id.uuidString)"]
            scrollToID = "binding:\(first.id.uuidString)"
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

    // MARK: - Add Group

    func addGroup() {
        let id = UUID()
        let newGroup = AppGroup(id: id, name: "New Group")
        updateGroups(groups + [newGroup])

        selection = ["group:\(id.uuidString)"]
        expandedGroupIDs.insert(id)
        scrollToID = "group:\(id.uuidString)"
        beginRename(for: id)

        undoManager.registerUndo { [self, newGroup] in
            removeGroupsInternal([newGroup])
        }
        undoManager.setActionName("Add Group")
    }

    // MARK: - Rename Group

    func beginRename(for groupID: AppGroup.ID) {
        guard let group = groups.first(where: { $0.id == groupID }) else { return }
        renamingGroupID = groupID
        pendingGroupName = group.name
    }

    func confirmRename() {
        guard let groupID = renamingGroupID else { return }
        let trimmed = pendingGroupName.trimmingCharacters(in: .whitespaces)
        renamingGroupID = nil

        guard !trimmed.isEmpty,
              let index = groups.firstIndex(where: { $0.id == groupID }) else { return }

        let oldName = groups[index].name
        guard trimmed != oldName else { return }

        var updatedGroups = groups
        updatedGroups[index].name = trimmed
        updateGroups(updatedGroups)

        undoManager.registerUndo { [self, groupID, oldName, trimmed] in
            renameGroupInternal(id: groupID, name: oldName)
            registerRedoForRename(id: groupID, name: trimmed)
        }
        undoManager.setActionName("Rename Group")
    }

    func cancelRename() {
        renamingGroupID = nil
    }

    private func renameGroupInternal(id: AppGroup.ID, name: String) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        var updatedGroups = groups
        updatedGroups[index].name = name
        updateGroups(updatedGroups)
    }

    private func registerRedoForRename(id: AppGroup.ID, name: String) {
        undoManager.registerUndo { [self, id, name] in
            guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
            let currentName = groups[index].name
            renameGroupInternal(id: id, name: name)
            registerRedoForRename(id: id, name: currentName)
        }
        undoManager.setActionName("Rename Group")
    }

    // MARK: - Add Apps to Group

    func addAppsToGroup(groupID: AppGroup.ID) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupID }) else { return }

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Choose applications to add to group"
        panel.prompt = "Add"

        guard panel.runModal() == .OK else { return }

        let existingIDs = Set(groups[groupIndex].members.map(\.bundleIdentifier))
        var newMembers: [AppGroupMember] = []

        for url in panel.urls {
            guard let bundle = Bundle(url: url),
                  let bundleIdentifier = bundle.bundleIdentifier,
                  !existingIDs.contains(bundleIdentifier),
                  !newMembers.contains(where: { $0.bundleIdentifier == bundleIdentifier }) else {
                continue
            }

            let appName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? url.deletingPathExtension().lastPathComponent

            newMembers.append(AppGroupMember(bundleIdentifier: bundleIdentifier, appName: appName))
        }

        guard !newMembers.isEmpty else { return }

        var updatedGroups = groups
        updatedGroups[groupIndex].members.append(contentsOf: newMembers)
        updateGroups(updatedGroups)

        undoManager.registerUndo { [self, groupID, newMembers] in
            removeAppsFromGroupInternal(groupID: groupID, members: newMembers)
        }
        let actionName = newMembers.count == 1 ? "Add App to Group" : "Add Apps to Group"
        undoManager.setActionName(actionName)
    }

    // MARK: - Remove App from Group

    func removeAppFromGroup(bundleIdentifier: String, groupID: AppGroup.ID) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupID }),
              let memberIndex = groups[groupIndex].members.firstIndex(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            return
        }

        let removedMember = groups[groupIndex].members[memberIndex]
        var updatedGroups = groups
        updatedGroups[groupIndex].members.remove(at: memberIndex)
        updateGroups(updatedGroups)

        undoManager.registerUndo { [self, groupID, removedMember, memberIndex] in
            insertMemberInGroupInternal(groupID: groupID, member: removedMember, at: memberIndex)
        }
        undoManager.setActionName("Remove App")
    }

    private func removeAppsFromGroupInternal(groupID: AppGroup.ID, members membersToRemove: [AppGroupMember]) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupID }) else { return }
        let idsToRemove = Set(membersToRemove.map(\.bundleIdentifier))
        var updatedGroups = groups
        updatedGroups[groupIndex].members.removeAll { idsToRemove.contains($0.bundleIdentifier) }
        updateGroups(updatedGroups)

        undoManager.registerUndo { [self, groupID, membersToRemove] in
            guard let gi = groups.firstIndex(where: { $0.id == groupID }) else { return }
            var updated = groups
            updated[gi].members.append(contentsOf: membersToRemove)
            updateGroups(updated)
            undoManager.registerUndo { [self, groupID, membersToRemove] in
                removeAppsFromGroupInternal(groupID: groupID, members: membersToRemove)
            }
            let actionName = membersToRemove.count == 1 ? "Add App to Group" : "Add Apps to Group"
            undoManager.setActionName(actionName)
        }
        let actionName = membersToRemove.count == 1 ? "Remove App" : "Remove Apps"
        undoManager.setActionName(actionName)
    }

    private func insertMemberInGroupInternal(groupID: AppGroup.ID, member: AppGroupMember, at index: Int) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupID }) else { return }
        var updatedGroups = groups
        let clampedIndex = min(index, updatedGroups[groupIndex].members.count)
        updatedGroups[groupIndex].members.insert(member, at: clampedIndex)
        updateGroups(updatedGroups)

        undoManager.registerUndo { [self, groupID, member] in
            removeAppFromGroup(bundleIdentifier: member.bundleIdentifier, groupID: groupID)
        }
        undoManager.setActionName("Add App")
    }

    // MARK: - Remove Bindings / Groups

    func removeSelected() {
        guard !selection.isEmpty else { return }

        let selectedBindings = bindings.filter { selection.contains("binding:\($0.id.uuidString)") }
        let selectedGroups = groups.filter { selection.contains("group:\($0.id.uuidString)") }

        // Parse selected group members: "member:{groupID}:{bundleID}"
        // Skip members whose parent group is also being deleted
        let selectedGroupIDs = Set(selectedGroups.map(\.id))
        struct SelectedMember { let member: AppGroupMember; let groupID: AppGroup.ID; let originalIndex: Int }
        var selectedMembers: [SelectedMember] = []
        for selID in selection {
            guard selID.hasPrefix("member:") else { continue }
            let rest = String(selID.dropFirst("member:".count))
            guard let colonIdx = rest.firstIndex(of: ":"),
                  let groupID = UUID(uuidString: String(rest[rest.startIndex..<colonIdx])) else { continue }
            guard !selectedGroupIDs.contains(groupID) else { continue }
            let bundleID = String(rest[rest.index(after: colonIdx)...])
            guard let gi = groups.firstIndex(where: { $0.id == groupID }),
                  let mi = groups[gi].members.firstIndex(where: { $0.bundleIdentifier == bundleID }) else { continue }
            selectedMembers.append(SelectedMember(member: groups[gi].members[mi], groupID: groupID, originalIndex: mi))
        }

        guard !selectedBindings.isEmpty || !selectedGroups.isEmpty || !selectedMembers.isEmpty else { return }

        // Compute next selection from binding/group rows only
        let allVisible = filteredItems.compactMap { item -> String? in
            switch item {
            case .binding, .group: return item.id
            default: return nil
            }
        }
        let sortedSelected = allVisible.filter { selection.contains($0) }
        let nextSelectionID: String? = {
            guard let lastSelected = sortedSelected.last,
                  let lastIndex = allVisible.firstIndex(of: lastSelected) else { return nil }
            let nextIndex = lastIndex + 1
            if nextIndex < allVisible.count { return allVisible[nextIndex] }
            if let firstSelected = sortedSelected.first,
               let firstIndex = allVisible.firstIndex(of: firstSelected),
               firstIndex > 0 { return allVisible[firstIndex - 1] }
            return nil
        }()

        // Save shortcuts for undo
        var savedBindingShortcuts: [HotkeyBinding.ID: KeyboardShortcuts.Shortcut] = [:]
        for binding in selectedBindings {
            if let sc = KeyboardShortcuts.getShortcut(for: .init(binding.shortcutName)) {
                savedBindingShortcuts[binding.id] = sc
            }
            KeyboardShortcuts.setShortcut(nil, for: .init(binding.shortcutName))
        }

        var savedGroupShortcuts: [AppGroup.ID: KeyboardShortcuts.Shortcut] = [:]
        for group in selectedGroups {
            if let sc = KeyboardShortcuts.getShortcut(for: .init(group.shortcutName)) {
                savedGroupShortcuts[group.id] = sc
            }
            KeyboardShortcuts.setShortcut(nil, for: .init(group.shortcutName))
        }

        // Remove group members from their groups (without triggering individual undos)
        if !selectedMembers.isEmpty {
            var updatedGroups = groups
            for m in selectedMembers {
                guard let gi = updatedGroups.firstIndex(where: { $0.id == m.groupID }) else { continue }
                updatedGroups[gi].members.removeAll { $0.bundleIdentifier == m.member.bundleIdentifier }
            }
            groups = updatedGroups
            groupStore.groups = updatedGroups
        }

        updateBindings(bindings.filter { !selection.contains("binding:\($0.id.uuidString)") })
        updateGroups(groups.filter { !selection.contains("group:\($0.id.uuidString)") })
        expandedGroupIDs.subtract(selectedGroupIDs)

        if let nextID = nextSelectionID {
            selection = [nextID]
        } else if !selectedMembers.isEmpty, let groupID = selectedMembers.first?.groupID,
                  groups.contains(where: { $0.id == groupID }) {
            selection = ["group:\(groupID.uuidString)"]
        } else {
            selection = []
        }

        let totalCount = selectedBindings.count + selectedGroups.count + selectedMembers.count
        let actionName: String
        if totalCount == 1 {
            if let b = selectedBindings.first { actionName = "Remove \(b.appName)" }
            else if let g = selectedGroups.first { actionName = "Remove \(g.name)" }
            else if let m = selectedMembers.first { actionName = "Remove \(m.member.appName)" }
            else { actionName = "Remove" }
        } else {
            actionName = "Remove \(totalCount) Items"
        }

        undoManager.registerUndo { [self, selectedBindings, savedBindingShortcuts, selectedGroups, savedGroupShortcuts, selectedMembers] in
            addBindingsInternal(selectedBindings, shortcuts: savedBindingShortcuts)
            addGroupsInternal(selectedGroups, shortcuts: savedGroupShortcuts)
            for m in selectedMembers.sorted(by: { $0.originalIndex < $1.originalIndex }) {
                insertMemberInGroupInternal(groupID: m.groupID, member: m.member, at: m.originalIndex)
            }
        }
        undoManager.setActionName(actionName)
    }

    private func removeBindingsInternal(_ bindingsToRemove: [HotkeyBinding]) {
        let idsToRemove = Set(bindingsToRemove.map(\.id))

        for binding in bindingsToRemove {
            KeyboardShortcuts.setShortcut(nil, for: .init(binding.shortcutName))
        }

        updateBindings(bindings.filter { !idsToRemove.contains($0.id) })
        selection = selection.subtracting(idsToRemove.map { "binding:\($0.uuidString)" })


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
                KeyboardShortcuts.setShortcut(shortcut, for: .init(binding.shortcutName))
            }
        }

        if let first = bindingsToAdd.first {
            selection = ["binding:\(first.id.uuidString)"]
            scrollToID = "binding:\(first.id.uuidString)"
        }

        let actionName = bindingsToAdd.count == 1
            ? "Add \(bindingsToAdd[0].appName)"
            : "Add \(bindingsToAdd.count) Shortcuts"
        undoManager.registerUndo { [self, bindingsToAdd] in
            removeBindingsInternal(bindingsToAdd)
        }
        undoManager.setActionName(actionName)
    }

    private func removeGroupsInternal(_ groupsToRemove: [AppGroup]) {
        let idsToRemove = Set(groupsToRemove.map(\.id))

        for group in groupsToRemove {
            KeyboardShortcuts.setShortcut(nil, for: .init(group.shortcutName))
        }

        updateGroups(groups.filter { !idsToRemove.contains($0.id) })
        selection = selection.subtracting(idsToRemove.map { "group:\($0.uuidString)" })
        expandedGroupIDs.subtract(idsToRemove)

        let actionName = groupsToRemove.count == 1
            ? "Remove \(groupsToRemove[0].name)"
            : "Remove \(groupsToRemove.count) Groups"
        undoManager.registerUndo { [self, groupsToRemove] in
            addGroupsInternal(groupsToRemove, shortcuts: [:])
        }
        undoManager.setActionName(actionName)
    }

    private func addGroupsInternal(_ groupsToAdd: [AppGroup], shortcuts: [AppGroup.ID: KeyboardShortcuts.Shortcut]) {
        let existingIDs = Set(groups.map(\.id))
        let newGroups = groupsToAdd.filter { !existingIDs.contains($0.id) }

        if !newGroups.isEmpty {
            updateGroups(groups + newGroups)
        }

        for (id, shortcut) in shortcuts {
            if let group = groupsToAdd.first(where: { $0.id == id }) {
                KeyboardShortcuts.setShortcut(shortcut, for: .init(group.shortcutName))
            }
        }

        if let first = groupsToAdd.first {
            selection = ["group:\(first.id.uuidString)"]
            scrollToID = "group:\(first.id.uuidString)"
        }

        let actionName = groupsToAdd.count == 1
            ? "Add \(groupsToAdd[0].name)"
            : "Add \(groupsToAdd.count) Groups"
        undoManager.registerUndo { [self, groupsToAdd] in
            removeGroupsInternal(groupsToAdd)
        }
        undoManager.setActionName(actionName)
    }
}
