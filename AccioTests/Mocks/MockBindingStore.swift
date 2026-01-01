//
//  MockBindingStore.swift
//  AccioTests
//

import Combine
import Foundation
@testable import Accio

final class MockBindingStore: BindingStore {
    private let bindingsSubject: CurrentValueSubject<[HotkeyBinding], Never>

    var bindings: [HotkeyBinding] {
        get { bindingsSubject.value }
        set { bindingsSubject.send(newValue) }
    }

    var bindingsPublisher: AnyPublisher<[HotkeyBinding], Never> {
        bindingsSubject.eraseToAnyPublisher()
    }

    init(bindings: [HotkeyBinding] = []) {
        self.bindingsSubject = CurrentValueSubject(bindings)
    }
}
