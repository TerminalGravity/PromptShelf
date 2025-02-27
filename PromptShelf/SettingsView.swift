import SwiftUI
import Foundation
import AppKit
import Combine

// Type aliases to avoid import errors

// Local enum for toast types
// enum ToastType: String, Identifiable {
//     case success = "Success"
//     case error = "Error"
//     case info = "Info"
//     case warning = "Warning"
//     
//     var id: String { rawValue }
//     
//     var iconName: String {
//         switch self {
//         case .success: return "checkmark.circle"
//         case .error: return "xmark.circle"
//         case .info: return "info.circle"
//         case .warning: return "exclamationmark.triangle"
//         }
//     }
//     
//     var color: Color {
//         switch self {
//         case .success: return .green
//         case .error: return .red
//         case .info: return .blue
//         case .warning: return .orange
//         }
//     }
// }

// Local enum for LLM models
enum LocalLLMModel: String, CaseIterable, Identifiable {
    case gpt4 = "GPT-4"
    case gpt35Turbo = "GPT-3.5 Turbo"
    case claude3Opus = "Claude 3 Opus"
    case claude3Sonnet = "Claude 3 Sonnet"
    case claude3Haiku = "Claude 3 Haiku"
    case gemini = "Gemini"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var hasReasoningCapability: Bool {
        return true
    }
}

// Local enum for model providers
enum LocalModelProvider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case google = "Google"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var models: [LocalLLMModel] {
        return []
    }
}

// Local enum for app theme
enum LocalAppTheme: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
}

// Local enum for settings sections
enum LocalSettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case models = "Models"
    case apiKeys = "API Keys"
    case appearance = "Appearance"
    case advanced = "Advanced"
    case about = "About"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var iconName: String {
        switch self {
        case .general: return "gear"
        case .models: return "cpu"
        case .apiKeys: return "key"
        case .appearance: return "paintbrush"
        case .advanced: return "slider.horizontal.3"
        case .about: return "info.circle"
        }
    }
}

// Local ToastView implementation
struct SettingsToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool
    
    var body: some View {
        if isShowing {
            VStack {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: type.iconName)
                        .foregroundColor(type.color)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isShowing = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.windowBackgroundColor))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
}

// Local PromptStore implementation
class LocalPromptStore: ObservableObject {
    // Empty implementation for compilation
}

// Local SettingsViewModel implementation
class SettingsViewModel: ObservableObject {
    @Published var selectedSection: LocalSettingsSection = .general
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var toastType: ToastType = .info
    @Published var selectedTheme: LocalAppTheme = .system
    
    init(promptStore: LocalPromptStore) {
        // Initialize with promptStore
    }
    
    func validateAPIKey() {
        // Validate API key
    }
    
    func saveAPIKey() {
        // Save API key
    }
    
    func deleteAPIKey() {
        // Delete API key
    }
    
    func resetAPIUsageStats() {
        // Reset API usage stats
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Local state for UI
    @State private var selectedProvider: LocalModelProvider? = LocalModelProvider.allCases.first
    @State private var selectedModel: LocalLLMModel = LocalLLMModel.allCases.first!
    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var isValidating: Bool = false
    @State private var showGuide: Bool = true
    @State private var showReasoningModelsOnly: Bool = false
    @State private var enableCaching: Bool = true
    @State private var enableLogging: Bool = false
    @State private var rateLimitValue: Double = 10
    @State private var showResetConfirmation: Bool = false
    
    init(store: LocalPromptStore) {
        self.viewModel = SettingsViewModel(promptStore: store)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                // Sidebar sections
                ForEach(LocalSettingsSection.allCases) { section in
                    SidebarRow(section: section, isSelected: section == viewModel.selectedSection) {
                        viewModel.selectedSection = section
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
            
            // Content view based on selected section
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Label("Close", systemImage: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .labelStyle(.iconOnly)
            }
        }
        .frame(width: 800, height: 500)
        .overlay(
            SettingsToastView(message: viewModel.toastMessage, type: viewModel.toastType, isShowing: $viewModel.showToast)
        )
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    var contentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text(viewModel.selectedSection.displayName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Divider()
            
            // Content based on selected section
            ScrollView {
                switch viewModel.selectedSection {
                case .apiKeys:
                    apiKeysSection
                case .models:
                    apiUsageSection
                case .appearance:
                    appearanceSection
                case .advanced:
                    advancedSection
                case .about:
                    aboutSection
                case .general:
                    Text("General settings not implemented yet")
                }
            }
        }
        .padding()
    }
    
    // MARK: - Section Views
    
    var apiKeysSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Configure your API keys for language models")
                .font(.headline)
            
            // Provider selection
            VStack(alignment: .leading) {
                Text("Select Provider")
                    .font(.headline)
                
                Picker("Provider", selection: $selectedProvider) {
                    ForEach(LocalModelProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider as LocalModelProvider?)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom)
            }
            
            // Model selection
            if let provider = selectedProvider {
                VStack(alignment: .leading) {
                    Text("Select Model")
                        .font(.headline)
                    
                    Picker("Model", selection: $selectedModel) {
                        let models = showReasoningModelsOnly ? 
                            provider.models.filter { $0.hasReasoningCapability } :
                            provider.models
                        
                        ForEach(models) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.bottom)
                    
                    Toggle("Show only models with reasoning capabilities", isOn: $showReasoningModelsOnly)
                        .padding(.bottom)
                }
            }
            
            // API Key section
            VStack(alignment: .leading) {
                HStack {
                    Text("API Key")
                        .font(.headline)
                    
                    Button(action: {
                        showAPIKey.toggle()
                    }) {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }
                
                VStack {
                    HStack {
                        if showAPIKey {
                            TextField("Enter API key", text: $apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            SecureField("Enter API key", text: $apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Button("Validate") {
                            viewModel.validateAPIKey()
                        }
                        .disabled(apiKey.isEmpty || isValidating)
                        
                        if isValidating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.leading, 5)
                        }
                    }
                    
                    HStack {
                        Button("Save") {
                            viewModel.saveAPIKey()
                        }
                        .disabled(apiKey.isEmpty)
                        
                        Button("Delete") {
                            viewModel.deleteAPIKey()
                        }
                    }
                    .padding(.top, 5)
                }
                .padding(.bottom)
            }
            
            if showGuide {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("API Key Guide")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showGuide = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    Text("To use AI-powered improvements, you need an API key from your selected provider.")
                    Text("1. Create an account at the provider's website")
                    Text("2. Navigate to API section and generate a new key")
                    Text("3. Copy and paste the key here")
                    Text("4. Save to securely store for future use")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.1)))
            }
        }
    }
    
    var apiUsageSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Monitor your API usage")
                .font(.headline)
            
            // Usage statistics
            VStack(alignment: .leading, spacing: 12) {
                Text("Usage Statistics")
                    .font(.headline)
                
                Group {
                    Text("Total API Calls: 0")
                    Text("Total Tokens Used: 0")
                    Text("Estimated Cost: $0.00")
                    Text("Last Updated: \(Date().formatted())")
                }
                .font(.system(.body, design: .monospaced))
                
                Divider()
                
                Text("Usage by Model")
                    .font(.headline)
                
                Text("No usage data available")
                    .font(.system(.body, design: .monospaced))
                
                Button("Reset Usage Statistics") {
                    showResetConfirmation = true
                }
                .padding(.top)
                .alert(isPresented: $showResetConfirmation) {
                    Alert(
                        title: Text("Reset Usage Statistics"),
                        message: Text("Are you sure you want to reset all API usage statistics? This action cannot be undone."),
                        primaryButton: .destructive(Text("Reset")) {
                            // Reset API usage stats
                            // viewModel.resetAPIUsageStats()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }
    
    var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Customize the application appearance")
                .font(.headline)
            
            VStack(alignment: .leading) {
                Text("Theme")
                    .font(.headline)
                
                Picker("Theme", selection: $viewModel.selectedTheme) {
                    ForEach(LocalAppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom)
            }
            
            // Additional appearance settings could go here
        }
    }
    
    var advancedSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Advanced settings for power users")
                .font(.headline)
            
            VStack(alignment: .leading) {
                Text("Rate Limiting")
                    .font(.headline)
                
                Text("API calls per minute: \(Int(rateLimitValue))")
                
                Slider(value: $rateLimitValue, in: 1...20, step: 1)
                    .padding(.bottom)
            }
            
            VStack(alignment: .leading) {
                Text("Caching")
                    .font(.headline)
                
                Toggle("Enable API response caching", isOn: $enableCaching)
                    .padding(.bottom)
            }
            
            VStack(alignment: .leading) {
                Text("Logging")
                    .font(.headline)
                
                Toggle("Enable debug logging", isOn: $enableLogging)
                    .padding(.bottom)
            }
        }
    }
    
    var aboutSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About PromptShelf")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("PromptShelf v1.0.0")
                    .fontWeight(.bold)
                
                Text("A macOS application for managing, improving, and organizing your prompt library.")
                
                Text("© 2024 PromptShelf Team")
                
                Link("Visit Our Website", destination: URL(string: "https://www.promptshelf.app")!)
                    .padding(.top, 5)
            }
        }
    }
}

// MARK: - Helper Views

struct SidebarRow: View {
    let section: LocalSettingsSection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: section.iconName)
                    .frame(width: 24, height: 24)
                
                Text(section.displayName)
                    .font(.headline)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .accentColor : .primary)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let store = LocalPromptStore()
        return SettingsView(store: store)
    }
}