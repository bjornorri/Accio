# Accio Coding Conventions

## Dependency Injection

All services use the Factory pattern with FactoryKit:

1. **Protocol** in `Accio/Protocols/{Name}.swift`
2. **Implementation** in `Accio/Implementations/Default{Name}.swift` (or descriptive prefix like `NSWorkspace{Name}.swift`)
3. **Register** in `Accio/Core/DependencyContainer.swift`

Example:
```swift
// Accio/Protocols/WindowCycler.swift
protocol WindowCycler {
    func cycleWindows(for bundleIdentifier: String) throws
}

// Accio/Implementations/SystemWindowCycler.swift
final class SystemWindowCycler: WindowCycler { ... }

// Accio/Core/DependencyContainer.swift
var windowCycler: Factory<WindowCycler> {
    self { SystemWindowCycler() }
}
```

## File Organization

```
Accio/
  Protocols/        # Protocol definitions
  Implementations/  # Protocol implementations
  Models/           # Data models (Codable structs, enums)
  Views/            # SwiftUI views
  Core/             # DependencyContainer, DefaultsKeys, utilities
AccioTests/         # All tests
```

## Testing

- Use **Swift Testing** framework (`import Testing`), not XCTest
- Test file naming: `Default{Name}Tests.swift` or `{Name}Tests.swift`
- Use `@Suite(.container, .serialized)` for tests that use Factory mocks
- Define mock classes in the test file, not in production code
- Reset container before each test: `Container.shared.manager.reset(options: .all)`

Example:
```swift
@Suite(.container, .serialized)
struct DefaultActionCoordinatorTests {
    @Test func whenNotRunning_launchApp_launchesTheApp() async {
        // Arrange
        Container.shared.manager.reset(options: .all)
        let mock = MockApplicationManager()
        Container.shared.applicationManager.register { mock }

        // Act
        let coordinator = DefaultActionCoordinator()
        await coordinator.executeAction(for: "com.example.App", settings: .default)

        // Assert
        #expect(mock.launchCalls == ["com.example.App"])
    }
}
```

## Code Style

- Prefer `final class` for implementations unless inheritance is needed
- Use `@Injected` for dependency injection in classes
- Avoid `@MainActor` unless truly required for thread safety
- Keep error handling - don't silently swallow errors that aid debugging
