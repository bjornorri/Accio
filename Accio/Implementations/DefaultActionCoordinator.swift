//
//  DefaultActionCoordinator.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import FactoryKit
import Foundation

/// Default implementation of ActionCoordinator that executes actions based on app state
final class DefaultActionCoordinator: ActionCoordinator {
    @Injected(\.applicationManager) private var applicationManager: ApplicationManager
    @Injected(\.windowCycler) private var windowCycler: WindowCycler

    func executeAction(for bundleIdentifier: String, settings: AppBehaviorSettings) async {
        let isRunning = applicationManager.isRunning(bundleIdentifier: bundleIdentifier)

        if !isRunning {
            // App is not running - apply whenNotRunning action
            switch settings.whenNotRunning {
            case .launchApp:
                do {
                    try await applicationManager.launch(bundleIdentifier: bundleIdentifier)
                } catch {
                    print("Failed to launch app: \(error)")
                }
            case .doNothing:
                break
            }
            // After launching, the app will be focused, so we're done
            return
        }

        // App is running - check if focused
        let isFocused = applicationManager.isFocused(bundleIdentifier: bundleIdentifier)

        if !isFocused {
            // App is running but not focused - apply whenNotFocused action
            switch settings.whenNotFocused {
            case .focusApp:
                do {
                    try applicationManager.activate(bundleIdentifier: bundleIdentifier)
                } catch {
                    print("Failed to activate app: \(error)")
                }
            case .doNothing:
                break
            }
            return
        }

        // App is running and focused - apply whenFocused action
        switch settings.whenFocused {
        case .cycleWindows:
            do {
                try windowCycler.cycleWindows(for: bundleIdentifier)
            } catch {
                print("Failed to cycle windows: \(error)")
            }
        case .hideApp:
            do {
                try applicationManager.hide(bundleIdentifier: bundleIdentifier)
            } catch {
                print("Failed to hide app: \(error)")
            }
        case .doNothing:
            break
        }
    }
}
