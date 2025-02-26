# PromptShelf Developer Guidelines

## Build & Test Commands
- Build: `xcodebuild -project PromptShelf.xcodeproj -scheme PromptShelf build`
- Run: `xcodebuild -project PromptShelf.xcodeproj -scheme PromptShelf run`
- Test: `xcodebuild -project PromptShelf.xcodeproj -scheme PromptShelf test`
- Run single test: `xcodebuild -project PromptShelf.xcodeproj -scheme PromptShelf test -only-testing:PromptShelfTests/PromptShelfTests/[testName]`

## Code Style Guidelines
- **File Structure**: Core types in `Models/Types.swift`, views in root directory, services in `Services/`
- **Type Definitions**: Use `enum`, `struct`, and `protocol` with clear documentation comments
- **Naming**: Use camelCase for variables/methods, PascalCase for types
- **Imports**: Group and organize imports with Foundation/SwiftUI first, then alphabetically
- **Error Handling**: Use async/await pattern with proper error propagation
- **UI Patterns**: Follow SwiftUI best practices with @State, @Published, @EnvironmentObject
- **Models**: Make properties public when needed, use proper access control
- **Documentation**: Add doc comments (///) for public interfaces
- **Enums**: Use exhaustive switch statements (no default cases)
- **Constants**: Group related constants in enum-based namespaces

When adding LLM functionality, ensure support for multiple providers including reasoning capabilities.