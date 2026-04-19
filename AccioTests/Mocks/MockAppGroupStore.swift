//
//  MockAppGroupStore.swift
//  AccioTests
//

import Combine
import Foundation
@testable import Accio

final class MockAppGroupStore: AppGroupStore {
    private let groupsSubject: CurrentValueSubject<[AppGroup], Never>

    var groups: [AppGroup] {
        get { groupsSubject.value }
        set { groupsSubject.send(newValue) }
    }

    var groupsPublisher: AnyPublisher<[AppGroup], Never> {
        groupsSubject.eraseToAnyPublisher()
    }

    init(groups: [AppGroup] = []) {
        self.groupsSubject = CurrentValueSubject(groups)
    }
}
