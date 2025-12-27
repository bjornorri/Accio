//
//  WindowFocusObserver.swift
//  Accio
//

import AppKit

/// Saves and restores focus when the window loses/regains key status.
///
/// This works around an issue where KeyboardShortcuts.RecorderCocoa clears
/// the window's first responder when the window resigns key status.
final class WindowFocusObserver {
    private var updateObserver: NSObjectProtocol?
    private var resignObserver: NSObjectProtocol?
    private var becomeKeyObserver: NSObjectProtocol?
    private weak var lastFirstResponder: NSResponder?
    private weak var savedFirstResponder: NSResponder?

    func start() {
        // Track the current first responder continuously
        updateObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didUpdateNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow,
                  window.isKeyWindow,
                  let firstResponder = window.firstResponder,
                  firstResponder !== window else {
                return
            }
            self?.lastFirstResponder = firstResponder
        }

        // Save the last first responder when window resigns key
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.savedFirstResponder = self?.lastFirstResponder
        }

        // Restore the saved first responder when window becomes key
        becomeKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let window = notification.object as? NSWindow,
                  let responder = self.savedFirstResponder else {
                return
            }
            // Delay slightly to run after RecorderCocoa's preventBecomingKey()
            DispatchQueue.main.async {
                window.makeFirstResponder(responder)
            }
        }
    }

    func stop() {
        if let updateObserver {
            NotificationCenter.default.removeObserver(updateObserver)
            self.updateObserver = nil
        }
        if let resignObserver {
            NotificationCenter.default.removeObserver(resignObserver)
            self.resignObserver = nil
        }
        if let becomeKeyObserver {
            NotificationCenter.default.removeObserver(becomeKeyObserver)
            self.becomeKeyObserver = nil
        }
    }
}
