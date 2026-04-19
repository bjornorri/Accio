//
//  AppGroupStore.swift
//  Accio
//

import Combine

/// Protocol for storing and observing app groups.
protocol AppGroupStore {
    /// Current groups
    var groups: [AppGroup] { get set }

    /// Publisher for group changes
    var groupsPublisher: AnyPublisher<[AppGroup], Never> { get }
}
