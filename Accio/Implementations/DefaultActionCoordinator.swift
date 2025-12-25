//
//  DefaultActionCoordinator.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import FactoryKit
import Foundation

/// Default implementation of ActionCoordinator that executes actions based on app state
class DefaultActionCoordinator: ActionCoordinator {
    @Injected(\.applicationManager) private var applicationManager: ApplicationManager
    @Injected(\.windowCycler) private var windowCycler: WindowCycler

    func executeAction(for bundleIdentifier: String, settings: AppBehaviorSettings) async {
        // Check if app is running (on MainActor for accurate state)
        let isRunning = await MainActor.run {
            applicationManager.isRunning(bundleIdentifier: bundleIdentifier)
        }

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
                return
            }
            // After launching, the app will be focused, so we're done
            return
        }

        // App is running - check state and act atomically on MainActor
        do {
            try await MainActor.run {
                let isFocused = applicationManager.isFocused(bundleIdentifier: bundleIdentifier)

                if !isFocused {
                    // App is running but not focused - apply whenNotFocused action
                    switch settings.whenNotFocused {
                    case .focusApp:
                        try applicationManager.activate(bundleIdentifier: bundleIdentifier)
                    case .doNothing:
                        break
                    }
                    return
                }

                // App is running and focused - apply whenFocused action
                switch settings.whenFocused {
                case .cycleWindows:
                    try windowCycler.cycleWindows(for: bundleIdentifier)
                case .hideApp:
                    try applicationManager.hide(bundleIdentifier: bundleIdentifier)
                case .doNothing:
                    break
                }
            }
        } catch {
            print("Action failed: \(error)")
        }
    }
}
