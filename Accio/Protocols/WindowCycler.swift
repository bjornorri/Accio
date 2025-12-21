//
//  WindowCycler.swift
//  Accio
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import Foundation

/// Triggers window cycling for an application
protocol WindowCycler {
    /// Cycle to the next window of the specified application
    /// - Parameter bundleIdentifier: The bundle identifier of the app to cycle windows for
    /// - Throws: Error if window cycling fails
    func cycleWindows(for bundleIdentifier: String) throws
}
