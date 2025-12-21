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

    var applicationManager: Factory<ApplicationManager> {
        self { NSWorkspaceApplicationManager() }
    }

    // MARK: - Hotkey Manager

    var hotkeyManager: Factory<HotkeyManager> {
        self { KeyboardShortcutsHotkeyManager() }
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

    // MARK: - Clock

    var clock: Factory<any Clock<Duration>> {
        self { ContinuousClock() }
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

protocol WindowCyclingStrategyProtocol {
    func cycleWindows(for bundleIdentifier: String) throws
}

protocol ActionCoordinatorProtocol {
    func executeAction(for bundleIdentifier: String)
}

// MARK: - Stub Implementations

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
