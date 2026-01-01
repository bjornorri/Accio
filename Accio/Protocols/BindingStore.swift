//
//  BindingStore.swift
//  Accio
//

import Combine

/// Protocol for storing and observing hotkey bindings.
protocol BindingStore {
    /// Current bindings
    var bindings: [HotkeyBinding] { get set }

    /// Publisher for binding changes
    var bindingsPublisher: AnyPublisher<[HotkeyBinding], Never> { get }
}
