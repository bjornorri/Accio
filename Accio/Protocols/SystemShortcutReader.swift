//
//  SystemShortcutReader.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import Foundation

/// Reads system keyboard shortcuts from user preferences
protocol SystemShortcutReader {
    /// Read the user's configured "Move focus to next window" shortcut
    /// - Returns: The configured shortcut, or Cmd+` as fallback
    func readWindowCyclingShortcut() -> KeyboardShortcut
}
