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
    // MARK: - App Metadata Provider

    var appMetadataProvider: Factory<AppMetadataProvider> {
        self { NSWorkspaceAppMetadataProvider() }
    }

    // MARK: - Application Manager

    var applicationManager: Factory<ApplicationManager> {
        self { NSWorkspaceApplicationManager() }
    }

    // MARK: - Hotkey Manager

    var hotkeyManager: Factory<HotkeyManager> {
        self { KeyboardShortcutsHotkeyManager() }
    }

    // MARK: - System Shortcut Reader

    var systemShortcutReader: Factory<SystemShortcutReader> {
        self { DefaultSystemShortcutReader() }
    }

    // MARK: - Keyboard Event Poster

    var keyboardEventPoster: Factory<KeyboardEventPoster> {
        self { CGEventKeyboardEventPoster() }
    }

    // MARK: - Window Cycler

    var windowCycler: Factory<WindowCycler> {
        self { SystemWindowCycler() }
    }

    // MARK: - Action Coordinator

    var actionCoordinator: Factory<ActionCoordinator> {
        self { DefaultActionCoordinator() }
    }

    // MARK: - Binding Orchestrator

    var bindingOrchestrator: Factory<BindingOrchestrator> {
        self { DefaultBindingOrchestrator() }
            .singleton
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
}
