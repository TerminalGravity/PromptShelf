import SwiftUI
import Foundation
import AppKit
import Combine

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(store: PromptStore) {
        self.viewModel = SettingsViewModel(promptStore: store)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                // Sidebar sections
                ForEach(SettingsSection.allCases) { section in
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
            ToastView(message: viewModel.toastMessage, type: viewModel.toastType, isShowing: $viewModel.showToast)
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
                case .apiUsage:
                    apiUsageSection
                case .appearance:
                    appearanceSection
                case .advanced:
                    advancedSection
                case .about:
                    aboutSection
                default:
                    Text("Section not implemented yet")
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
                
                Picker("Provider", selection: $viewModel.selectedProvider) {
                    ForEach(ModelProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider as ModelProvider?)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom)
            }
            
            // Model selection
            if let provider = viewModel.selectedProvider {
                VStack(alignment: .leading) {
                    Text("Select Model")
                        .font(.headline)
                    
                    Picker("Model", selection: $viewModel.selectedModel) {
                        let models = viewModel.showReasoningModelsOnly ? 
                            provider.models.filter { $0.hasReasoningCapability } :
                            provider.models
                        
                        ForEach(models) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.bottom)
                    
                    Toggle("Show only models with reasoning capabilities", isOn: $viewModel.showReasoningModelsOnly)
                        .padding(.bottom)
                }
            }
            
            // API Key section
            VStack(alignment: .leading) {
                HStack {
                    Text("API Key")
                        .font(.headline)
                    
                    Button(action: {
                        viewModel.showAPIKey.toggle()
                    }) {
                        Image(systemName: viewModel.showAPIKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }
                
                VStack {
                    HStack {
                        if viewModel.showAPIKey {
                            TextField("Enter API key", text: $viewModel.apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            SecureField("Enter API key", text: $viewModel.apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Button("Validate") {
                            viewModel.validateAPIKey()
                        }
                        .disabled(viewModel.apiKey.isEmpty || viewModel.isValidating)
                        
                        if viewModel.isValidating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.leading, 5)
                        }
                    }
                    
                    HStack {
                        Button("Save") {
                            viewModel.saveAPIKey()
                        }
                        .disabled(viewModel.apiKey.isEmpty)
                        
                        Button("Delete") {
                            viewModel.deleteAPIKey()
                        }
                    }
                    .padding(.top, 5)
                }
                .padding(.bottom)
            }
            
            if viewModel.showGuide {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("API Key Guide")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.showGuide = false
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
                    Text("Total API Calls: \(viewModel.store.apiUsageStats.totalCalls)")
                    Text("Total Tokens Used: \(viewModel.store.apiUsageStats.totalTokensUsed)")
                    Text("Estimated Cost: $\(String(format: "%.2f", viewModel.store.apiUsageStats.estimatedCost()))")
                    Text("Last Updated: \(viewModel.store.apiUsageStats.lastUpdated.formatted())")
                }
                .font(.system(.body, design: .monospaced))
                
                Divider()
                
                Text("Usage by Model")
                    .font(.headline)
                
                ForEach(Array(viewModel.store.apiUsageStats.callsByModel.keys.sorted()), id: \.self) { model in
                    if let calls = viewModel.store.apiUsageStats.callsByModel[model],
                       let tokens = viewModel.store.apiUsageStats.tokensByModel[model] {
                        Text("\(model): \(calls) calls, \(tokens) tokens")
                            .font(.system(.body, design: .monospaced))
                    }
                }
                
                Button("Reset Usage Statistics") {
                    viewModel.showResetConfirmation = true
                }
                .padding(.top)
                .alert(isPresented: $viewModel.showResetConfirmation) {
                    Alert(
                        title: Text("Reset Usage Statistics"),
                        message: Text("Are you sure you want to reset all API usage statistics? This action cannot be undone."),
                        primaryButton: .destructive(Text("Reset")) {
                            viewModel.resetAPIUsageStats()
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
                    ForEach(AppTheme.allCases) { theme in
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
                
                Text("API calls per minute: \(Int(viewModel.rateLimitValue))")
                
                Slider(value: $viewModel.rateLimitValue, in: 1...20, step: 1)
                    .padding(.bottom)
            }
            
            VStack(alignment: .leading) {
                Text("Caching")
                    .font(.headline)
                
                Toggle("Enable API response caching", isOn: $viewModel.enableCaching)
                    .padding(.bottom)
            }
            
            VStack(alignment: .leading) {
                Text("Logging")
                    .font(.headline)
                
                Toggle("Enable debug logging", isOn: $viewModel.enableLogging)
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
    let section: SettingsSection
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

struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            if isShowing {
                HStack {
                    Image(systemName: type.iconName)
                        .foregroundColor(type.color)
                    
                    Text(message)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        isShowing = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(type.color, lineWidth: 1)
                )
                .shadow(radius: 3)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: isShowing)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let store = PromptStore()
        return SettingsView(store: store)
    }
}