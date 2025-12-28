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
    var clearedShortcutIDs: [HotkeyBinding.ID] = []

    func start() {
        startCalled = true
    }

    func stop() {
        stopCalled = true
    }

    func findConflict(for bindingId: HotkeyBinding.ID) -> ShortcutConflict? {
        conflictToReturn
    }

    func clearShortcut(for bindingId: HotkeyBinding.ID) {
        clearedShortcutIDs.append(bindingId)
    }
}
