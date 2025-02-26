# PromptShelf

PromptShelf is a macOS application for managing, organizing, and improving your AI prompts across multiple LLM providers.

## Features

### Comprehensive Model Support
- **Multiple Providers**: OpenAI, Anthropic, Google, DeepSeek, and Grok models supported
- **Reasoning Capability**: Enhanced support for models with reasoning capabilities

### Prompt Management
- **Organize prompts** by type and folders
- **Version history** for all your prompts
- **Quick access** to frequently used prompts

### AI-Powered Improvements
- **Improve prompts** with any supported LLM model
- **Reasoning Mode**: Get detailed explanations of how and why the AI improved your prompt
- **Specialized workflows** for different prompt types:
  - General prompts
  - Cursor Fix prompts
  - Planner Mode prompts

### Advanced Settings
- **API Key Management**: Securely store and manage API keys for each provider
- **Usage Statistics**: Track API calls, token usage, and estimated costs
- **Customization**: Appearance options and advanced settings

## Reasoning Capabilities

### What is Reasoning Mode?

Reasoning Mode is a special capability available with select models that provides not just the improved prompt, but also a detailed explanation of the AI's thought process during improvement. This helps you:

1. **Understand why** specific changes were made
2. **Learn from the AI's reasoning** to write better prompts in the future
3. **Build trust** by making the improvement process transparent

### Models with Reasoning Support

Look for the "Reasoning Capable" indicator in the model selection menu. Models that support reasoning include:
- GPT-4o, GPT-4, and GPT-4 Turbo (OpenAI)
- Claude 3 Opus and Claude 3 Sonnet (Anthropic)
- Gemini 1.5 Pro (Google)
- And more

### How to Use Reasoning Mode

1. Select a prompt you want to improve
2. Choose a model with reasoning capability
3. Toggle the "Use reasoning" switch
4. Click "Improve with [Model]"
5. The improved prompt will include the AI's reasoning about the changes

## Getting Started

1. Download and install PromptShelf
2. Add your API keys in the Settings menu
3. Create or import prompts
4. Use the AI improvement features to enhance your prompts

## Requirements

- macOS 12.0 or later
- Internet connection for API access
- API keys for the model providers you want to use

## Development

### Cursor Rules

This project uses Cursor rules to maintain consistent code style and organization. The `.cursorrules` file provides the following features:

1. **Import Organization**: Automatically organizes imports into logical groups (Standard Library, Project Modules, Models, Services, Settings).
2. **Code Formatting**: Enforces consistent formatting with 4-space indentation and 100-character line width.
3. **Type Resolution**: Helps resolve common type references with proper module paths (e.g., `SettingsViewModel`, `PromptStore`, etc.).
4. **Documentation**: Encourages proper documentation of parameters and return values.
5. **Linting**: Enforces best practices like avoiding force unwrapping, force casting, ensuring proper `@Published` usage, and maintaining thread safety with `async/await` and `Task`.
6. **File Organization**: Organizes Swift files into logical sections (Imports, Type Declarations, Properties, Initializers, Methods, etc.).
7. **Refactoring Suggestions**: Provides suggestions for moving types to appropriate files and consolidating imports.

### Using Cursor Rules

When working with this project in Cursor:

1. The rules will automatically apply when editing Swift files.
2. Use the "Format Document," "Organize Imports," "Lint," "Suggest Refactorings," "Suggest Documentation," and "Suggest Type Imports" commands to maintain consistency.
3. Pay attention to import and type resolution suggestions to resolve build errors.
4. Follow the file organization patterns and template suggestions for new files.

### Project Structure

- **PromptShelf/**: Main application code
  - **Models/**: Data structures and type definitions (e.g., `Models.swift`)
  - **Services/**: Service layer for API interactions (e.g., `PromptStore.swift`)
  - **Settings/**: Settings-related view models and types (e.g., `SettingsViewModel.swift`)
  - **Templates/**: Templates for new Swift files, view models, and views
- **PromptShelfTests/**: Unit tests
- **PromptShelfUITests/**: UI tests

### Contributing

We welcome contributions to PromptShelf! Here's how to get started:

1. Fork the repository and clone it locally.
2. Install dependencies via Swift Package Manager (if any).
3. Use the Cursor rules in `.cursorrules` to maintain code style.
4. Create a new branch for your feature or bug fix.
5. Submit a pull request with detailed changes, tests, and documentation updates.

Please follow the Cursor rules and Swift best practices outlined in this README.

### Testing

- **Unit Tests**: Use the `PromptShelfTests` target to write unit tests for models, services, and view models. Follow the `TestTemplate.swift` in `Templates/` for consistency, ensuring tests cover:
  - Prompt creation, deletion, and improvement (`improvePromptWithLLM`).
  - API key management (`saveAPIKey`, `getAPIKey`, `deleteAPIKey`).
  - Usage statistics tracking.
  - Use `async/await` for testing asynchronous operations and include error handling cases.

  **Example Unit Test**:
  ```swift
  func testPromptImprovement() async {
      // Arrange
      let prompt = Prompt(title: "Test", text: "Improve this", folder: "Code")
      store.savePrompt(prompt)
      
      // Act
      do {
          let improvedPrompt = try await store.improvePromptWithLLM(prompt: prompt, model: .openAI)
          // Assert
          XCTAssertNotEqual(improvedPrompt.text, prompt.text, "Prompt should be improved")
          XCTAssertTrue(improvedPrompt.versions.last?.improvedByLLM ?? false, "Version should be LLM-improved")
      } catch {
          XCTFail("Improvement failed: \(error)")
      }
  }
  ```

- **UI Tests**: Use `PromptShelfUITests` for testing UI interactions, ensuring:
  - Dark theme compatibility across `SettingsView`, `PromptVersionsView`, and `PromptImproveView`.
  - Prompt management workflows (e.g., creating, improving, and viewing versions).
  - Settings navigation and API key management functionality.
  - Use Xcode's UI testing framework (`XCUIApplication`) to simulate user actions.

  **Example UI Test**:
  ```swift
  func testSettingsNavigation() {
      let app = XCUIApplication()
      app.launch()
      
      // Navigate to Settings
      app.navigationBars["Prompts"].buttons["Settings"].tap()
      XCTAssertTrue(app.navigationBars["Settings"].exists, "Settings view should appear")
      
      // Test API key input
      let apiKeyField = app.textFields["Enter API key"]
      apiKeyField.tap()
      apiKeyField.typeText("test-api-key")
      app.buttons["Save"].tap()
      XCTAssertTrue(app.staticTexts["API key saved successfully"].exists, "Save should succeed")
  }
  ```

- **Run Tests**: Open Xcode, select the appropriate test scheme (e.g., "PromptShelfTests" or "PromptShelfUITests"), and use Cmd + U to run tests. Ensure tests pass in a dark theme environment.

### Deployment

- **Build for Distribution**: Use Xcode's Archive feature (Product > Archive) to create a `.xcarchive` for macOS distribution. Ensure:
  - All dependencies (e.g., Swift Package Manager packages) are included.
  - The app is signed with a valid Developer ID certificate for macOS.
  - The build configuration matches your target (e.g., Debug or Release).

- **App Store Submission**: Prepare your app for the Mac App Store by:
  - Configuring entitlements (e.g., Keychain access for API keys, App Sandbox if needed).
  - Adding high-quality icons (512x512px, 1024x1024px) and screenshots for macOS.
  - Providing metadata (app description, keywords, category) in App Store Connect.
  - Using the App Store Connect API or Transporter app for automated submission, ensuring compliance with macOS guidelines.

- **Local Distribution**: Export an `.app` file for local testing or distribution via notarization:
  - Use `xcodebuild -exportArchive` to export the archive, specifying the export options (e.g., `exportOptionsPlist` for notarization).
  - Follow Apple's notarization process using `xcrun altool` or Xcode's Organizer to upload and notarize the app, ensuring macOS Gatekeeper compatibility.
  - Distribute the notarized `.app` or `.dmg` file locally or via a website.

### Versioning

- Use semantic versioning (SemVer) for releases (e.g., `v1.0.0` for major.minor.patch).
- Update the `README.md` and `PromptShelf/Info.plist` with version numbers during releases.
- Maintain a `CHANGELOG.md` file to document changes between versions.

**Example CHANGELOG.md**:
```markdown
# Changelog

## [1.0.0] - 2025-02-26
- Initial release of PromptShelf with core prompt management and LLM integration.
- Added support for OpenAI, Anthropic, Google, DeepSeek, and Grok models.
- Implemented Reasoning Mode for advanced prompt improvements.
``` 