//
//  GroupOrderTracker.swift
//  Accio
//

/// Tracks app activations and updates group member ordering accordingly.
protocol GroupOrderTracker: AnyObject {
    /// Start observing app activations
    func start()

    /// Stop observing app activations
    func stop()
}
