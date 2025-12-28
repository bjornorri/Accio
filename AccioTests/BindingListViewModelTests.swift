//
//  BindingListViewModelTests.swift
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
struct BindingListViewModelTests {

    private func createViewModel(
        with bindings: [HotkeyBinding] = []
    ) -> (BindingListViewModel, MockHotkeyManager, MockBindingOrchestrator, MockBindingUndoManager, MockAppMetadataProvider) {
        Container.shared.manager.reset(options: .all)
        Defaults[.hotkeyBindings] = bindings

        let mockHotkeyManager = MockHotkeyManager()
        let mockOrchestrator = MockBindingOrchestrator()
        let mockUndoManager = MockBindingUndoManager()
        let mockMetadataProvider = MockAppMetadataProvider()

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

        let names = viewModel.filteredBindings.map(\.appName)
        #expect(names == ["Apple", "Mango", "Zebra"])
    }

    @Test func filteredBindings_filtersWhenSearchTextIsSet() {
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(shortcutName: "s", appBundleIdentifier: "com.safari", appName: "Safari"),
            HotkeyBinding(shortcutName: "f", appBundleIdentifier: "com.finder", appName: "Finder"),
            HotkeyBinding(shortcutName: "m", appBundleIdentifier: "com.mail", appName: "Mail")
        ])

        viewModel.searchText = "fi"

        let names = viewModel.filteredBindings.map(\.appName)
        #expect(names == ["Finder"])
    }

    @Test func filteredBindings_isCaseInsensitive() {
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(shortcutName: "s", appBundleIdentifier: "com.safari", appName: "Safari"),
            HotkeyBinding(shortcutName: "f", appBundleIdentifier: "com.finder", appName: "Finder")
        ])

        viewModel.searchText = "SAFARI"

        let names = viewModel.filteredBindings.map(\.appName)
        #expect(names == ["Safari"])
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
        viewModel.selection = [id]

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

        #expect(viewModel.selection == [id1])
    }

    @Test func handleListFocused_keepsValidSelection() {
        let id1 = UUID()
        let id2 = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: id1, shortcutName: "a", appBundleIdentifier: "com.a", appName: "Apple"),
            HotkeyBinding(id: id2, shortcutName: "z", appBundleIdentifier: "com.z", appName: "Zebra")
        ])
        viewModel.selection = [id2]

        viewModel.handleListFocused()

        #expect(viewModel.selection == [id2])
    }

    @Test func handleListFocused_clearsInvalidSelection() {
        let id1 = UUID()
        let invalidId = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: id1, shortcutName: "a", appBundleIdentifier: "com.a", appName: "Apple")
        ])
        viewModel.selection = [invalidId]

        viewModel.handleListFocused()

        #expect(viewModel.selection == [id1])
    }

    // MARK: - activateSelectedRecorder Tests

    @Test func activateSelectedRecorder_activatesWhenSingleSelection() async throws {
        let id = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: id, shortcutName: "test", appBundleIdentifier: "com.test", appName: "Test")
        ])
        viewModel.selection = [id]

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
        viewModel.selection = [id1, id2]

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

        #expect(viewModel.selection == [id])
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
        viewModel.selection = [id1]

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
        viewModel.selection = [id2]

        viewModel.removeSelected()

        #expect(viewModel.selection == [id3])
    }

    @Test func removeSelected_selectsPreviousItemWhenRemovingLast() {
        let id1 = UUID()
        let id2 = UUID()
        let (viewModel, _, _, _, _) = createViewModel(with: [
            HotkeyBinding(id: id1, shortcutName: "a", appBundleIdentifier: "com.a", appName: "Apple"),
            HotkeyBinding(id: id2, shortcutName: "z", appBundleIdentifier: "com.z", appName: "Zebra")
        ])
        viewModel.selection = [id2]

        viewModel.removeSelected()

        #expect(viewModel.selection == [id1])
    }

    @Test func removeSelected_registersUndo() {
        let id = UUID()
        let (viewModel, _, _, mockUndoManager, _) = createViewModel(with: [
            HotkeyBinding(id: id, shortcutName: "test", appBundleIdentifier: "com.test", appName: "Test App")
        ])
        viewModel.selection = [id]

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
