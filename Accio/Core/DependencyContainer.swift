//
//  DependencyContainer.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import FactoryKit
import Foundation

// MARK: - Dependency Container

extension Container {
    // MARK: - Application Manager

    var applicationManager: Factory<ApplicationManagerProtocol> {
        self { StubApplicationManager() }
    }

    // MARK: - Hotkey Manager

    var hotkeyManager: Factory<HotkeyManagerProtocol> {
        self { StubHotkeyManager() }
    }

    // MARK: - Window Cycling Strategy

    var windowCyclingStrategy: Factory<WindowCyclingStrategyProtocol> {
        self { StubWindowCyclingStrategy() }
    }

    // MARK: - Window Manager

    var windowManager: Factory<WindowManager> {
        self { DefaultWindowManager() }
            .singleton
    }

    // MARK: - Permission Manager

    var permissionProvider: Factory<AccessibilityPermissionProvider> {
        self { DefaultAccessibilityPermissionProvider() }
            .singleton
    }

    var permissionMonitor: Factory<AccessibilityPermissionMonitor> {
        self { DefaultAccessibilityPermissionMonitor() }
            .singleton
    }

    // MARK: - Action Coordinator

    var actionCoordinator: Factory<ActionCoordinatorProtocol> {
        self { StubActionCoordinator() }
    }
}

// MARK: - Protocol Stubs (Temporary)

// These are placeholder protocols and stub implementations.
// We'll replace these with real protocols and implementations in later steps.

protocol ApplicationManagerProtocol {
    func launch(bundleIdentifier: String) throws
    func activate(bundleIdentifier: String) throws
    func hide(bundleIdentifier: String) throws
    func isRunning(bundleIdentifier: String) -> Bool
    func isFocused(bundleIdentifier: String) -> Bool
}

protocol HotkeyManagerProtocol {
    func register(name: String, handler: @escaping () -> Void)
    func unregister(name: String)
    func unregisterAll()
}

protocol WindowCyclingStrategyProtocol {
    func cycleWindows(for bundleIdentifier: String) throws
}


protocol ActionCoordinatorProtocol {
    func executeAction(for bundleIdentifier: String)
}

// MARK: - Stub Implementations

class StubApplicationManager: ApplicationManagerProtocol {
    func launch(bundleIdentifier: String) throws {
        print("Stub: Launch \(bundleIdentifier)")
    }

    func activate(bundleIdentifier: String) throws {
        print("Stub: Activate \(bundleIdentifier)")
    }

    func hide(bundleIdentifier: String) throws {
        print("Stub: Hide \(bundleIdentifier)")
    }

    func isRunning(bundleIdentifier: String) -> Bool {
        print("Stub: Check if \(bundleIdentifier) is running")
        return false
    }

    func isFocused(bundleIdentifier: String) -> Bool {
        print("Stub: Check if \(bundleIdentifier) is focused")
        return false
    }
}

class StubHotkeyManager: HotkeyManagerProtocol {
    func register(name: String, handler: @escaping () -> Void) {
        print("Stub: Register hotkey \(name)")
    }

    func unregister(name: String) {
        print("Stub: Unregister hotkey \(name)")
    }

    func unregisterAll() {
        print("Stub: Unregister all hotkeys")
    }
}

class StubWindowCyclingStrategy: WindowCyclingStrategyProtocol {
    func cycleWindows(for bundleIdentifier: String) throws {
        print("Stub: Cycle windows for \(bundleIdentifier)")
    }
}

class StubActionCoordinator: ActionCoordinatorProtocol {
    func executeAction(for bundleIdentifier: String) {
        print("Stub: Execute action for \(bundleIdentifier)")
    }
}
