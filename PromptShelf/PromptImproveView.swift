import SwiftUI
import Foundation

// All types (PromptStore, Prompt, LLMModel) should be accessible 
// from the same module without explicit imports

struct PromptImproveView: View {
    @ObservedObject var store: PromptStore
    let promptID: UUID
    @Binding var isShowing: Bool
    
    @State private var isLoading = false
    @State private var improvedText = ""
    @State private var reasoningText = ""
    @State private var errorMessage: String? = nil
    @State private var useReasoning = false
    @State private var showReasoning = false
    
    private var prompt: Prompt? {
        store.prompts[promptID]
    }
    
    private var canUseReasoning: Bool {
        store.selectedLLMModel.hasReasoningCapability
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
            
            // Model selector and reasoning toggle
            VStack(spacing: 10) {
                HStack {
                    Text("LLM Model:")
                        .font(.headline)
                    
                    Picker("", selection: $store.selectedLLMModel) {
                        ForEach(LLMModel.allCases, id: \.self) { model in
                            HStack {
                                Text(model.displayName)
                                if model.hasReasoningCapability {
                                    Image(systemName: "brain.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                            }.tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 250)
                    
                    Spacer()
                }
                
                if canUseReasoning {
                    HStack {
                        Toggle("Enable reasoning mode", isOn: $useReasoning)
                            .toggleStyle(SwitchToggleStyle())
                            .help("When enabled, the AI will explain its reasoning process")
                        
                        if useReasoning {
                            Image(systemName: "brain.fill")
                                .foregroundColor(.blue)
                                .help("This model supports detailed reasoning")
                        }
                        
                        Spacer()
                    }
                }
                
                HStack {
                    Spacer()
                    
                    Button(action: improveLLM) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        } else {
                            Text("Improve with \(store.selectedLLMModel.displayName)")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || prompt == nil || store.getAPIKey(service: store.selectedLLMModel.provider.rawValue) == nil)
                }
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
                    HStack {
                        Text("Improved Prompt")
                            .font(.headline)
                        
                        Spacer()
                        
                        if !reasoningText.isEmpty {
                            Button(action: { showReasoning.toggle() }) {
                                HStack {
                                    Image(systemName: "brain")
                                    Text(showReasoning ? "Hide Reasoning" : "Show Reasoning")
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    if showReasoning && !reasoningText.isEmpty {
                        // Reasoning view
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("AI Reasoning Process")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Text(reasoningText)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(8)
                            }
                        }
                        .frame(height: 140)
                    }
                    
                    ScrollView {
                        Text(improvedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .frame(height: showReasoning ? 140 : 180)
                    
                    HStack {
                        Button("Revert") {
                            improvedText = ""
                            reasoningText = ""
                            showReasoning = false
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Copy to Clipboard") {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(improvedText, forType: .string)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Apply Improvement") {
                            applyImprovement()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            
            Spacer()
            
            // API key management
            if store.getAPIKey(service: store.selectedLLMModel.provider.rawValue) == nil {
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
        .frame(width: 700, height: 600)
        .onChange(of: store.selectedLLMModel) { newModel in
            // If the new model doesn't support reasoning, disable it
            if !newModel.hasReasoningCapability {
                useReasoning = false
            }
        }
    }
    
    private func improveLLM() {
        errorMessage = nil
        isLoading = true
        improvedText = ""
        reasoningText = ""
        showReasoning = false
        
        // Reset the reasoning text
        reasoningText = ""
        
        store.improvePromptWithLLM(promptID: promptID, useReasoning: useReasoning) { result in
            isLoading = false
            
            switch result {
            case .success(let improved):
                // If reasoning was used, try to separate the reasoning from the improved prompt
                if useReasoning && improved.contains("REASONING:") {
                    let parts = improved.components(separatedBy: "\n\nIMPROVED PROMPT:")
                    if parts.count > 1 {
                        reasoningText = parts[0].replacingOccurrences(of: "REASONING:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        improvedText = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        showReasoning = true
                    } else {
                        improvedText = improved
                    }
                } else {
                    improvedText = improved
                }
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
        
        let notes = useReasoning && !reasoningText.isEmpty ? 
            "Improved with reasoning by \(store.selectedLLMModel.displayName)" : 
            "Improved by \(store.selectedLLMModel.displayName)"
        
        store.savePromptVersion(
            id: promptID, 
            text: improvedText,
            improvedByLLM: true,
            llmModel: store.selectedLLMModel.rawValue,
            notes: notes
        )
        
        isShowing = false
    }
} 