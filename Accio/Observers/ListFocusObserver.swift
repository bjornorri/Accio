//
//  ListFocusObserver.swift
//  Accio
//

import AppKit

/// Observes when an NSTableView gains focus and notifies via callback.
final class ListFocusObserver {
    private var observer: NSObjectProtocol?
    private var isListFocused = false
    private let onListFocused: () -> Void

    init(onListFocused: @escaping () -> Void) {
        self.onListFocused = onListFocused
    }

    func start() {
        observer = NotificationCenter.default.addObserver(
            forName: NSWindow.didUpdateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkListFocus()
        }
    }

    func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }

    private func checkListFocus() {
        guard let window = NSApp.keyWindow,
              let firstResponder = window.firstResponder else {
            isListFocused = false
            return
        }

        // Check if the first responder is the table view or its clip view
        let isNowFocused = firstResponder is NSTableView ||
            (firstResponder as? NSView)?.superview is NSTableView

        if isNowFocused && !isListFocused {
            onListFocused()
        }
        isListFocused = isNowFocused
    }
}
