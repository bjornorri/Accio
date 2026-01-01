//
//  BindingListFocusCoordinator.swift
//  Accio
//

import AppKit

/// Coordinates all focus management for the binding list view.
///
/// This class consolidates focus-related logic including:
/// - Window focus restoration when the app regains focus
/// - List focus observation for auto-selecting items
/// - Search field focus tracking and restoration
@MainActor
final class BindingListFocusCoordinator {
    private var windowFocusObserver: WindowFocusObserver?
    private var listFocusObserver: ListFocusObserver?
    private var windowResignObserver: NSObjectProtocol?
    private var windowBecomeKeyObserver: NSObjectProtocol?

    private var savedSearchFocus = false

    /// Called when the list gains focus
    var onListFocused: (() -> Void)?

    /// Called to check if search field is currently focused
    var isSearchFocused: (() -> Bool)?

    /// Called to set search field focus
    var setSearchFocused: ((Bool) -> Void)?

    func start() {
        setupWindowFocusObserver()
        setupListFocusObserver()
        setupSearchFocusTracking()
    }

    func stop() {
        windowFocusObserver?.stop()
        windowFocusObserver = nil
        listFocusObserver?.stop()
        listFocusObserver = nil

        if let windowResignObserver {
            NotificationCenter.default.removeObserver(windowResignObserver)
            self.windowResignObserver = nil
        }
        if let windowBecomeKeyObserver {
            NotificationCenter.default.removeObserver(windowBecomeKeyObserver)
            self.windowBecomeKeyObserver = nil
        }

        savedSearchFocus = false
    }

    /// Clears any saved focus state. Call when the view appears to prevent stale state.
    func clearSavedState() {
        savedSearchFocus = false
    }

    /// Focuses the list's table view
    func focusList() {
        guard let window = NSApp.keyWindow else { return }
        if let tableView = findTableView(in: window.contentView) {
            window.makeFirstResponder(tableView)
        }
    }

    /// Called when search field loses focus to determine if list should be focused
    func handleSearchFocusLost() {
        // Only focus list if no other element received focus (e.g., Escape pressed)
        // This avoids interfering with Shift+Tab navigation
        DispatchQueue.main.async { [weak self] in
            guard let window = NSApp.keyWindow,
                  let firstResponder = window.firstResponder else {
                return
            }
            // If the window itself is the first responder, nothing specific has focus
            if firstResponder === window || firstResponder === window.contentView {
                self?.focusList()
            }
        }
    }

    /// Checks if the list's table view is currently focused
    func isListFocused() -> Bool {
        NSApp.keyWindow?.isTableViewFocused ?? false
    }

    // MARK: - Private Setup

    private func setupWindowFocusObserver() {
        windowFocusObserver = WindowFocusObserver()
        windowFocusObserver?.start()
    }

    private func setupListFocusObserver() {
        listFocusObserver = ListFocusObserver { [weak self] in
            self?.onListFocused?()
        }
        listFocusObserver?.start()
    }

    private func setupSearchFocusTracking() {
        // Save search focus state before window loses key status
        windowResignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.savedSearchFocus = self?.isSearchFocused?() ?? false
        }

        // Restore search focus if it was focused before
        windowBecomeKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.savedSearchFocus else { return }
            DispatchQueue.main.async {
                self.setSearchFocused?(true)
            }
        }
    }

    // MARK: - Private Helpers

    private func findTableView(in view: NSView?) -> NSTableView? {
        guard let view else { return nil }
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
}
