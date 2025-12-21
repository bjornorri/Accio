//
//  NSWorkspaceApplicationManager.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 16.12.2025.
//

import AppKit

/// NSWorkspace-based implementation of ApplicationManager
final class NSWorkspaceApplicationManager: ApplicationManager {
    private let workspace = NSWorkspace.shared

    enum ApplicationManagerError: Error, LocalizedError {
        case applicationNotFound(bundleIdentifier: String)
        case launchFailed(bundleIdentifier: String)
        case activationFailed(bundleIdentifier: String)
        case hideFailed(bundleIdentifier: String)

        var errorDescription: String? {
            switch self {
            case .applicationNotFound(let bundleIdentifier):
                return "Application with bundle identifier '\(bundleIdentifier)' not found"
            case .launchFailed(let bundleIdentifier):
                return "Failed to launch application '\(bundleIdentifier)'"
            case .activationFailed(let bundleIdentifier):
                return "Failed to activate application '\(bundleIdentifier)'"
            case .hideFailed(let bundleIdentifier):
                return "Failed to hide application '\(bundleIdentifier)'"
            }
        }
    }

    func launch(bundleIdentifier: String) async throws {
        // Get the URL for the application
        guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            throw ApplicationManagerError.applicationNotFound(bundleIdentifier: bundleIdentifier)
        }

        // Launch the application
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        do {
            try await workspace.openApplication(at: appURL, configuration: configuration)
        } catch {
            throw ApplicationManagerError.launchFailed(bundleIdentifier: bundleIdentifier)
        }
    }

    func activate(bundleIdentifier: String) throws {
        // Find the running application
        guard let app = workspace.runningApplications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            throw ApplicationManagerError.applicationNotFound(bundleIdentifier: bundleIdentifier)
        }

        // Activate the application
        let success: Bool
        if #available(macOS 14.0, *) {
            // On macOS 14+, ignoringOtherApps has no effect and is deprecated
            success = app.activate(options: [])
        } else {
            // On macOS 13 and earlier, preserve previous behavior
            success = app.activate(options: [.activateIgnoringOtherApps])
        }
        if !success {
            throw ApplicationManagerError.activationFailed(bundleIdentifier: bundleIdentifier)
        }
    }

    func isRunning(bundleIdentifier: String) -> Bool {
        return workspace.runningApplications.contains { $0.bundleIdentifier == bundleIdentifier }
    }

    func isFocused(bundleIdentifier: String) -> Bool {
        guard let frontmostApp = workspace.frontmostApplication else {
            return false
        }
        return frontmostApp.bundleIdentifier == bundleIdentifier
    }

    func hide(bundleIdentifier: String) throws {
        // Find the running application
        guard let app = workspace.runningApplications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            throw ApplicationManagerError.applicationNotFound(bundleIdentifier: bundleIdentifier)
        }

        // Hide the application
        let success = app.hide()
        if !success {
            throw ApplicationManagerError.hideFailed(bundleIdentifier: bundleIdentifier)
        }
    }
}

