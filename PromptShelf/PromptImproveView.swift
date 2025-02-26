import SwiftUI
import Foundation
import Combine

/// A view for improving prompts with AI language models, supporting reasoning capability and dark mode
struct PromptImproveView: View {
    @ObservedObject var store: PromptStore
    let promptID: UUID
    @Binding var isShowing: Bool
    
    // State variables
    @State private var isImproving = false
    @State private var improvedText = ""
    @State private var reasoningText = ""
    @State private var errorMessage: String? = nil
    @State private var useReasoning = false
    @State private var showReasoning = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .info
    @State private var isModelChanging = false
    @State private var improvementTask: Task<Void, Never>? = nil
    
    // Environment support for dark mode
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Computed Properties
    
    /// The prompt being improved
    private var prompt: Prompt? {
        store.prompts[promptID]
    }
    
    /// Whether the selected model supports reasoning capability
    private var canUseReasoning: Bool {
        store.selectedLLMModel.hasReasoningCapability
    }
    
    /// Primary background color for the view based on current theme
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.white
    }
    
    /// Background color for prompt cards based on current theme
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.6) : Color.gray.opacity(0.1)
    }
    
    /// Background color for improved prompt based on current theme
    private var improvedBackgroundColor: Color {
        colorScheme == .dark ? Color.blue.opacity(0.15) : Color.blue.opacity(0.05)
    }
    
    /// Primary text color based on current theme
    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    /// Secondary text color based on current theme
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
    
    /// Warning background color based on current theme
    private var warningBackgroundColor: Color {
        colorScheme == .dark ? Color.orange.opacity(0.2) : Color.orange.opacity(0.1)
    }
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                Text("Improve Prompt: \(prompt?.title ?? "")")
                    .font(.title2.bold())
                    .foregroundColor(textColor)
                
                Spacer()
                
                Button("Close") {
                    // Cancel any running task before closing
                    improvementTask?.cancel()
                    isShowing = false
                }
                .buttonStyle(.bordered)
            }
            
            // Original prompt
            VStack(alignment: .leading) {
                Text("Original Prompt")
                    .font(.headline)
                    .foregroundColor(textColor)
                
                ScrollView {
                    Text(prompt?.text ?? "")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(cardBackgroundColor)
                        .cornerRadius(8)
                        .foregroundColor(textColor)
                }
                .frame(height: 120)
            }
            
            // Model selector and reasoning toggle
            VStack(spacing: 10) {
                HStack {
                    Text("LLM Model:")
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    Picker("", selection: $store.selectedLLMModel) {
                        ForEach(LLMModel.allCases, id: \.self) { model in
                            HStack {
                                Text(model.displayName)
                                    .foregroundColor(textColor)
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
                    .disabled(isImproving)
                    
                    Spacer()
                }
                
                if canUseReasoning {
                    HStack {
                        Toggle("Enable reasoning mode", isOn: $useReasoning)
                            .toggleStyle(SwitchToggleStyle())
                            .help("When enabled, the AI will explain its reasoning process")
                            .foregroundColor(textColor)
                            .disabled(isImproving)
                        
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
                    
                    if isModelChanging {
                        Text("Updating model selection...")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                            .padding(.trailing, 8)
                    }
                    
                    Button(action: {
                        improvementTask = Task {
                            await generateImprovement()
                        }
                    }) {
                        if isImproving {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                                .padding(.horizontal, 10)
                        } else {
                            Text("Improve with \(store.selectedLLMModel.displayName)")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isImproving || isModelChanging || prompt == nil || 
                              store.getAPIKey(service: store.selectedLLMModel.provider.rawValue) == nil)
                    .animation(.easeInOut(duration: 0.2), value: isImproving)
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: errorMessage != nil)
            }
            
            // Improved prompt (shown only when available)
            if !improvedText.isEmpty {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Improved Prompt")
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        if !reasoningText.isEmpty {
                            Button(action: { 
                                withAnimation {
                                    showReasoning.toggle()
                                }
                            }) {
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
                                    .background(improvedBackgroundColor)
                                    .cornerRadius(8)
                                    .foregroundColor(textColor)
                            }
                        }
                        .frame(height: 140)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: showReasoning)
                    }
                    
                    ScrollView {
                        Text(improvedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(improvedBackgroundColor)
                            .cornerRadius(8)
                            .foregroundColor(textColor)
                    }
                    .frame(height: showReasoning ? 140 : 180)
                    .animation(.easeInOut(duration: 0.3), value: showReasoning)
                    
                    HStack {
                        Button("Revert") {
                            withAnimation {
                                improvedText = ""
                                reasoningText = ""
                                showReasoning = false
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Copy to Clipboard") {
                            copyToClipboard(improvedText)
                            displayToast(message: "Copied to clipboard", type: .success)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Apply Improvement") {
                            Task {
                                await applyImprovement()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: !improvedText.isEmpty)
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
                        isShowing = false
                        // Trigger settings with notification
                        NotificationCenter.default.post(
                            name: NSNotification.Name("OpenSettingsSection"),
                            object: nil,
                            userInfo: ["section": "apiKeys"]
                        )
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(warningBackgroundColor)
                .cornerRadius(8)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: store.getAPIKey(service: store.selectedLLMModel.provider.rawValue) == nil)
            }
        }
        .padding()
        .frame(width: 700, height: 600)
        .background(backgroundColor)
        .onChange(of: store.selectedLLMModel) { newModel in
            Task { @MainActor in
                // Update UI to show model is changing
                isModelChanging = true
                
                // If the new model doesn't support reasoning, disable it
                if !newModel.hasReasoningCapability {
                    useReasoning = false
                }
                
                // Debounce model changes
                do {
                    try await Task.sleep(nanoseconds: 300_000_000) // 0.3-second debounce
                    isModelChanging = false
                } catch {
                    // Handle task cancellation
                    isModelChanging = false
                }
            }
        }
        .overlay(
            Group {
                if showToast {
                    ToastView(
                        message: toastMessage,
                        type: toastType,
                        isShowing: $showToast
                    )
                }
            }
        )
        .onDisappear {
            // Clean up any running tasks when view disappears
            improvementTask?.cancel()
        }
    }
    
    // MARK: - Methods
    
    /// Generates an improved version of the prompt using the selected LLM
    private func generateImprovement() async {
        // Update UI state
        await MainActor.run {
            errorMessage = nil
            isImproving = true
            improvedText = ""
            reasoningText = ""
            showReasoning = false
        }
        
        do {
            // Request improved prompt from store
            let result = await withCheckedContinuation { continuation in
                store.improvePromptWithLLM(promptID: promptID, useReasoning: useReasoning) { result in
                    continuation.resume(returning: result)
                }
            }
            
            // Update UI with result
            await MainActor.run {
                isImproving = false
                
                switch result {
                case .success(let improved):
                    parseLLMResponse(improved)
                    displayToast(message: "Prompt improved successfully", type: .success)
                case .failure(let error):
                    handleError(error)
                }
            }
        } catch {
            // Handle any unexpected errors
            await MainActor.run {
                isImproving = false
                handleError(error)
            }
        }
    }
    
    /// Parses the response from the LLM, separating reasoning from improved prompt
    private func parseLLMResponse(_ response: String) {
        // Support multiple formats of LLM responses
        let reasoningMarkers = ["REASONING:", "Reasoning:", "REASONING PROCESS:", "Here's my reasoning:"]
        let promptMarkers = ["IMPROVED PROMPT:", "Improved Prompt:", "FINAL PROMPT:", "Here's the improved prompt:"]
        
        // Find reasoning section
        var foundReasoning = false
        var foundPrompt = false
        var reasoning = ""
        var improved = ""
        
        // Try to find structured format first (with both reasoning and improved sections)
        for reasoningMarker in reasoningMarkers {
            if response.contains(reasoningMarker) {
                for promptMarker in promptMarkers {
                    if response.contains(promptMarker) {
                        let parts = response.components(separatedBy: promptMarker)
                        if parts.count > 1 {
                            improved = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            let reasoningParts = parts[0].components(separatedBy: reasoningMarker)
                            if reasoningParts.count > 1 {
                                reasoning = reasoningParts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                            } else {
                                reasoning = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                            
                            foundReasoning = true
                            foundPrompt = true
                            break
                        }
                    }
                }
                
                if foundReasoning && foundPrompt {
                    break
                }
            }
        }
        
        // If structured format not found but we're expecting reasoning, make a best effort
        if useReasoning && !foundReasoning && !foundPrompt {
            // If no structured format but the response seems substantial, 
            // try to split it heuristically based on paragraph breaks
            let paragraphs = response.components(separatedBy: "\n\n")
            if paragraphs.count > 1 {
                // Assume first half is reasoning, last half is the improved prompt
                let midpoint = max(1, paragraphs.count / 2)
                reasoning = paragraphs[..<midpoint].joined(separator: "\n\n")
                improved = paragraphs[midpoint...].joined(separator: "\n\n")
                
                foundReasoning = true
                foundPrompt = true
            }
        }
        
        // If all parsing failed, just use the whole response as the improved prompt
        if !foundPrompt {
            improved = response
        }
        
        // Update state
        improvedText = improved
        if !reasoning.isEmpty {
            reasoningText = reasoning
            showReasoning = true
        }
    }
    
    /// Applies the improvement by saving it as a new version of the prompt
    private func applyImprovement() async {
        guard !improvedText.isEmpty, let promptID = prompt?.id else { return }
        
        let notes = useReasoning && !reasoningText.isEmpty ? 
            "Improved with reasoning by \(store.selectedLLMModel.displayName)" : 
            "Improved by \(store.selectedLLMModel.displayName)"
        
        let success = await Task<Bool, Never> {
            return store.savePromptVersion(
                id: promptID, 
                text: improvedText,
                improvedByLLM: true,
                llmModel: store.selectedLLMModel.rawValue,
                notes: notes
            )
        }.value
        
        await MainActor.run {
            if success {
                displayToast(message: "Improvement applied and saved", type: .success)
                // Give the toast a moment to appear before closing
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isShowing = false
                }
            } else {
                displayToast(message: "Failed to save improvement", type: .error)
            }
        }
    }
    
    /// Handles errors by categorizing them and displaying appropriate messages
    private func handleError(_ error: Error) {
        if let nsError = error as NSError? {
            switch nsError.domain {
            case "APIKeyNotFound":
                errorMessage = "API key not configured for \(store.selectedLLMModel.displayName). Please go to Settings to add your API key."
            case "PromptNotFound":
                errorMessage = "Prompt not found. It may have been deleted."
            case "NetworkError":
                errorMessage = "Network error: \(nsError.localizedDescription). Please check your internet connection."
            case "TimeoutError":
                errorMessage = "Request timed out. The server may be busy, please try again later."
            case "RateLimitError":
                errorMessage = "Rate limit exceeded for \(store.selectedLLMModel.provider.displayName). Please try again later."
            case "InvalidPromptError":
                errorMessage = "The prompt could not be processed. It may be too long or contain invalid content."
            case "AuthenticationError":
                errorMessage = "Authentication failed. Your API key may be invalid or expired."
            case "ServerError":
                errorMessage = "Server error: \(nsError.localizedDescription). Please try again later."
            case "ParseError":
                errorMessage = "Failed to parse the response from the model."
            default:
                errorMessage = "Error: \(nsError.localizedDescription)"
            }
        } else {
            errorMessage = "Error: \(error.localizedDescription)"
        }
        
        displayToast(message: errorMessage ?? "Improvement failed", type: .error)
    }
    
    /// Copies text to the clipboard
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    /// Displays a toast notification and posts a notification for app-wide toast system
    private func displayToast(message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        showToast = true
        
        // Automatically hide toast after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                showToast = false
            }
        }
        
        // Also post notification for app-wide toast system
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowToast"),
            object: nil,
            userInfo: ["message": message, "type": type.rawValue]
        )
    }
}

// MARK: - ToastView
/// A view that displays toast notifications with different styles based on type
struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.windowBackgroundColor).opacity(0.95) : Color(.windowBackgroundColor)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: type.iconName)
                    .foregroundColor(type.color)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(message)
                    .foregroundColor(textColor)
                    .font(.system(size: 14))
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(type.color, lineWidth: 1)
            )
            .padding()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: isShowing)
    }
} 