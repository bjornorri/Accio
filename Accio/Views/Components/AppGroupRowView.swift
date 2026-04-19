//
//  AppGroupRowView.swift
//  Accio
//

import KeyboardShortcuts
import SwiftUI

/// A row displaying an app group's icons, name, and shortcut recorder
struct AppGroupRowView: View {
    let group: AppGroup
    let appMetadataProvider: AppMetadataProvider
    let refreshTrigger: Bool
    var shouldActivateRecorder: Bool = false
    var isExpanded: Bool = false
    var isRenaming: Bool = false
    @Binding var renamingText: String
    var onToggleExpanded: () -> Void
    var onBeginRename: () -> Void
    var onConfirmRename: () -> Void
    var onCancelRename: () -> Void
    var onRecorderActivated: (() -> Void)?
    var onRecorderDeactivated: (() -> Void)?

    @FocusState private var isNameFocused: Bool

    private var shortcutName: KeyboardShortcuts.Name {
        KeyboardShortcuts.Name(group.shortcutName)
    }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                onToggleExpanded()
            } label: {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .frame(width: 10)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            groupIconView
                .frame(width: 32, height: 32)

            // Name area — double-click to rename
            HStack(spacing: 0) {
                if isRenaming {
                    TextField("", text: $renamingText)
                        .textFieldStyle(.plain)
                        .focused($isNameFocused)
                        .onSubmit { onConfirmRename() }
                        .onKeyPress(.escape) {
                            onCancelRename()
                            return .handled
                        }
                        .onChange(of: isNameFocused) { _, focused in
                            if !focused { onConfirmRename() }
                        }
                        .onAppear { isNameFocused = true }
                } else {
                    Text(group.name)
                        .lineLimit(1)
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                if !isRenaming { onBeginRename() }
            }

            ShortcutRecorder(
                name: shortcutName,
                shouldActivate: shouldActivateRecorder,
                onActivated: onRecorderActivated,
                onDeactivated: onRecorderDeactivated
            )
            .focusable(false)
        }
        .padding(.vertical, 4)
    }

    private var groupIconImages: [NSImage] {
        _ = refreshTrigger
        return group.members.prefix(3).compactMap {
            appMetadataProvider.appIcon(for: $0.bundleIdentifier)
        }
    }

    @ViewBuilder
    private var groupIconView: some View {
        let icons = groupIconImages
        if icons.isEmpty {
            Image(systemName: "square.stack.3d.up")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
        } else if icons.count == 1 {
            Image(nsImage: icons[0])
                .resizable()
                .frame(width: 32, height: 32)
        } else {
            ZStack {
                ForEach(Array(icons.enumerated().reversed()), id: \.offset) { index, icon in
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 26, height: 26)
                        .offset(x: CGFloat(index) * 4, y: CGFloat(index) * (-2))
                }
            }
            .frame(width: 32, height: 32)
        }
    }
}
