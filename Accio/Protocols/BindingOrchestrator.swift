//
//  BindingOrchestrator.swift
//  Accio
//

import Foundation

/// Manages the lifecycle of hotkey bindings
///
/// Responsibilities:
/// - Observes hotkey bindings from storage
/// - Registers/unregisters hotkeys as bindings change
/// - Executes actions when hotkeys are triggered
protocol BindingOrchestrator: AnyObject {
    /// Start observing binding changes and register existing bindings
    func start()

    /// Stop observing and unregister all bindings
    func stop()
}
