//
//  MockHotkeyManager.swift
//  AccioTests
//

import Foundation
@testable import Accio

final class MockHotkeyManager: HotkeyManager {
    var registeredNames: [String] = []
    var unregisteredNames: [String] = []
    var handlers: [String: () async -> Void] = [:]
    var pauseAllCalled = false
    var resumeAllCalled = false

    func register(name: String, handler: @escaping () async -> Void) {
        registeredNames.append(name)
        handlers[name] = handler
    }

    func unregister(name: String) {
        unregisteredNames.append(name)
        handlers.removeValue(forKey: name)
    }

    func unregisterAll() {
        unregisteredNames.append(contentsOf: handlers.keys)
        handlers.removeAll()
    }

    func pauseAll() {
        pauseAllCalled = true
    }

    func resumeAll() {
        resumeAllCalled = true
    }
}
