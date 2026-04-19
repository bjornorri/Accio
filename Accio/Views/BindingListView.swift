//
//  BindingListView.swift
//  Accio
//

import AppKit
import FactoryKit
import SwiftUI
import UniformTypeIdentifiers

/// A view displaying hotkey bindings and app groups in macOS Settings style
struct BindingListView: View {
    @Injected(\.appMetadataProvider) private var appMetadataProvider
    @State private var viewModel = BindingListViewModel()
    @State private var coordinator: BindingListViewCoordinator?
    @State private var visibleItemIDs: Set<String> = []
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        Group {
            if viewModel.isEmpty {
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
            viewModel.refreshMetadata()
        }
        .onReceive(NotificationCenter.default.publisher(for: .performFind)) { _ in
            guard viewModel.isUndoEnabled else { return }
            isSearchFocused = true
        }
        .onAppear {
            viewModel.enableUndo()
            setupCoordinator()
        }
        .onDisappear {
            viewModel.disableUndo()
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

        newCoordinator.focusCoordinator.onListFocused = { [self] in
            viewModel.handleListFocused()
        }
        newCoordinator.focusCoordinator.isSearchFocused = { [self] in
            isSearchFocused
        }
        newCoordinator.focusCoordinator.setSearchFocused = { [self] focused in
            isSearchFocused = focused
        }

        newCoordinator.onAddItem = { [self] in addBinding() }

        newCoordinator.start()
        coordinator = newCoordinator
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
                    viewModel.addBindingFromDrop(url: url)
                }
            }
        }
    }

    // MARK: - Views

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Shortcuts", systemImage: "keyboard")
        } description: {
            Text("Press \(Image(systemName: "command"))N to add an application shortcut\nor drag apps here")
        } actions: {
            Menu {
                Button("Add App Shortcut") { addBinding() }
                Button("Add App Group") { addGroup() }
            } label: {
                Text("Add Shortcut")
            }
            .menuStyle(.automatic)
            .buttonStyle(.borderedProminent)
            .fixedSize()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listToolbar: some View {
        HStack(spacing: 0) {
            Menu {
                Button("Add App Shortcut") { addBinding() }
                Button("Add App Group") { addGroup() }
            } label: {
                Image(systemName: "plus")
                    .frame(width: 26, height: 22)
            }
            .menuStyle(.automatic)
            .menuIndicator(.hidden)
            .buttonStyle(.borderless)
            .fixedSize()

            Button {
                viewModel.removeSelected()
            } label: {
                Image(systemName: "minus")
                    .frame(width: 26, height: 22)
            }
            .buttonStyle(.borderless)
            .disabled(!viewModel.hasSelection)

            Spacer()
        }
        .frame(maxWidth: 800)
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(.bar)
    }

    private var bindingsList: some View {
        @Bindable var vm = viewModel
        let showSections = !viewModel.filteredBindingItems.isEmpty && !viewModel.filteredGroupItems.isEmpty
        return ScrollViewReader { proxy in
            List(selection: $vm.selection) {
                if showSections {
                    Section("App Groups") {
                        ForEach(viewModel.filteredGroupItems) { item in
                            itemView(for: item)
                                .id(item.id)
                                .onAppear { visibleItemIDs.insert(item.id) }
                                .onDisappear { visibleItemIDs.remove(item.id) }
                        }
                    }
                    Section("App Shortcuts") {
                        ForEach(viewModel.filteredBindingItems) { item in
                            itemView(for: item)
                                .id(item.id)
                                .onAppear { visibleItemIDs.insert(item.id) }
                                .onDisappear { visibleItemIDs.remove(item.id) }
                        }
                    }
                } else {
                    ForEach(viewModel.filteredItems) { item in
                        itemView(for: item)
                            .id(item.id)
                            .onAppear { visibleItemIDs.insert(item.id) }
                            .onDisappear { visibleItemIDs.remove(item.id) }
                    }
                }
            }
            .listStyle(.inset)
            .alternatingRowBackgrounds()
            .environment(\.defaultMinListRowHeight, 40)
            .searchable(text: $vm.searchText, placement: .toolbar)
            .searchFocused($isSearchFocused)
            .listKeyHandler(
                onDelete: {
                    if viewModel.hasSelection { viewModel.removeSelected() }
                },
                onReturn: {
                    if viewModel.selection.count == 1 { viewModel.activateSelectedRecorder() }
                },
                onSpace: {
                    if viewModel.selection.count == 1 { viewModel.activateSelectedRecorder() }
                },
                onEscape: {
                    if !viewModel.searchText.isEmpty { viewModel.searchText = "" }
                }
            )
            .onKeyPress(.leftArrow) {
                viewModel.collapseSelectedGroup()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                viewModel.expandSelectedGroup()
                return .handled
            }
            .onChange(of: isSearchFocused) { _, isFocused in
                if !isFocused { coordinator?.focusCoordinator.handleSearchFocusLost() }
            }
            .onChange(of: viewModel.scrollToID) { _, id in
                if let id {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        if !visibleItemIDs.contains(id) {
                            withAnimation { proxy.scrollTo(id, anchor: .center) }
                        }
                        viewModel.scrollToID = nil
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func itemView(for item: BindingListItem) -> some View {
        @Bindable var vm = viewModel
        switch item {
        case .binding(let binding):
            BindingRowView(
                binding: binding,
                appMetadataProvider: appMetadataProvider,
                refreshTrigger: viewModel.refreshTrigger,
                shouldActivateRecorder: binding.id == viewModel.activeRecorderID,
                onRecorderActivated: { viewModel.onRecorderActivated(for: binding) },
                onRecorderDeactivated: {
                    viewModel.onRecorderDeactivated()
                    coordinator?.focusCoordinator.focusList()
                }
            )
            .tag("binding:\(binding.id.uuidString)")
            .contextMenu {
                Button("Record Shortcut") {
                    viewModel.selection = ["binding:\(binding.id.uuidString)"]
                    viewModel.activateRecorder(for: binding.id)
                }
                Divider()
                Button("Remove", role: .destructive) {
                    viewModel.selection = ["binding:\(binding.id.uuidString)"]
                    viewModel.removeSelected()
                }
            }

        case .group(let group):
            AppGroupRowView(
                group: group,
                appMetadataProvider: appMetadataProvider,
                refreshTrigger: viewModel.refreshTrigger,
                shouldActivateRecorder: group.id == viewModel.activeRecorderID,
                isExpanded: viewModel.expandedGroupIDs.contains(group.id),
                isRenaming: group.id == viewModel.renamingGroupID,
                renamingText: $vm.pendingGroupName,
                onToggleExpanded: { viewModel.toggleExpanded(group.id) },
                onBeginRename: { viewModel.beginRename(for: group.id) },
                onConfirmRename: { viewModel.confirmRename() },
                onCancelRename: { viewModel.cancelRename() },
                onRecorderActivated: { viewModel.onGroupRecorderActivated(for: group) },
                onRecorderDeactivated: {
                    viewModel.onRecorderDeactivated()
                    coordinator?.focusCoordinator.focusList()
                }
            )
            .tag("group:\(group.id.uuidString)")
            .contextMenu {
                Button("Record Shortcut") {
                    viewModel.selection = ["group:\(group.id.uuidString)"]
                    viewModel.activateRecorder(for: group.id)
                }
                Button("Rename") {
                    viewModel.selection = ["group:\(group.id.uuidString)"]
                    viewModel.beginRename(for: group.id)
                }
                Divider()
                Button("Remove", role: .destructive) {
                    viewModel.selection = ["group:\(group.id.uuidString)"]
                    viewModel.removeSelected()
                }
            }

        case .groupMember(let member, let groupID, let showMostRecentLabel):
            GroupMemberRowView(
                member: member,
                appMetadataProvider: appMetadataProvider,
                refreshTrigger: viewModel.refreshTrigger,
                showMostRecentLabel: showMostRecentLabel,
                onRemove: { viewModel.removeAppFromGroup(bundleIdentifier: member.bundleIdentifier, groupID: groupID) }
            )

        case .addAppToGroup(let groupID):
            Button {
                viewModel.addAppsToGroup(groupID: groupID)
            } label: {
                Label("Add App...", systemImage: "plus")
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
            .padding(.leading, 52)
            .padding(.vertical, 4)
            .selectionDisabled(true)
        }
    }

    // MARK: - Actions

    private func addBinding() {
        let wasSearchFocused = isSearchFocused
        let wasListFocused = coordinator?.focusCoordinator.isListFocused() ?? false

        let didAdd = viewModel.addBindingFromPanel()

        if didAdd {
            DispatchQueue.main.async {
                coordinator?.focusCoordinator.focusList()
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

    private func addGroup() {
        viewModel.addGroup()
        DispatchQueue.main.async {
            coordinator?.focusCoordinator.focusList()
        }
    }
}

#Preview {
    BindingListView()
        .frame(width: 450, height: 350)
}
