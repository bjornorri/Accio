//
//  GroupMemberRowView.swift
//  Accio
//

import SwiftUI

/// A row displaying a single member app within an expanded group
struct GroupMemberRowView: View {
    let member: AppGroupMember
    let appMetadataProvider: AppMetadataProvider
    let refreshTrigger: Bool
    var showMostRecentLabel: Bool = false
    var onRemove: () -> Void

    private var appIcon: NSImage? {
        _ = refreshTrigger
        return appMetadataProvider.appIcon(for: member.bundleIdentifier)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Indent to align with group content
            Color.clear
                .frame(width: 22)

            if let icon = appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.body)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.yellow)
            }

            Text(member.appName)
                .lineLimit(1)
                .foregroundStyle(.primary)

            if showMostRecentLabel {
                Text("Most Recent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
            }

            Spacer()

            Button(role: .destructive) {
                onRemove()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 3)
    }
}
