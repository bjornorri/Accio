//
//  SystemWindowCycler.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import CoreGraphics
import FactoryKit
import Foundation

/// Window cycler that triggers the system's window cycling shortcut
class SystemWindowCycler: WindowCycler {
    @Injected(\.systemShortcutReader) private var shortcutReader: SystemShortcutReader
    @Injected(\.keyboardEventPoster) private var eventPoster: KeyboardEventPoster

    func cycleWindows(for bundleIdentifier: String) throws {
        let shortcut = shortcutReader.readWindowCyclingShortcut()
        try eventPoster.postKeyPress(keyCode: shortcut.keyCode, modifiers: shortcut.modifiers)
    }
}
