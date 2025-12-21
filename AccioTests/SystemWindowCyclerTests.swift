//
//  SystemWindowCyclerTests.swift
//  AccioTests
//
//  Created by Bjorn Orri Saemundsson on 21.12.2025.
//

import CoreGraphics
import FactoryKit
import FactoryTesting
import Testing
@testable import Accio

@Suite(.container, .serialized)
@MainActor
struct SystemWindowCyclerTests {

    private func resetAndRegisterMocks(
        shortcut: KeyboardShortcut = .commandBacktick,
        shouldThrow: Bool = false
    ) -> (MockSystemShortcutReader, MockKeyboardEventPoster) {
        Container.shared.manager.reset(options: .all)

        let mockReader = MockSystemShortcutReader(shortcut: shortcut)
        let mockPoster = MockKeyboardEventPoster(shouldThrow: shouldThrow)

        Container.shared.systemShortcutReader.register { mockReader }
        Container.shared.keyboardEventPoster.register { mockPoster }
        Container.shared.windowCycler.register { SystemWindowCycler() }

        return (mockReader, mockPoster)
    }

    @Test func cycleWindows_readsShortcutAndPostsKeyPress() throws {
        let (mockReader, mockPoster) = resetAndRegisterMocks()

        let cycler = Container.shared.windowCycler()

        try cycler.cycleWindows(for: "com.apple.Safari")

        #expect(mockReader.readCount == 1)
        #expect(mockPoster.postedKeyPresses.count == 1)
        #expect(mockPoster.postedKeyPresses[0].keyCode == KeyboardShortcut.commandBacktick.keyCode)
        #expect(mockPoster.postedKeyPresses[0].modifiers == KeyboardShortcut.commandBacktick.modifiers)
    }

    @Test func cycleWindows_usesCustomShortcut() throws {
        let customShortcut = KeyboardShortcut(
            keyCode: 0x31,  // Space
            modifiers: [.maskCommand, .maskShift]
        )
        let (_, mockPoster) = resetAndRegisterMocks(shortcut: customShortcut)

        let cycler = Container.shared.windowCycler()

        try cycler.cycleWindows(for: "com.apple.Finder")

        #expect(mockPoster.postedKeyPresses.count == 1)
        #expect(mockPoster.postedKeyPresses[0].keyCode == customShortcut.keyCode)
        #expect(mockPoster.postedKeyPresses[0].modifiers == customShortcut.modifiers)
    }

    @Test func cycleWindows_propagatesErrors() throws {
        let (_, _) = resetAndRegisterMocks(shouldThrow: true)

        let cycler = Container.shared.windowCycler()

        #expect(throws: MockKeyboardEventPoster.MockError.self) {
            try cycler.cycleWindows(for: "com.apple.Safari")
        }
    }
}

// MARK: - Mock SystemShortcutReader

class MockSystemShortcutReader: SystemShortcutReader {
    var shortcut: KeyboardShortcut
    var readCount = 0

    init(shortcut: KeyboardShortcut) {
        self.shortcut = shortcut
    }

    func readWindowCyclingShortcut() -> KeyboardShortcut {
        readCount += 1
        return shortcut
    }
}

// MARK: - Mock KeyboardEventPoster

class MockKeyboardEventPoster: KeyboardEventPoster {
    enum MockError: Error {
        case testError
    }

    var shouldThrow: Bool
    var postedKeyPresses: [(keyCode: CGKeyCode, modifiers: CGEventFlags)] = []

    init(shouldThrow: Bool = false) {
        self.shouldThrow = shouldThrow
    }

    func postKeyPress(keyCode: CGKeyCode, modifiers: CGEventFlags) throws {
        if shouldThrow {
            throw MockError.testError
        }
        postedKeyPresses.append((keyCode, modifiers))
    }
}
