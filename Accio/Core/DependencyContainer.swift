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
        self { @MainActor in NSWorkspaceAppMetadataProvider() }
    }

    // MARK: - Application Manager

    var applicationManager: Factory<ApplicationManager> {
        self { @MainActor in NSWorkspaceApplicationManager() }
    }

    // MARK: - Hotkey Manager

    var hotkeyManager: Factory<HotkeyManager> {
        self { @MainActor in  KeyboardShortcutsHotkeyManager() }
    }

    // MARK: - System Shortcut Reader

    var systemShortcutReader: Factory<SystemShortcutReader> {
        self { @MainActor in  DefaultSystemShortcutReader() }
    }

    // MARK: - Keyboard Event Poster

    var keyboardEventPoster: Factory<KeyboardEventPoster> {
        self { @MainActor in  CGEventKeyboardEventPoster() }
    }

    // MARK: - Window Cycler

    var windowCycler: Factory<WindowCycler> {
        self { @MainActor in  SystemWindowCycler() }
    }

    // MARK: - Action Coordinator

    var actionCoordinator: Factory<ActionCoordinator> {
        self { @MainActor in  DefaultActionCoordinator() }
    }

    // MARK: - Notification Poster

    var notificationPoster: Factory<NotificationPoster> {
        self { @MainActor in UserNotificationPoster() }
            .singleton
    }

    // MARK: - Binding Orchestrator

    var bindingOrchestrator: Factory<BindingOrchestrator> {
        self { @MainActor in  DefaultBindingOrchestrator() }
            .singleton
    }

    // MARK: - Window Manager

    var windowManager: Factory<WindowManager> {
        self { @MainActor in  DefaultWindowManager() }
            .singleton
    }

    // MARK: - Permission Manager

    var permissionProvider: Factory<AccessibilityPermissionProvider> {
        self { @MainActor in  DefaultAccessibilityPermissionProvider() }
            .singleton
    }

    var permissionMonitor: Factory<AccessibilityPermissionMonitor> {
        self { @MainActor in  DefaultAccessibilityPermissionMonitor() }
            .singleton
    }

    // MARK: - Clock

    var clock: Factory<any Clock<Duration>> {
        self { ContinuousClock() }
            .singleton
    }

    // MARK: - Binding Undo Manager

    var bindingUndoManager: Factory<BindingUndoManager> {
        self { DefaultBindingUndoManager() }
            .singleton
    }

    // MARK: - Binding Store

    var bindingStore: Factory<BindingStore> {
        self { DefaultsBindingStore() }
            .singleton
    }

    // MARK: - App Info Provider

    var appInfoProvider: Factory<AppInfoProvider> {
        self { BundleAppInfoProvider() }
    }

    // MARK: - App Settings Store

    var appSettingsStore: Factory<AppSettingsStore> {
        self { DefaultsAppSettingsStore() }
            .singleton
    }
}
