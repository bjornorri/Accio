# Accio Coding Conventions

## Dependency Injection

All services use the Factory pattern with FactoryKit:

1. **Protocol** in `Accio/Protocols/{Name}.swift`
2. **Implementation** in `Accio/Implementations/{Prefix}{Name}.swift`
3. **Register** in `Accio/Core/DependencyContainer.swift`

### Implementation Naming

Use a descriptive prefix that indicates the underlying technology or framework:
- `CGEvent{Name}` - wraps Core Graphics events
- `NSWorkspace{Name}` - wraps NSWorkspace
- `System{Name}` - wraps system APIs or multiple frameworks
- `Default{Name}` - pure Swift implementation with no specific framework dependency

### Factory Scopes

Choose the appropriate scope when registering:
- `self { }` - new instance each time (stateless services)
- `.singleton` - single shared instance (stateful services, caches)
- `.cached` - lazy singleton, created on first use

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
    Components/     # Reusable UI components
  Core/             # DependencyContainer, DefaultsKeys, utilities
AccioTests/         # All tests
  Mocks/            # Shared mocks used by multiple test suites
```

## Testing

- Use **Swift Testing** framework (`import Testing`), not XCTest
- Test file naming: `{ImplementationName}Tests.swift`
- Use `@Suite(.container, .serialized)` for tests that use Factory mocks
- Reset container before each test: `Container.shared.manager.reset(options: .all)`

### Mock Placement

- **Single test suite**: Define mock in the test file
- **Multiple test suites**: Place in `AccioTests/Mocks/Mock{ProtocolName}.swift`

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

## Error Handling

- Prefer `throws` for synchronous code, `async throws` for async code
- Don't silently swallow errors - at minimum log them
- Let errors propagate unless you can meaningfully handle them
- Use `do/catch` at boundaries (UI, entry points) to present errors to users

## Code Style

### Classes and Access Control

- Prefer `final class` for implementations unless inheritance is needed
- Default to `private` for properties and helper methods
- Use `internal` (implicit) for protocol conformance methods
- Only use `public` for module API boundaries

### Dependency Injection

- Use `@Injected` for dependency injection in classes
- Inject dependencies in `init` for test-only overrides when `@Injected` isn't suitable

### Thread Safety

- Use `@MainActor` only for:
  - SwiftUI view models / `@Observable` classes that drive UI
  - Methods that directly update UI state
- Don't use `@MainActor` on protocol definitions - apply it to implementations if needed
- For async coordination without UI, prefer actors over `@MainActor`
