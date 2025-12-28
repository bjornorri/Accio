//
//  AccioApp.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import SwiftUI

@main
struct AccioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar app - no window scenes
        // Settings window is managed by WindowManager
        Settings {
            EmptyView()
        }
        .commands {
            // Remove the native Settings menu item
            CommandGroup(replacing: .appSettings) { }

            // Add Edit > Find menu item
            CommandGroup(after: .textEditing) {
                Button("Find") {
                    NotificationCenter.default.post(name: .performFind, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
    }
}
