//
//  ShortcutRecorder.swift
//  Accio
//

import AppKit
import KeyboardShortcuts
import SwiftUI

/// A keyboard shortcut recorder that always selects all text when focused
struct ShortcutRecorder: NSViewRepresentable {
    let name: KeyboardShortcuts.Name

    func makeNSView(context: Context) -> KeyboardShortcuts.RecorderCocoa {
        let recorder = KeyboardShortcuts.RecorderCocoa(for: name)
        context.coordinator.recorder = recorder
        return recorder
    }

    func updateNSView(_ nsView: KeyboardShortcuts.RecorderCocoa, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        weak var recorder: KeyboardShortcuts.RecorderCocoa?
        private var observer: NSObjectProtocol?
        private var didSelectAll = false

        init() {
            observer = NotificationCenter.default.addObserver(
                forName: NSWindow.didUpdateNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.checkFirstResponder()
            }
        }

        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        private func checkFirstResponder() {
            guard let recorder,
                  let window = recorder.window else {
                return
            }

            let isFirstResponder = window.firstResponder === recorder.currentEditor()

            if isFirstResponder && !didSelectAll {
                recorder.currentEditor()?.selectAll(nil)
                didSelectAll = true
            } else if !isFirstResponder {
                didSelectAll = false
            }
        }
    }
}
