//
//  ShortcutRecorder.swift
//  Accio
//

import AppKit
import KeyboardShortcuts
import SwiftUI

/// A keyboard shortcut recorder that selects all text when focused
struct ShortcutRecorder: NSViewRepresentable {
    let name: KeyboardShortcuts.Name
    var shouldActivate: Bool = false
    var onActivated: (() -> Void)?
    var onDeactivated: (() -> Void)?

    func makeNSView(context: Context) -> KeyboardShortcuts.RecorderCocoa {
        let recorder = KeyboardShortcuts.RecorderCocoa(for: name)
        context.coordinator.recorder = recorder
        context.coordinator.onActivated = onActivated
        context.coordinator.onDeactivated = onDeactivated
        return recorder
    }

    func updateNSView(_ nsView: KeyboardShortcuts.RecorderCocoa, context: Context) {
        context.coordinator.onActivated = onActivated
        context.coordinator.onDeactivated = onDeactivated

        // Programmatically activate if requested
        if shouldActivate && !context.coordinator.isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        weak var recorder: KeyboardShortcuts.RecorderCocoa?
        var onActivated: (() -> Void)?
        var onDeactivated: (() -> Void)?
        private var observer: NSObjectProtocol?
        private(set) var isRecording = false

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

            if isFirstResponder && !isRecording {
                // Starting to record - select all text for consistent behavior
                recorder.currentEditor()?.selectAll(nil)
                isRecording = true
                onActivated?()
            } else if !isFirstResponder && isRecording {
                isRecording = false
                onDeactivated?()
            }
        }
    }
}
