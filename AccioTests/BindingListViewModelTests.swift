//
//  BindingListViewModelTests.swift
//  AccioTests
//

import FactoryKit
import FactoryTesting
import Foundation
import Testing
@testable import Accio

@Suite(.container, .serialized)
@MainActor
struct BindingListViewModelTests {

    private func createViewModel(
        with bindings: [HotkeyBinding] = [],
        groups: [AppGroup] = []
    ) -> (BindingListViewModel, MockHotkeyManager, MockBindingOrchestrator, MockBindingUndoManager, MockAppMetadataProvider) {
        Container.shared.manager.reset(options: .all)

        let mockBindingStore = MockBindingStore(bindings: bindings)
        let mockGroupStore = MockAppGroupStore(groups: groups)
        let mockHotkeyManager = MockHotkeyManager()
        let mockOrchestrator = MockBindingOrchestrator()
        let mockUndoManager = MockBindingUndoManager()
        let mockMetadataProvider = MockAppMetadataProvider()

        Container.shared.bindingStore.register { mockBindingStore }
        Container.shared.appGroupStore.register { mockGroupStore }
        Container.shared.hotkeyManager.register { mockHotkeyManager }
        Container.shared.bindingOrchestrator.register { mockOrchestrator }
        Container.shared.bindingUndoManager.register { mockUndoManager }
        Container.shared.appMetadataProvider.register { mockMetadataProvider }

        let viewModel = BindingListViewModel()
        return (viewModel, mockHotkeyManager, mockOrchestrator, mockUndoManager, mockMetadataProvider)
    }

    // MARK: - isEmpty Tests

    @Test func isEmpty_returnsTrueWhenNoBindings() {
        let (viewModel, _, _, _, _) = createViewModel()

        #expect(viewModel.isEmpty == true)
    }

    @Test func isEmpty_returnsFalseWhenBindingsExist() {
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(shortcutName: "test", appBundleIdentifier: "com.test.App", appName: "Test")
        ])

        #expect(viewModel.isEmpty == false)
    }

    // MARK: - filteredBindings Tests

    @Test func filteredBindings_returnsSortedByAppName() {
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(shortcutName: "z", appBundleIdentifier: "com.z.App", appName: "Zebra"),
            HotkeyBinding(shortcutName: "a", appBundleIdentifier: "com.a.App", appName: "Apple"),
            HotkeyBinding(shortcutName: "m", appBundleIdentifier: "com.m.App", appName: "Mango")
        ])

        #expect(viewModel.filteredBindings.map(\.appName) == ["Apple", "Mango", "Zebra"])
    }

    @Test func filteredBindings_filtersWhenSearchTextIsSet() {
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(shortcutName: "s", appBundleIdentifier: "com.safari", appName: "Safari"),
            HotkeyBinding(shortcutName: "f", appBundleIdentifier: "com.finder", appName: "Finder"),
            HotkeyBinding(shortcutName: "m", appBundleIdentifier: "com.mail", appName: "Mail")
        ])

        viewModel.searchText = "fi"

        #expect(viewModel.filteredBindings.map(\.appName) == ["Finder"])
    }

    @Test func filteredBindings_isCaseInsensitive() {
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(shortcutName: "s", appBundleIdentifier: "com.safari", appName: "Safari"),
            HotkeyBinding(shortcutName: "f", appBundleIdentifier: "com.finder", appName: "Finder")
        ])

        viewModel.searchText = "SAFARI"

        #expect(viewModel.filteredBindings.map(\.appName) == ["Safari"])
    }

    // MARK: - hasSelection Tests

    @Test func hasSelection_returnsFalseWhenEmpty() {
        let (viewModel, _, _, _, _) = createViewModel()

        #expect(viewModel.hasSelection == false)
    }

    @Test func hasSelection_returnsTrueWhenNotEmpty() {
        let id = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: id, shortcutName: "test", appBundleIdentifier: "com.test", appName: "Test")
        ])
        viewModel.selection = ["binding:\(id.uuidString)"]

        #expect(viewModel.hasSelection == true)
    }

    // MARK: - handleListFocused Tests

    @Test func handleListFocused_selectsFirstBindingWhenNoSelection() {
        let id1 = UUID()
        let id2 = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: id1, shortcutName: "a", appBundleIdentifier: "com.a", appName: "Apple"),
            HotkeyBinding(id: id2, shortcutName: "z", appBundleIdentifier: "com.z", appName: "Zebra")
        ])

        viewModel.handleListFocused()

        #expect(viewModel.selection == ["binding:\(id1.uuidString)"])
    }

    @Test func handleListFocused_keepsValidSelection() {
        let id1 = UUID()
        let id2 = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: id1, shortcutName: "a", appBundleIdentifier: "com.a", appName: "Apple"),
            HotkeyBinding(id: id2, shortcutName: "z", appBundleIdentifier: "com.z", appName: "Zebra")
        ])
        viewModel.selection = ["binding:\(id2.uuidString)"]

        viewModel.handleListFocused()

        #expect(viewModel.selection == ["binding:\(id2.uuidString)"])
    }

    @Test func handleListFocused_clearsInvalidSelection() {
        let id1 = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: id1, shortcutName: "a", appBundleIdentifier: "com.a", appName: "Apple")
        ])
        viewModel.selection = ["binding:\(UUID().uuidString)"]

        viewModel.handleListFocused()

        #expect(viewModel.selection == ["binding:\(id1.uuidString)"])
    }

    // MARK: - activateSelectedRecorder Tests

    @Test func activateSelectedRecorder_activatesWhenSingleSelection() async throws {
        let id = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: id, shortcutName: "test", appBundleIdentifier: "com.test", appName: "Test")
        ])
        viewModel.selection = ["binding:\(id.uuidString)"]

        viewModel.activateSelectedRecorder()

        #expect(viewModel.activeRecorderID == id)
    }

    @Test func activateSelectedRecorder_doesNothingWhenMultipleSelection() {
        let id1 = UUID()
        let id2 = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: id1, shortcutName: "a", appBundleIdentifier: "com.a", appName: "A"),
            HotkeyBinding(id: id2, shortcutName: "b", appBundleIdentifier: "com.b", appName: "B")
        ])
        viewModel.selection = ["binding:\(id1.uuidString)", "binding:\(id2.uuidString)"]

        viewModel.activateSelectedRecorder()

        #expect(viewModel.activeRecorderID == nil)
    }

    @Test func activateSelectedRecorder_doesNothingWhenNoSelection() {
        let (viewModel, _, _, _, _) = createViewModel()

        viewModel.activateSelectedRecorder()

        #expect(viewModel.activeRecorderID == nil)
    }

    // MARK: - onRecorderActivated Tests

    @Test func onRecorderActivated_pausesHotkeys() {
        let (viewModel, mockHotkeyManager, _, _, _) = createViewModel()
        let binding = HotkeyBinding(shortcutName: "test", appBundleIdentifier: "com.test", appName: "Test")

        viewModel.onRecorderActivated(for: binding)

        #expect(mockHotkeyManager.pauseAllCalled == true)
    }

    @Test func onRecorderActivated_setsSelection() {
        let id = UUID()
        let (viewModel, _, _, _, _) = createViewModel()
        let binding = HotkeyBinding(id: id, shortcutName: "test", appBundleIdentifier: "com.test", appName: "Test")

        viewModel.onRecorderActivated(for: binding)

        #expect(viewModel.selection == ["binding:\(id.uuidString)"])
    }

    // MARK: - onRecorderDeactivated Tests

    @Test func onRecorderDeactivated_resumesHotkeys() {
        let binding = HotkeyBinding(shortcutName: "test", appBundleIdentifier: "com.test", appName: "Test")
        let (viewModel, mockHotkeyManager, _, _, _) = createViewModel(with: [binding])
        viewModel.onRecorderActivated(for: binding)

        viewModel.onRecorderDeactivated()

        #expect(mockHotkeyManager.resumeAllCalled == true)
    }

    // MARK: - removeSelected Tests

    @Test func removeSelected_removesSelectedBindings() {
        let id1 = UUID()
        let id2 = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: id1, shortcutName: "a", appBundleIdentifier: "com.a", appName: "Apple"),
            HotkeyBinding(id: id2, shortcutName: "z", appBundleIdentifier: "com.z", appName: "Zebra")
        ])
        viewModel.selection = ["binding:\(id1.uuidString)"]

        viewModel.removeSelected()

        #expect(viewModel.bindings.count == 1)
        #expect(viewModel.bindings.first?.id == id2)
    }

    @Test func removeSelected_selectsNextItem() {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: id1, shortcutName: "a", appBundleIdentifier: "com.a", appName: "Apple"),
            HotkeyBinding(id: id2, shortcutName: "m", appBundleIdentifier: "com.m", appName: "Mango"),
            HotkeyBinding(id: id3, shortcutName: "z", appBundleIdentifier: "com.z", appName: "Zebra")
        ])
        viewModel.selection = ["binding:\(id2.uuidString)"]

        viewModel.removeSelected()

        #expect(viewModel.selection == ["binding:\(id3.uuidString)"])
    }

    @Test func removeSelected_selectsPreviousItemWhenRemovingLast() {
        let id1 = UUID()
        let id2 = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: id1, shortcutName: "a", appBundleIdentifier: "com.a", appName: "Apple"),
            HotkeyBinding(id: id2, shortcutName: "z", appBundleIdentifier: "com.z", appName: "Zebra")
        ])
        viewModel.selection = ["binding:\(id2.uuidString)"]

        viewModel.removeSelected()

        #expect(viewModel.selection == ["binding:\(id1.uuidString)"])
    }

    @Test func removeSelected_registersUndo() {
        let id = UUID()
        let (viewModel, _, _, mockUndoManager, _) = createViewModel(with: [
            HotkeyBinding(id: id, shortcutName: "test", appBundleIdentifier: "com.test", appName: "Test App")
        ])
        viewModel.selection = ["binding:\(id.uuidString)"]

        viewModel.removeSelected()

        #expect(mockUndoManager.canUndo == true)
        #expect(mockUndoManager.actionNames.contains("Remove Test App"))
    }

    @Test func removeSelected_doesNothingWhenNoSelection() {
        let id = UUID()
        let (viewModel, _, _, mockUndoManager, _) = createViewModel(with: [
            HotkeyBinding(id: id, shortcutName: "test", appBundleIdentifier: "com.test", appName: "Test")
        ])

        viewModel.removeSelected()

        #expect(viewModel.bindings.count == 1)
        #expect(mockUndoManager.canUndo == false)
    }

    // MARK: - Undo/Redo Enable/Disable Tests

    @Test func enableUndo_enablesUndoManager() {
        let (viewModel, _, _, mockUndoManager, _) = createViewModel()

        viewModel.enableUndo()

        #expect(mockUndoManager.isEnabled == true)
    }

    @Test func disableUndo_disablesUndoManager() {
        let (viewModel, _, _, mockUndoManager, _) = createViewModel()
        viewModel.enableUndo()

        viewModel.disableUndo()

        #expect(mockUndoManager.isEnabled == false)
    }

    @Test func isUndoEnabled_reflectsUndoManagerState() {
        let (viewModel, _, _, _, _) = createViewModel()

        #expect(viewModel.isUndoEnabled == false)
        viewModel.enableUndo()
        #expect(viewModel.isUndoEnabled == true)
    }

    // MARK: - Expand/Collapse Tests

    @Test func toggleExpanded_expandsCollapsedGroup() {
        let group = AppGroup(name: "Work")
        let (viewModel, _, _, _, _) = createViewModel(groups: [group])

        viewModel.toggleExpanded(group.id)

        #expect(viewModel.expandedGroupIDs.contains(group.id))
    }

    @Test func toggleExpanded_collapsesExpandedGroup() {
        let group = AppGroup(name: "Work")
        let (viewModel, _, _, _, _) = createViewModel(groups: [group])
        viewModel.expandedGroupIDs.insert(group.id)

        viewModel.toggleExpanded(group.id)

        #expect(!viewModel.expandedGroupIDs.contains(group.id))
    }

    @Test func collapseSelectedGroup_collapsesSelectedGroup() {
        let group = AppGroup(name: "Work")
        let (viewModel, _, _, _, _) = createViewModel(groups: [group])
        viewModel.expandedGroupIDs.insert(group.id)
        viewModel.selection = ["group:\(group.id.uuidString)"]

        viewModel.collapseSelectedGroup()

        #expect(!viewModel.expandedGroupIDs.contains(group.id))
    }

    @Test func collapseSelectedGroup_doesNothingWhenGroupAlreadyCollapsed() {
        let group = AppGroup(name: "Work")
        let (viewModel, _, _, _, _) = createViewModel(groups: [group])
        viewModel.selection = ["group:\(group.id.uuidString)"]

        viewModel.collapseSelectedGroup()

        #expect(!viewModel.expandedGroupIDs.contains(group.id))
    }

    @Test func collapseSelectedGroup_selectsParentGroupWhenMemberSelected() {
        var group = AppGroup(name: "Work")
        group.members = [AppGroupMember(bundleIdentifier: "com.apple.Safari", appName: "Safari")]
        let (viewModel, _, _, _, _) = createViewModel(groups: [group])
        viewModel.expandedGroupIDs.insert(group.id)
        viewModel.selection = ["member:\(group.id.uuidString):com.apple.Safari"]

        viewModel.collapseSelectedGroup()

        #expect(viewModel.selection == ["group:\(group.id.uuidString)"])
    }

    @Test func collapseSelectedGroup_doesNothingWhenBindingSelected() {
        let bindingID = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: bindingID, shortcutName: "s", appBundleIdentifier: "com.safari", appName: "Safari")
        ])
        viewModel.selection = ["binding:\(bindingID.uuidString)"]

        viewModel.collapseSelectedGroup()

        #expect(viewModel.selection == ["binding:\(bindingID.uuidString)"])
    }

    @Test func expandSelectedGroup_expandsSelectedGroup() {
        let group = AppGroup(name: "Work")
        let (viewModel, _, _, _, _) = createViewModel(groups: [group])
        viewModel.selection = ["group:\(group.id.uuidString)"]

        viewModel.expandSelectedGroup()

        #expect(viewModel.expandedGroupIDs.contains(group.id))
    }

    @Test func expandSelectedGroup_doesNothingWhenBindingSelected() {
        let bindingID = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: bindingID, shortcutName: "s", appBundleIdentifier: "com.safari", appName: "Safari")
        ])
        viewModel.selection = ["binding:\(bindingID.uuidString)"]

        viewModel.expandSelectedGroup()

        #expect(viewModel.expandedGroupIDs.isEmpty)
    }

    @Test func expandSelectedGroup_doesNothingWhenNoSelection() {
        let group = AppGroup(name: "Work")
        let (viewModel, _, _, _, _) = createViewModel(groups: [group])

        viewModel.expandSelectedGroup()

        #expect(viewModel.expandedGroupIDs.isEmpty)
    }

    // MARK: - addGroup Tests

    @Test func addGroup_addsGroup() {
        let (viewModel, _, _, _, _) = createViewModel()

        viewModel.addGroup()

        #expect(viewModel.groups.count == 1)
    }

    @Test func addGroup_setsSelectionToNewGroup() {
        let (viewModel, _, _, _, _) = createViewModel()

        viewModel.addGroup()

        guard let group = viewModel.groups.first else {
            Issue.record("Expected a group to be added"); return
        }
        #expect(viewModel.selection == ["group:\(group.id.uuidString)"])
    }

    @Test func addGroup_expandsNewGroup() {
        let (viewModel, _, _, _, _) = createViewModel()

        viewModel.addGroup()

        guard let group = viewModel.groups.first else {
            Issue.record("Expected a group to be added"); return
        }
        #expect(viewModel.expandedGroupIDs.contains(group.id))
    }

    @Test func addGroup_beginsRenaming() {
        let (viewModel, _, _, _, _) = createViewModel()

        viewModel.addGroup()

        #expect(viewModel.renamingGroupID == viewModel.groups.first?.id)
        #expect(viewModel.pendingGroupName == "New Group")
    }

    @Test func addGroup_registersUndo() {
        let (viewModel, _, _, mockUndoManager, _) = createViewModel()

        viewModel.addGroup()

        #expect(mockUndoManager.canUndo == true)
        #expect(mockUndoManager.actionNames.contains("Add Group"))
    }

    // MARK: - Rename Group Tests

    @Test func beginRename_setsRenamingGroupID() {
        let group = AppGroup(name: "Work")
        let (viewModel, _, _, _, _) = createViewModel(groups: [group])

        viewModel.beginRename(for: group.id)

        #expect(viewModel.renamingGroupID == group.id)
    }

    @Test func beginRename_setsPendingGroupName() {
        let group = AppGroup(name: "Work")
        let (viewModel, _, _, _, _) = createViewModel(groups: [group])

        viewModel.beginRename(for: group.id)

        #expect(viewModel.pendingGroupName == "Work")
    }

    @Test func beginRename_doesNothingForUnknownID() {
        let (viewModel, _, _, _, _) = createViewModel()

        viewModel.beginRename(for: UUID())

        #expect(viewModel.renamingGroupID == nil)
    }

    @Test func confirmRename_updatesGroupName() {
        let group = AppGroup(name: "Old Name")
        let (viewModel, _, _, _, _) = createViewModel(groups: [group])
        viewModel.beginRename(for: group.id)
        viewModel.pendingGroupName = "New Name"

        viewModel.confirmRename()

        #expect(viewModel.groups.first?.name == "New Name")
    }

    @Test func confirmRename_clearsRenamingGroupID() {
        let group = AppGroup(name: "Old Name")
        let (viewModel, _, _, _, _) = createViewModel(groups: [group])
        viewModel.beginRename(for: group.id)
        viewModel.pendingGroupName = "New Name"

        viewModel.confirmRename()

        #expect(viewModel.renamingGroupID == nil)
    }

    @Test func confirmRename_doesNotRenameWhenNameUnchanged() {
        let group = AppGroup(name: "Same Name")
        let (viewModel, _, _, mockUndoManager, _) = createViewModel(groups: [group])
        viewModel.beginRename(for: group.id)

        viewModel.confirmRename()

        #expect(viewModel.groups.first?.name == "Same Name")
        #expect(!mockUndoManager.actionNames.contains("Rename Group"))
    }

    @Test func confirmRename_doesNotRenameWhenNameIsBlank() {
        let group = AppGroup(name: "Work")
        let (viewModel, _, _, _, _) = createViewModel(groups: [group])
        viewModel.beginRename(for: group.id)
        viewModel.pendingGroupName = "   "

        viewModel.confirmRename()

        #expect(viewModel.groups.first?.name == "Work")
    }

    @Test func confirmRename_registersUndo() {
        let group = AppGroup(name: "Old Name")
        let (viewModel, _, _, mockUndoManager, _) = createViewModel(groups: [group])
        viewModel.beginRename(for: group.id)
        viewModel.pendingGroupName = "New Name"

        viewModel.confirmRename()

        #expect(mockUndoManager.canUndo == true)
        #expect(mockUndoManager.actionNames.contains("Rename Group"))
    }

    @Test func cancelRename_clearsRenamingGroupID() {
        let group = AppGroup(name: "Work")
        let (viewModel, _, _, _, _) = createViewModel(groups: [group])
        viewModel.beginRename(for: group.id)

        viewModel.cancelRename()

        #expect(viewModel.renamingGroupID == nil)
    }

    @Test func cancelRename_doesNotChangeGroupName() {
        let group = AppGroup(name: "Work")
        let (viewModel, _, _, _, _) = createViewModel(groups: [group])
        viewModel.beginRename(for: group.id)
        viewModel.pendingGroupName = "New Name"

        viewModel.cancelRename()

        #expect(viewModel.groups.first?.name == "Work")
    }

    // MARK: - refreshMetadata Tests

    @Test func refreshMetadata_updatesAppNames() {
        let id = UUID()
        let (viewModel, _, _, _, mockMetadataProvider) = createViewModel(with: [
            HotkeyBinding(id: id, shortcutName: "test", appBundleIdentifier: "com.test", appName: "Old Name")
        ])
        mockMetadataProvider.appNames["com.test"] = "New Name"

        viewModel.refreshMetadata()

        #expect(viewModel.bindings.first?.appName == "New Name")
    }

    @Test func refreshMetadata_doesNotUpdateWhenNameUnchanged() {
        let id = UUID()
        let (viewModel, _, _, _, mockMetadataProvider) = createViewModel(with: [
            HotkeyBinding(id: id, shortcutName: "test", appBundleIdentifier: "com.test", appName: "Same Name")
        ])
        mockMetadataProvider.appNames["com.test"] = "Same Name"

        viewModel.refreshMetadata()

        #expect(viewModel.bindings.first?.appName == "Same Name")
    }

    @Test func refreshMetadata_togglesRefreshTrigger() {
        let (viewModel, _, _, _, _) = createViewModel()
        let initialValue = viewModel.refreshTrigger

        viewModel.refreshMetadata()

        #expect(viewModel.refreshTrigger != initialValue)
    }
}
