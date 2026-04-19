//
//  NSWorkspaceGroupOrderTracker.swift
//  Accio
//

import AppKit
import FactoryKit

/// NSWorkspace-based implementation of GroupOrderTracker.
///
/// Observes system-wide app activations and moves recently-used apps
/// to the front of their groups' member lists.
final class NSWorkspaceGroupOrderTracker: GroupOrderTracker {
    @Injected(\.appGroupStore) private var groupStore: AppGroupStore

    private var observer: NSObjectProtocol?

    func start() {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleID = app.bundleIdentifier else { return }
            self?.handleAppActivation(bundleIdentifier: bundleID)
        }
    }

    func stop() {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observer = nil
    }

    private func handleAppActivation(bundleIdentifier: String) {
        var groups = groupStore.groups
        var changed = false

        for i in groups.indices {
            guard let memberIndex = groups[i].members.firstIndex(where: { $0.bundleIdentifier == bundleIdentifier }),
                  memberIndex > 0 else { continue }

            let member = groups[i].members.remove(at: memberIndex)
            groups[i].members.insert(member, at: 0)
            changed = true
        }

        if changed {
            groupStore.groups = groups
        }
    }
}
