//
//  AccioApp.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 14.12.2025.
//

import FactoryKit
import SwiftUI

@main
struct AccioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private var undoManager: BindingUndoManager { Container.shared.bindingUndoManager() }

    var body: some Scene {
        // Menu bar app - no window scenes
        // Settings window is managed by WindowManager
        Settings {
            EmptyView()
        }
        .commands {
            // Remove the native Settings menu item
            CommandGroup(replacing: .appSettings) { }

            // Undo/Redo menu items
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    undoManager.undo()
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!undoManager.isEnabled || !undoManager.canUndo)

                Button("Redo") {
                    undoManager.redo()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!undoManager.isEnabled || !undoManager.canRedo)
            }

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
