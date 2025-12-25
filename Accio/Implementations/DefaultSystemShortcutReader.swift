//
//  DefaultSystemShortcutReader.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import CoreGraphics
import Foundation

/// Default implementation that reads from symbolichotkeys.plist
final class DefaultSystemShortcutReader: SystemShortcutReader {
    /// Symbolic hotkey ID for "Move focus to next window"
    private static let windowCyclingHotkeyID = "27"

    func readWindowCyclingShortcut() -> KeyboardShortcut {
        // Try to read from user defaults
        guard let symbolicHotKeys = UserDefaults.standard.persistentDomain(
            forName: "com.apple.symbolichotkeys"
        )?["AppleSymbolicHotKeys"] as? [String: Any] else {
            return .commandBacktick
        }

        guard let hotkey = symbolicHotKeys[Self.windowCyclingHotkeyID] as? [String: Any] else {
            return .commandBacktick
        }

        // Check if the hotkey is enabled
        guard let enabled = hotkey["enabled"] as? Bool, enabled else {
            return .commandBacktick
        }

        // Parse the shortcut parameters
        guard let value = hotkey["value"] as? [String: Any],
              let parameters = value["parameters"] as? [Int],
              parameters.count >= 3
        else {
            return .commandBacktick
        }

        // Parameters: [asciiCode, virtualKeyCode, modifierFlags]
        let virtualKeyCode = parameters[1]
        let modifierFlags = parameters[2]

        return KeyboardShortcut(
            keyCode: CGKeyCode(virtualKeyCode),
            modifiers: convertModifierFlags(modifierFlags)
        )
    }

    /// Convert symbolic hotkey modifier flags to CGEventFlags
    private func convertModifierFlags(_ flags: Int) -> CGEventFlags {
        var result: CGEventFlags = []

        // Modifier flag bit positions in symbolichotkeys.plist
        // Command: 1 << 20 (1048576)
        // Shift: 1 << 17 (131072)
        // Control: 1 << 18 (262144)
        // Option: 1 << 19 (524288)

        if flags & (1 << 20) != 0 {
            result.insert(.maskCommand)
        }
        if flags & (1 << 17) != 0 {
            result.insert(.maskShift)
        }
        if flags & (1 << 18) != 0 {
            result.insert(.maskControl)
        }
        if flags & (1 << 19) != 0 {
            result.insert(.maskAlternate)
        }

        return result
    }
}
