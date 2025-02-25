import SwiftUI
import Foundation

// Forward declarations to help the linter recognize types
#if canImport(PromptShelf)
import PromptShelf
#else
// These typealias declarations help the linter recognize types in the same module
// They won't affect the actual code compilation
typealias PromptStore = AnyObject
typealias Prompt = Any
typealias LLMModel = Any
#endif

// All types (PromptStore, Prompt, LLMModel) should be accessible 
// within the same module without explicit imports

struct PromptImproveView: View {
    @ObservedObject var store: PromptStore
    let promptID: UUID
    @Binding var isShowing: Bool
    
    @State private var isLoading = false
    @State private var improvedText = ""
    @State private var errorMessage: String? = nil
    
    private var prompt: Prompt? {
        store.prompts[promptID]
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                Text("LLM Improvement")
                    .font(.title2.bold())
                
                Spacer()
                
                Button("Close") {
                    isShowing = false
                }
                .buttonStyle(.bordered)
            }
            
            // Original prompt
            VStack(alignment: .leading) {
                Text("Original Prompt")
                    .font(.headline)
                
                ScrollView {
                    Text(prompt?.text ?? "")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(height: 120)
            }
            
            // Model selector
            HStack {
                Text("LLM Model:")
                    .font(.headline)
                
                Picker("", selection: $store.selectedLLMModel) {
                    ForEach(LLMModel.allCases, id: \.self) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 250)
                
                Spacer()
                
                Button(action: improveLLM) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Text("Improve with LLM")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || prompt == nil || store.getAPIKey(service: store.selectedLLMModel.rawValue) == nil)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Improved prompt (shown only when available)
            if !improvedText.isEmpty {
                VStack(alignment: .leading) {
                    Text("Improved Prompt")
                        .font(.headline)
                    
                    ScrollView {
                        Text(improvedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .frame(height: 180)
                    
                    HStack {
                        Spacer()
                        
                        Button("Apply Improvement") {
                            applyImprovement()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            
            Spacer()
            
            // API key management
            if store.getAPIKey(service: store.selectedLLMModel.rawValue) == nil {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    
                    Text("API key for \(store.selectedLLMModel.displayName) not found")
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button("Manage API Keys") {
                        // This should be handled in the parent view
                        isShowing = false
                        // Here we would normally trigger the settings sheet
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(width: 600, height: 500)
    }
    
    private func improveLLM() {
        errorMessage = nil
        isLoading = true
        
        store.improvePromptWithLLM(promptID: promptID) { result in
            isLoading = false
            
            switch result {
            case .success(let improved):
                improvedText = improved
            case .failure(let error):
                if let nsError = error as NSError?, nsError.domain == "APIKeyNotFound" {
                    errorMessage = "API key not configured. Please go to Settings to add your API key."
                } else if let nsError = error as NSError?, nsError.domain == "PromptNotFound" {
                    errorMessage = "Prompt not found."
                } else {
                    errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func applyImprovement() {
        guard !improvedText.isEmpty, let promptID = prompt?.id else { return }
        
        store.savePromptVersion(
            id: promptID, 
            text: improvedText,
            improvedByLLM: true,
            llmModel: store.selectedLLMModel.rawValue,
            notes: "Improved by \(store.selectedLLMModel.displayName)"
        )
        
        isShowing = false
    }
} 