//
//  BindingListView.swift
//  Accio
//

import AppKit
import FactoryKit
import SwiftUI
import UniformTypeIdentifiers

/// A view displaying hotkey bindings in macOS Settings style
struct BindingListView: View {
    @Injected(\.appMetadataProvider) private var appMetadataProvider
    @State private var viewModel = BindingListViewModel()
    @State private var coordinator: BindingListViewCoordinator?
    @State private var visibleBindingIDs: Set<HotkeyBinding.ID> = []
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

        // Configure focus coordinator
        newCoordinator.focusCoordinator.onListFocused = { [self] in
            viewModel.handleListFocused()
        }
        newCoordinator.focusCoordinator.isSearchFocused = { [self] in
            isSearchFocused
        }
        newCoordinator.focusCoordinator.setSearchFocused = { [self] focused in
            isSearchFocused = focused
        }

        // Configure state callbacks
        newCoordinator.checkHasSelection = { [self] in viewModel.hasSelection }
        newCoordinator.checkHasSingleSelection = { [self] in viewModel.selection.count == 1 }
        newCoordinator.checkHasFilter = { [self] in !viewModel.searchText.isEmpty }

        // Configure action callbacks
        newCoordinator.onAddItem = { [self] in addBinding() }
        newCoordinator.onRemoveSelected = { [self] in viewModel.removeSelected() }
        newCoordinator.onFocusSearch = { [self] in isSearchFocused = true }
        newCoordinator.onActivateSelected = { [self] in viewModel.activateSelectedRecorder() }
        newCoordinator.onClearFilter = { [self] in viewModel.searchText = "" }

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
                viewModel.removeSelected()
            } label: {
                Image(systemName: "minus")
            }
            .buttonStyle(.borderless)
            .disabled(!viewModel.hasSelection)

            Spacer()
        }
        .frame(maxWidth: 800)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(.bar)
    }

    private var bindingsList: some View {
        ScrollViewReader { proxy in
            List(selection: $viewModel.selection) {
                ForEach(viewModel.filteredBindings) { binding in
                    BindingRowView(
                        binding: binding,
                        appMetadataProvider: appMetadataProvider,
                        refreshTrigger: viewModel.refreshTrigger,
                        shouldActivateRecorder: binding.id == viewModel.activeRecorderID,
                        onRecorderActivated: { [self] in
                            viewModel.onRecorderActivated(for: binding)
                        },
                        onRecorderDeactivated: { [self] in
                            viewModel.onRecorderDeactivated()
                            coordinator?.focusCoordinator.focusList()
                        }
                    )
                    .tag(binding.id)
                    .id(binding.id)
                    .onAppear { visibleBindingIDs.insert(binding.id) }
                    .onDisappear { visibleBindingIDs.remove(binding.id) }
                    .contextMenu {
                        Button("Record Shortcut") {
                            viewModel.selection = [binding.id]
                            viewModel.activateRecorder(for: binding.id)
                        }
                        Divider()
                        Button("Remove", role: .destructive) {
                            viewModel.selection = [binding.id]
                            viewModel.removeSelected()
                        }
                    }
                }
            }
            .listStyle(.inset)
            .alternatingRowBackgrounds()
            .environment(\.defaultMinListRowHeight, 40)
            .searchable(text: $viewModel.searchText, placement: .toolbar)
            .searchFocused($isSearchFocused)
            .onChange(of: isSearchFocused) { _, isFocused in
                if !isFocused {
                    coordinator?.focusCoordinator.handleSearchFocusLost()
                }
            }
            .onChange(of: viewModel.scrollToID) { _, id in
                if let id {
                    // Delay to allow the new row to appear and update visibleBindingIDs
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        if !visibleBindingIDs.contains(id) {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                        viewModel.scrollToID = nil
                    }
                }
            }
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
            // Panel was cancelled - restore focus
            if wasSearchFocused {
                isSearchFocused = true
            } else if wasListFocused {
                DispatchQueue.main.async {
                    coordinator?.focusCoordinator.focusList()
                }
            }
        }
    }
}

#Preview {
    BindingListView()
        .frame(width: 450, height: 350)
}
