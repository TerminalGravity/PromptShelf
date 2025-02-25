import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: PromptStore
    @State private var apiKey = ""
    @State private var selectedModel: LLMModel = .gpt4
    @State private var showAPIKey = false
    @State private var saveSuccess = false
    @State private var saveError = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("API Key Management")
                .font(.title2.bold())
                .padding(.bottom, 5)
            
            // Model selector
            Picker("LLM Model", selection: $selectedModel) {
                ForEach(LLMModel.allCases, id: \.self) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedModel) { _ in
                // Load API key for selected model if it exists
                if let key = store.getAPIKey(service: selectedModel.rawValue) {
                    apiKey = key
                    showAPIKey = false
                } else {
                    apiKey = ""
                }
            }
            
            // API Key input
            VStack(alignment: .leading) {
                Text("API Key")
                    .font(.headline)
                
                HStack {
                    if showAPIKey {
                        TextField("Enter API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Enter API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Button(action: { showAPIKey.toggle() }) {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                }
                
                if saveSuccess {
                    Text("API key saved successfully!")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                if saveError {
                    Text("Failed to save API key")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            // Buttons
            HStack {
                Button("Save API Key") {
                    let success = store.saveAPIKey(service: selectedModel.rawValue, key: apiKey)
                    saveSuccess = success
                    saveError = !success
                    
                    // Update the selected model in the store
                    if success {
                        store.selectedLLMModel = selectedModel
                        
                        // Clear status after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            saveSuccess = false
                            saveError = false
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.isEmpty)
                
                Button("Delete API Key") {
                    let success = store.deleteAPIKey(service: selectedModel.rawValue)
                    if success {
                        apiKey = ""
                        saveSuccess = true
                        
                        // Clear status after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            saveSuccess = false
                        }
                    } else {
                        saveError = true
                        
                        // Clear status after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            saveError = false
                        }
                    }
                }
                .buttonStyle(.bordered)
                .disabled(apiKey.isEmpty)
            }
            
            Divider()
            
            // Usage info
            VStack(alignment: .leading, spacing: 10) {
                Text("API Usage Guide")
                    .font(.headline)
                
                Text("• Your API key is stored securely in the macOS Keychain")
                    .font(.caption)
                
                Text("• Different API keys can be saved for each LLM model")
                    .font(.caption)
                
                Text("• API calls are made directly from your computer to the LLM provider")
                    .font(.caption)
                
                Text("• Standard API usage rates from your provider apply")
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 450, height: 450)
        .onAppear {
            selectedModel = store.selectedLLMModel
            if let key = store.getAPIKey(service: selectedModel.rawValue) {
                apiKey = key
            }
        }
    }
}

extension LLMModel {
    var displayName: String {
        switch self {
        case .gpt4:
            return "OpenAI GPT-4"
        case .gpt35Turbo:
            return "OpenAI GPT-3.5 Turbo"
        case .claude3:
            return "Anthropic Claude 3 Opus"
        case .claude3Sonnet:
            return "Anthropic Claude 3 Sonnet"
        }
    }
} 