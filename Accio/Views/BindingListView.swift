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
    @State private var newlyAddedBindingID: HotkeyBinding.ID?
    @State private var focusedBindingID: HotkeyBinding.ID?
    @State private var keyboardHandler: BindingListKeyboardHandler?

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
            // Update cached app metadata for installed apps, then trigger refresh
            updateAppMetadata()
            refreshTrigger.toggle()
        }
        .onAppear {
            setupKeyboardHandler()
        }
        .onDisappear {
            keyboardHandler?.stop()
            keyboardHandler = nil
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

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
              let bundleIdentifier = bundle.bundleIdentifier else {
            return
        }

        // Skip if app is already in the list
        guard !bindings.contains(where: { $0.appBundleIdentifier == bundleIdentifier }) else {
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

    private func setupKeyboardHandler() {
        let handler = BindingListKeyboardHandler(
            hasSelection: { !selection.isEmpty },
            hasSingleSelection: { selection.count == 1 },
            onAddItem: { addBinding() },
            onRemoveSelected: { removeSelected() },
            onFocusSelected: {
                if let selectedID = selection.first {
                    focusedBindingID = selectedID
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focusedBindingID = nil
                    }
                }
            }
        )
        handler.start()
        keyboardHandler = handler
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
            bindings = updatedBindings
        }
    }

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

    private var filteredBindings: [HotkeyBinding] {
        let sorted = bindings.sorted { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter { $0.appName.localizedCaseInsensitiveContains(searchText) }
    }

    private var bindingsList: some View {
        ScrollViewReader { proxy in
            List(selection: $selection) {
                ForEach(filteredBindings) { binding in
                    BindingRowView(
                        binding: binding,
                        appMetadataProvider: appMetadataProvider,
                        refreshTrigger: refreshTrigger,
                        shouldFocus: binding.id == newlyAddedBindingID || binding.id == focusedBindingID
                    )
                    .tag(binding.id)
                    .id(binding.id)
                }
            }
            .listStyle(.inset)
            .alternatingRowBackgrounds()
            .environment(\.defaultMinListRowHeight, 40)
            .searchable(text: $searchText, placement: .toolbar)
            .onChange(of: newlyAddedBindingID) { _, newID in
                if let id = newID {
                    withAnimation {
                        proxy.scrollTo(id, anchor: .top)
                    }
                    // Clear the flag after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        newlyAddedBindingID = nil
                    }
                }
            }
        }
    }

    private func addBinding() {
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
                      let bundleIdentifier = bundle.bundleIdentifier else {
                    continue
                }

                // Skip if app is already in the list
                guard !bindings.contains(where: { $0.appBundleIdentifier == bundleIdentifier }) else {
                    continue
                }

                // Capture app name at creation time
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
                // Only auto-focus recorder when adding a single app
                if addedIDs.count == 1 {
                    newlyAddedBindingID = firstID
                }
            }
        }
    }

    private func removeSelected() {
        guard !selection.isEmpty else { return }

        // Clear shortcuts and remove bindings for all selected items
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

/// A row displaying app icon, name, and shortcut recorder
struct BindingRowView: View {
    let binding: HotkeyBinding
    let appMetadataProvider: AppMetadataProvider
    let refreshTrigger: Bool
    let shouldFocus: Bool

    private var isAppInstalled: Bool {
        // refreshTrigger ensures this is re-evaluated when window becomes active
        _ = refreshTrigger
        return appMetadataProvider.isInstalled(binding.appBundleIdentifier)
    }

    private var appIcon: NSImage? {
        _ = refreshTrigger
        return appMetadataProvider.appIcon(for: binding.appBundleIdentifier)
    }

    private var shortcutName: KeyboardShortcuts.Name {
        KeyboardShortcuts.Name(binding.shortcutName)
    }

    var body: some View {
        HStack(spacing: 10) {
            // App icon
            if let icon = appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.yellow)
            }

            // App name (use cached name from binding)
            VStack(alignment: .leading, spacing: 2) {
                Text(binding.appName)
                    .lineLimit(1)
                    .foregroundStyle(isAppInstalled ? .primary : .secondary)

                if !isAppInstalled {
                    Text("Not Installed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Shortcut recorder
            FocusableRecorder(name: shortcutName, shouldFocus: shouldFocus)
                .focusable(false)
        }
        .padding(.vertical, 4)
    }
}

/// A keyboard shortcut recorder that can be focused programmatically
struct FocusableRecorder: NSViewRepresentable {
    let name: KeyboardShortcuts.Name
    let shouldFocus: Bool

    func makeNSView(context: Context) -> KeyboardShortcuts.RecorderCocoa {
        KeyboardShortcuts.RecorderCocoa(for: name)
    }

    func updateNSView(_ recorder: KeyboardShortcuts.RecorderCocoa, context: Context) {
        if shouldFocus {
            DispatchQueue.main.async {
                recorder.window?.makeFirstResponder(recorder)
            }
        }
    }
}

#Preview {
    BindingListView()
        .frame(width: 450, height: 350)
}
