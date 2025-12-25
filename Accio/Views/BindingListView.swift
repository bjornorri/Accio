//
//  BindingListView.swift
//  Accio
//

import AppKit
import Defaults
import KeyboardShortcuts
import SwiftUI
import UniformTypeIdentifiers

/// A view displaying hotkey bindings in macOS Settings style
struct BindingListView: View {
    @Default(.hotkeyBindings) private var bindings
    @State private var selection: HotkeyBinding.ID?

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
                .disabled(selection == nil)

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
                BindingRowView(binding: binding)
                    .tag(binding.id)
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

                let id = UUID()
                let newBinding = HotkeyBinding(
                    id: id,
                    shortcutName: "binding-\(id.uuidString)",
                    appBundleIdentifier: bundleIdentifier
                )
                bindings.append(newBinding)
                selection = id
            }
        }
    }

    private func removeSelected() {
        guard let selectedId = selection,
              let binding = bindings.first(where: { $0.id == selectedId }) else {
            return
        }

        // Clear the shortcut
        let name = KeyboardShortcuts.Name(binding.shortcutName)
        KeyboardShortcuts.setShortcut(nil, for: name)

        // Remove binding
        bindings.removeAll { $0.id == selectedId }
        selection = nil
    }
}

/// A row displaying app icon, name, and shortcut recorder
struct BindingRowView: View {
    let binding: HotkeyBinding

    private var appName: String {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: binding.appBundleIdentifier),
           let bundle = Bundle(url: appURL) {
            return bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? appURL.deletingPathExtension().lastPathComponent
        }
        return binding.appBundleIdentifier
    }

    private var appIcon: NSImage? {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: binding.appBundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }
        return nil
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
                Image(systemName: "app")
                    .frame(width: 20, height: 20)
                    .foregroundColor(.secondary)
            }

            // App name
            Text(appName)
                .lineLimit(1)

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
