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
    @State private var refreshTrigger = false

    var body: some View {
        VStack(spacing: 0) {
            if bindings.isEmpty {
                emptyStateView
            } else {
                bindingsList
            }

            // +/- toolbar at bottom
            HStack(spacing: 0) {
                Button {
                    addBinding()
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)

                Divider()
                    .frame(height: 16)

                Button {
                    removeSelected()
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .disabled(selection.isEmpty)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            // Update cached app metadata for installed apps, then trigger refresh
            updateAppMetadata()
            refreshTrigger.toggle()
        }
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
        VStack(spacing: 8) {
            Text("No Hotkeys")
                .foregroundColor(.secondary)
            Text("Click + to add an application")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
    }

    private var bindingsList: some View {
        List(selection: $selection) {
            ForEach(bindings) { binding in
                BindingRowView(
                    binding: binding,
                    appMetadataProvider: appMetadataProvider,
                    refreshTrigger: refreshTrigger
                )
                .tag(binding.id)
            }
            .onMove { source, destination in
                bindings.move(fromOffsets: source, toOffset: destination)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func addBinding() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Choose an application"
        panel.prompt = "Add"

        if panel.runModal() == .OK, let url = panel.url {
            if let bundle = Bundle(url: url),
               let bundleIdentifier = bundle.bundleIdentifier {
                // Check if app is already in the list
                guard !bindings.contains(where: { $0.appBundleIdentifier == bundleIdentifier }) else {
                    return
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
                selection = [id]
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
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .frame(width: 20, height: 20)
                    .foregroundColor(.yellow)
            }

            // App name (use cached name from binding)
            Text(binding.appName)
                .lineLimit(1)
                .foregroundColor(isAppInstalled ? .primary : .secondary)

            if !isAppInstalled {
                Text("(Not Installed)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Shortcut recorder
            KeyboardShortcuts.Recorder(for: shortcutName)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    BindingListView()
        .frame(width: 450, height: 350)
}
