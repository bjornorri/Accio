//
//  DefaultsAppGroupStore.swift
//  Accio
//

import Combine
import Defaults

/// App group store implementation backed by Defaults (UserDefaults).
final class DefaultsAppGroupStore: AppGroupStore {
    var groups: [AppGroup] {
        get { Defaults[.appGroups] }
        set { Defaults[.appGroups] = newValue }
    }

    var groupsPublisher: AnyPublisher<[AppGroup], Never> {
        Defaults.publisher(.appGroups)
            .map(\.newValue)
            .eraseToAnyPublisher()
    }
}
