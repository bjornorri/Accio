//
//  DefaultsBindingStore.swift
//  Accio
//

import Combine
import Defaults

/// Binding store implementation backed by Defaults (UserDefaults).
final class DefaultsBindingStore: BindingStore {
    var bindings: [HotkeyBinding] {
        get { Defaults[.hotkeyBindings] }
        set { Defaults[.hotkeyBindings] = newValue }
    }

    var bindingsPublisher: AnyPublisher<[HotkeyBinding], Never> {
        Defaults.publisher(.hotkeyBindings)
            .map(\.newValue)
            .eraseToAnyPublisher()
    }
}
