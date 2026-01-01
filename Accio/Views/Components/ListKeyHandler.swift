//
//  ListKeyHandler.swift
//  Accio
//

import AppKit
import SwiftUI

/// A view modifier that intercepts key events on the underlying NSTableView to prevent system beeps.
struct ListKeyHandler: NSViewRepresentable {
    var onDelete: (() -> Void)?
    var onReturn: (() -> Void)?
    var onSpace: (() -> Void)?
    var onEscape: (() -> Void)?

    func makeNSView(context: Context) -> KeyHandlerView {
        let view = KeyHandlerView()
        view.onDelete = onDelete
        view.onReturn = onReturn
        view.onSpace = onSpace
        view.onEscape = onEscape
        return view
    }

    func updateNSView(_ nsView: KeyHandlerView, context: Context) {
        nsView.onDelete = onDelete
        nsView.onReturn = onReturn
        nsView.onSpace = onSpace
        nsView.onEscape = onEscape
    }

    class KeyHandlerView: NSView {
        var onDelete: (() -> Void)?
        var onReturn: (() -> Void)?
        var onSpace: (() -> Void)?
        var onEscape: (() -> Void)?

        private weak var tableView: NSTableView?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            DispatchQueue.main.async { [weak self] in
                self?.findAndConfigureTableView()
            }
        }

        private func findAndConfigureTableView() {
            guard let tableView = findTableView(in: window?.contentView) else { return }
            self.tableView = tableView

            // Swizzle keyDown if not already done
            KeyDownSwizzler.shared.swizzleIfNeeded()
            KeyDownSwizzler.shared.register(tableView: tableView, handler: self)
        }

        private func findTableView(in view: NSView?) -> NSTableView? {
            guard let view = view else { return nil }
            if let tableView = view as? NSTableView {
                return tableView
            }
            for subview in view.subviews {
                if let found = findTableView(in: subview) {
                    return found
                }
            }
            return nil
        }

        func handleKeyDown(_ event: NSEvent) -> Bool {
            let hasNoModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty
            guard hasNoModifiers else { return false }

            switch event.keyCode {
            case 51, 117: // Delete (backspace) and forward delete
                onDelete?()
                return true
            case 36, 76: // Return and Enter
                onReturn?()
                return true
            case 49: // Space
                onSpace?()
                return true
            case 53: // Escape
                onEscape?()
                return true
            default:
                return false
            }
        }
    }
}

/// Swizzles NSTableView.keyDown to allow interception of key events.
private class KeyDownSwizzler {
    static let shared = KeyDownSwizzler()

    private var isSwizzled = false
    private var handlers: [ObjectIdentifier: WeakHandler] = [:]

    private struct WeakHandler {
        weak var handler: ListKeyHandler.KeyHandlerView?
    }

    func register(tableView: NSTableView, handler: ListKeyHandler.KeyHandlerView) {
        handlers[ObjectIdentifier(tableView)] = WeakHandler(handler: handler)
    }

    func handler(for tableView: NSTableView) -> ListKeyHandler.KeyHandlerView? {
        handlers[ObjectIdentifier(tableView)]?.handler
    }

    func swizzleIfNeeded() {
        guard !isSwizzled else { return }
        isSwizzled = true

        let originalSelector = #selector(NSTableView.keyDown(with:))
        let swizzledSelector = #selector(NSTableView.accio_keyDown(with:))

        guard let originalMethod = class_getInstanceMethod(NSTableView.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(NSTableView.self, swizzledSelector) else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension NSTableView {
    @objc func accio_keyDown(with event: NSEvent) {
        // Check if we have a handler registered for this table view
        if let handler = KeyDownSwizzler.shared.handler(for: self),
           handler.handleKeyDown(event) {
            return
        }

        // Don't forward to original when inside a modal panel (e.g., NSOpenPanel)
        // The panel handles escape at a higher level, and the table view would beep
        if NSApp.modalWindow != nil {
            return
        }

        // Call original implementation (which is now swizzled to accio_keyDown)
        accio_keyDown(with: event)
    }
}

extension View {
    /// Adds key handlers to intercept key presses on the underlying List, preventing system beeps.
    func listKeyHandler(
        onDelete: (() -> Void)? = nil,
        onReturn: (() -> Void)? = nil,
        onSpace: (() -> Void)? = nil,
        onEscape: (() -> Void)? = nil
    ) -> some View {
        background(ListKeyHandler(
            onDelete: onDelete,
            onReturn: onReturn,
            onSpace: onSpace,
            onEscape: onEscape
        ))
    }
}
