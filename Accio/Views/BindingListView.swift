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
    @Default(.hotkeyBindings) private var bindings
    @State private var selection: Set<HotkeyBinding.ID> = []
    @State private var searchText = ""
    @State private var refreshTrigger = false
    @State private var activeRecorderID: HotkeyBinding.ID?
    @State private var coordinator: BindingListViewCoordinator?
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
        .onAppear {
            setupCoordinator()
        }
        .onDisappear {
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
        activeRecorderID = selectedID
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
                        onRecorderActivated: {
                            selection = [binding.id]
                        },
                        onRecorderDeactivated: { [self] in
                            coordinator?.focusCoordinator.focusList()
                        }
                    )
                    .tag(binding.id)
                    .id(binding.id)
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

        for selectedId in selection {
            if let binding = bindings.first(where: { $0.id == selectedId }) {
                let name = KeyboardShortcuts.Name(binding.shortcutName)
                KeyboardShortcuts.setShortcut(nil, for: name)
            }
        }

        bindings.removeAll { selection.contains($0.id) }
        selection = []
    }
}

#Preview {
    BindingListView()
        .frame(width: 450, height: 350)
}
