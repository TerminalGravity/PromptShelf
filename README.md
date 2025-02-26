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
5. **Linting**: Enforces best practices like avoiding force unwrapping, force casting, and ensuring proper `@Published` usage in `ObservableObject` classes.
6. **File Organization**: Organizes Swift files into logical sections (Imports, Type Declarations, Properties, Initializers, Methods, etc.).
7. **Refactoring Suggestions**: Provides suggestions for moving types to appropriate files and consolidating imports.

### Using Cursor Rules

When working with this project in Cursor:

1. The rules will automatically apply when editing Swift files.
2. Use the "Format Document" command to apply formatting rules.
3. Pay attention to import suggestions to resolve type errors.
4. Follow the file organization patterns for consistency.

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
5. Submit a pull request with detailed changes and tests.

Please follow the Cursor rules and Swift best practices outlined in this README. 