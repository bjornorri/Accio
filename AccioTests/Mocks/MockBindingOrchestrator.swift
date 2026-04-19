//
//  MockBindingOrchestrator.swift
//  AccioTests
//

import Foundation
@testable import Accio

final class MockBindingOrchestrator: BindingOrchestrator {
    var startCalled = false
    var stopCalled = false
    var conflictToReturn: ShortcutConflict?
    var clearedItems: [ShortcutConflict.Item] = []

    func start() {
        startCalled = true
    }

    func stop() {
        stopCalled = true
    }

    func findConflict(for shortcutName: String) -> ShortcutConflict? {
        conflictToReturn
    }

    func clearShortcut(for item: ShortcutConflict.Item) {
        clearedItems.append(item)
    }
}
