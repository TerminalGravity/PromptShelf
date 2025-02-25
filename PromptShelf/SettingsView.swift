import SwiftUI
import Foundation
import AppKit

// MARK: - Settings View

struct SettingsView: View {
    // Use the ViewModel instead of directly referencing PromptStore
    @StateObject private var viewModel: SettingsViewModel
    @State private var showResetConfirmation = false
    
    // Initialize with a PromptStore
    init(store: PromptStore) {
        // Create the ViewModel using _StateObject wrapper
        _viewModel = StateObject(wrappedValue: SettingsViewModel(store: store))
    }
    
    // MARK: - Main View Body
    
    var body: some View {
        NavigationView {
            // Left sidebar with setting categories
            sidebarView
            
            // Right content area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch viewModel.selectedSection {
                    case .apiKeys:
                        apiKeysView
                    case .apiUsage:
                        apiUsageView
                    case .appearance:
                        appearanceView
                    case .advanced:
                        advancedView
                    case .about:
                        aboutView
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .overlay(
                toastView
                    .opacity(viewModel.showToast ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showToast)
                    .padding(),
                alignment: .bottom
            )
        }
        .frame(width: 900, height: 600)
    }
    
    // MARK: - Sidebar View
    
    private var sidebarView: some View {
        List(selection: $viewModel.selectedSection) {
            Section(header: Text("Settings")) {
                sidebarRow(title: "API Keys", icon: "key.fill", section: .apiKeys)
                sidebarRow(title: "API Usage", icon: "chart.bar.fill", section: .apiUsage)
                sidebarRow(title: "Appearance", icon: "paintbrush.fill", section: .appearance)
                sidebarRow(title: "Advanced", icon: "gearshape.2.fill", section: .advanced)
            }
            
            Section(header: Text("Info")) {
                sidebarRow(title: "About", icon: "info.circle.fill", section: .about)
            }
        }
        .listStyle(.sidebar)
        .frame(width: 220)
    }
    
    private func sidebarRow(title: String, icon: String, section: SettingsSection) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(viewModel.selectedSection == section ? .accentColor : .gray)
                .frame(width: 24)
            
            Text(title)
                .font(.system(.body, design: .rounded))
        }
        .padding(.vertical, 4)
        .tag(section)
    }
    
    // MARK: - API Keys View
    
    private var apiKeysView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("API Keys")
                .font(.title.bold())
                .foregroundColor(.primary)
            
            providerSelectionView
            
            if let selectedProvider = viewModel.selectedProvider {
                // Filter toggle for reasoning models
                if selectedProvider.models.contains(where: { $0.hasReasoningCapability }) {
                    Toggle("Show only reasoning-capable models", isOn: $viewModel.showReasoningModelsOnly)
                        .padding(.bottom, 10)
                }
                
                // Models for selected provider
                modelSelectionView(for: selectedProvider)
                
                Divider()
                
                apiKeyInputView
                
                Toggle("Show API Key", isOn: $viewModel.showAPIKey)
                
                HStack {
                    Button("Validate API Key") {
                        viewModel.validateAPIKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.apiKey.isEmpty || viewModel.isValidating)
                    
                    if viewModel.isValidating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                            .padding(.leading, 5)
                    }
                    
                    Spacer()
                    
                    Button("Save API Key") {
                        viewModel.saveAPIKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.apiKey.isEmpty)
                    
                    Button("Delete API Key") {
                        viewModel.deleteAPIKey()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .disabled(viewModel.apiKey.isEmpty)
                }
                
                if viewModel.showGuide {
                    apiGuideView
                }
            } else {
                Text("Please select a provider from the list above")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    private var providerSelectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Provider")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(ModelProvider.allCases) { provider in
                        providerCard(provider: provider)
                    }
                }
                .padding(.bottom, 5)
            }
        }
    }
    
    private func providerCard(provider: ModelProvider) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        viewModel.selectedProvider == provider ?
                        LinearGradient(
                            colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: viewModel.selectedProvider == provider ? .blue.opacity(0.3) : .gray.opacity(0.2), radius: 5)
                
                Text(provider.displayName)
                    .font(.headline)
                    .foregroundColor(viewModel.selectedProvider == provider ? .white : .primary)
                    .padding(.vertical, 15)
                    .padding(.horizontal, 20)
                    .frame(minWidth: 100)
            }
            .frame(height: 50)
        }
        .onTapGesture {
            viewModel.selectedProvider = provider
            // Reset to the first model in this provider
            if let firstModel = provider.models.first {
                viewModel.selectedModel = firstModel
                if let savedKey = viewModel.store.getAPIKey(service: firstModel.rawValue) {
                    viewModel.apiKey = savedKey
                } else {
                    viewModel.apiKey = ""
                }
            }
        }
    }
    
    private func modelSelectionView(for provider: ModelProvider) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Model")
                .font(.headline)
            
            let filteredModels = viewModel.showReasoningModelsOnly ? 
                provider.models.filter({ $0.hasReasoningCapability }) : 
                provider.models
            
            if filteredModels.isEmpty {
                Text("No models match the current filter")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 5)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filteredModels) { model in
                            modelRow(model: model)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }
    
    private func modelRow(model: LLMModel) -> some View {
        HStack {
            Button(action: {
                viewModel.selectedModel = model
                if let savedKey = viewModel.store.getAPIKey(service: model.rawValue) {
                    viewModel.apiKey = savedKey
                } else {
                    viewModel.apiKey = ""
                }
            }) {
                HStack {
                    ZStack {
                        Circle()
                            .stroke(viewModel.selectedModel == model ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                        
                        if viewModel.selectedModel == model {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 12, height: 12)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.displayName)
                            .foregroundColor(.primary)
                            .font(.system(.body, design: .rounded))
                        
                        if model.hasReasoningCapability {
                            HStack(spacing: 4) {
                                Image(systemName: "brain.fill")
                                    .font(.caption2)
                                Text("Reasoning Capable")
                                    .font(.caption2)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    // Visual indicator if an API key exists
                    if viewModel.store.getAPIKey(service: model.rawValue) != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(viewModel.selectedModel == model ? Color.accentColor.opacity(0.1) : Color.clear)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var apiKeyInputView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("API Key for \(viewModel.selectedModel.displayName)")
                .font(.headline)
            
            if viewModel.showAPIKey {
                TextField("Enter API key", text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
            } else {
                SecureField("Enter API key", text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
            }
        }
    }
    
    private var apiGuideView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("API Key Guide")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { viewModel.showGuide = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("1. Select your preferred model provider")
                Text("2. Select a specific model from that provider")
                Text("3. Enter your API key for the selected model")
                Text("4. Click 'Validate API Key' to test the connection")
                Text("5. Save your API key securely in your system keychain")
            }
            .font(.system(.body, design: .rounded))
            .foregroundColor(.secondary)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - API Usage View
    
    private var apiUsageView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("API Usage Statistics")
                .font(.title.bold())
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                usageStatCard(
                    title: "Total API Calls",
                    value: "\(viewModel.store.apiUsageStats.totalCalls)",
                    icon: "arrow.up.arrow.down",
                    color: .blue
                )
                
                usageStatCard(
                    title: "Total Tokens Used",
                    value: "\(viewModel.store.apiUsageStats.totalTokensUsed)",
                    icon: "character.bubble",
                    color: .green
                )
                
                usageStatCard(
                    title: "Estimated Cost",
                    value: "$\(String(format: "%.2f", viewModel.store.apiUsageStats.estimatedCost()))",
                    icon: "dollarsign.circle",
                    color: .orange
                )
            }
            
            Spacer().frame(height: 10)
            
            Text("Usage by Model")
                .font(.headline)
            
            if viewModel.store.apiUsageStats.callsByModel.isEmpty {
                Text("No API calls have been recorded yet.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.store.apiUsageStats.callsByModel.keys.sorted()), id: \.self) { model in
                        if let calls = viewModel.store.apiUsageStats.callsByModel[model],
                           let tokens = viewModel.store.apiUsageStats.tokensByModel[model] {
                            modelUsageRow(
                                model: model,
                                calls: calls,
                                tokens: tokens,
                                totalCalls: viewModel.store.apiUsageStats.totalCalls
                            )
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                if viewModel.store.apiUsageStats.totalCalls > 0 {
                    Text("Last updated: \(dateFormatter.string(from: viewModel.store.apiUsageStats.lastUpdated))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                }
                
                Button("Reset API Usage Data") {
                    viewModel.showResetConfirmation = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .padding(.top, 10)
                .alert(isPresented: $viewModel.showResetConfirmation) {
                    Alert(
                        title: Text("Reset API Usage Data"),
                        message: Text("Are you sure you want to reset all API usage data? This cannot be undone."),
                        primaryButton: .destructive(Text("Reset")) {
                            viewModel.resetAPIUsageData()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }
    
    private func usageStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func modelUsageRow(model: String, calls: Int, tokens: Int, totalCalls: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(getDisplayName(for: model))
                    .font(.headline)
                
                Spacer()
                
                Text("\(calls) calls · \(tokens) tokens")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Usage bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .cornerRadius(5)
                    
                    // Filled portion
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: totalCalls > 0 ? CGFloat(calls) / CGFloat(totalCalls) * geometry.size.width : 0)
                        .cornerRadius(5)
                }
            }
            .frame(height: 8)
        }
    }
    
    private func getDisplayName(for modelId: String) -> String {
        if let model = LLMModel.allCases.first(where: { $0.rawValue == modelId }) {
            return model.displayName
        }
        return modelId
    }
    
    private func resetAPIUsageData() {
        // Reset the API usage stats
        viewModel.store.apiUsageStats = PromptStore.APIUsageStats()
        
        // Save the reset stats
        UserDefaults.standard.removeObject(forKey: "APIUsageStats")
        
        // Show confirmation toast
        viewModel.showToast(message: "API usage data has been reset", type: .success)
    }
    
    // MARK: - Appearance View
    
    private var appearanceView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Appearance")
                .font(.title.bold())
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Theme")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    themeCard(theme: .classic, name: "Classic")
                    themeCard(theme: .dark, name: "Dark")
                    themeCard(theme: .light, name: "Light")
                    themeCard(theme: .system, name: "System")
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Customization")
                    .font(.headline)
                
                Toggle("Use compact sidebar", isOn: .constant(false))
                Toggle("Show prompt creation date", isOn: .constant(true))
                Toggle("Enable animations", isOn: .constant(true))
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func themeCard(theme: AppTheme, name: String) -> some View {
        Button(action: { viewModel.selectedTheme = theme }) {
            VStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        theme == .dark ? Color.black :
                        theme == .light ? Color.white :
                        Color.gray.opacity(0.3)
                    )
                    .frame(width: 120, height: 70)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(viewModel.selectedTheme == theme ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                
                Text(name)
                    .foregroundColor(viewModel.selectedTheme == theme ? .accentColor : .primary)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Advanced View
    
    private var advancedView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Advanced Settings")
                .font(.title.bold())
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("API Rate Limiting")
                    .font(.headline)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Requests per minute:")
                        Spacer()
                        Text("\(Int(viewModel.rateLimitValue))")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $viewModel.rateLimitValue, in: 1...30, step: 1)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Cache Settings")
                    .font(.headline)
                
                VStack(alignment: .leading) {
                    Toggle("Enable response caching", isOn: $viewModel.enableCaching)
                    Text("Caching can reduce API calls by storing responses for similar prompts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if viewModel.enableCaching {
                        HStack {
                            Text("Cache duration:")
                            Picker("", selection: .constant(1)) {
                                Text("1 day").tag(1)
                                Text("1 week").tag(7)
                                Text("1 month").tag(30)
                                Text("Forever").tag(0)
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(.top, 5)
                    }
                    
                    Divider()
                    
                    Button("Clear Cache") {
                        viewModel.showToast(message: "Cache cleared successfully", type: .success)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.enableCaching)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Logging")
                    .font(.headline)
                
                VStack(alignment: .leading) {
                    Toggle("Enable debug logging", isOn: $viewModel.enableLogging)
                    
                    if viewModel.enableLogging {
                        Toggle("Include API request/response logs", isOn: .constant(true))
                            .padding(.leading)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - About View
    
    private var aboutView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About PromptShelf")
                .font(.title.bold())
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Version 1.0")
                    .font(.headline)
                Text("© 2023 Prompt Engineering Inc.")
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            Text("PromptShelf is a powerful tool for managing, organizing, and improving your AI prompts. Enhance your interactions with AI models by creating, storing, and refining prompts for various purposes.")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Features")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 5) {
                    featureRow(icon: "folder.fill", text: "Organize prompts in folders")
                    featureRow(icon: "sparkles", text: "Improve prompts with AI assistance")
                    featureRow(icon: "clock.arrow.circlepath", text: "Track version history")
                    featureRow(icon: "lock.fill", text: "Secure API key management")
                    featureRow(icon: "chart.bar.fill", text: "Monitor API usage and costs")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            HStack {
                Spacer()
                
                Button("Visit Website") {
                    // Open website
                }
                .buttonStyle(.bordered)
                
                Button("Check for Updates") {
                    viewModel.showToast(message: "You're running the latest version", type: .success)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            Text(text)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Toast View
    
    private var toastView: some View {
        HStack(spacing: 15) {
            Image(systemName: viewModel.toastType.iconName)
                .foregroundColor(viewModel.toastType.color)
            
            Text(viewModel.toastMessage)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: { viewModel.showToast = false }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .transition(.move(edge: .bottom))
    }
    
    // MARK: - Helper Functions
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}