//
//  BindingRowView.swift
//  Accio
//

import KeyboardShortcuts
import SwiftUI

/// A row displaying app icon, name, and shortcut recorder
struct BindingRowView: View {
    let binding: HotkeyBinding
    let appMetadataProvider: AppMetadataProvider
    let refreshTrigger: Bool
    var shouldActivateRecorder: Bool = false
    var onRecorderActivated: (() -> Void)?
    var onRecorderDeactivated: (() -> Void)?

    private var isAppInstalled: Bool {
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
}
