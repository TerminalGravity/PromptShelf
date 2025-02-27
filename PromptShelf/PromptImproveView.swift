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
    @State private var retryCount = 0
    @State private var showDiff = false
    @State private var isValidatingPrompt = false
    
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
    
    /// Whether the API key is configured for the selected model
    private var isAPIKeyConfigured: Bool {
        store.isProviderConfigured(store.selectedLLMModel.provider)
    }
    
    /// Get the list of providers that have API keys configured
    private var configuredProviders: [ModelProvider] {
        return ModelProvider.allCases.filter { store.isProviderConfigured($0) }
    }
    
    /// Checks if the selected model belongs to a provider that has a configured API key
    private var isSelectedModelAvailable: Bool {
        return configuredProviders.contains(store.selectedLLMModel.provider)
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
    
    /// Button is disabled when no API keys at all or when generating improvements
    private var isGenerateButtonDisabled: Bool {
        (configuredProviders.isEmpty && !isAPIKeyConfigured) ||
        isImproving || isModelChanging || prompt == nil || isValidatingPrompt
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
                .help("Close this window and return to the main view")
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
                                    .opacity(store.isProviderConfigured(model.provider) ? 1.0 : 0.5)
                                
                                if model.hasReasoningCapability {
                                    Image(systemName: "brain.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                                
                                // Show indicator for configured keys
                                if store.isProviderConfigured(model.provider) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                } else {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                }
                            }.tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 250)
                    .disabled(isImproving)
                    .help("Select the AI model to use for improving your prompt")
                    
                    // Show badge with number of configured providers
                    Text("\(configuredProviders.count)/\(ModelProvider.allCases.count) providers configured")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                        .padding(.leading, 4)
                    
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
                    
                    if isImproving {
                        Button("Cancel") {
                            improvementTask?.cancel()
                            isImproving = false
                            displayToast(message: "Improvement cancelled", type: .info)
                        }
                        .buttonStyle(.bordered)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: isImproving)
                        .help("Cancel the current improvement process")
                    }
                    
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
                            HStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                                    .padding(.horizontal, 5)
                                
                                Text("Generating improvement...")
                                    .font(.callout)
                            }
                            .padding(.horizontal, 5)
                        } else if isValidatingPrompt {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                                Text("Validating prompt...")
                                    .font(.callout)
                            }
                        } else {
                            if !configuredProviders.isEmpty && !isAPIKeyConfigured {
                                // The current provider isn't configured but others are
                                Text("Use Available Provider")
                            } else {
                                Text("Improve with \(store.selectedLLMModel.displayName)")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGenerateButtonDisabled)
                    .animation(.easeInOut(duration: 0.2), value: isImproving)
                    .animation(.easeInOut(duration: 0.2), value: isValidatingPrompt)
                    .help(isAPIKeyConfigured ? 
                          "Generate an improved version of your prompt" : 
                          configuredProviders.isEmpty ? 
                              "API key is required. Configure it in Settings." :
                              "This provider is not configured, but others are available.")
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
                        
                        Toggle("Show Diff", isOn: $showDiff)
                            .toggleStyle(SwitchToggleStyle())
                            .help("Show the differences between original and improved versions")
                            .foregroundColor(textColor)
                            .labelsHidden()
                            .padding(.horizontal, 5)
                        
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
                            .help("Toggle visibility of the AI's reasoning process")
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
                        if showDiff {
                            SuggestionRow(
                                original: prompt?.text ?? "",
                                improved: improvedText,
                                textColor: textColor,
                                backgroundColor: improvedBackgroundColor
                            )
                            .padding()
                        } else {
                            Text(improvedText)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(improvedBackgroundColor)
                                .cornerRadius(8)
                                .foregroundColor(textColor)
                        }
                    }
                    .frame(height: showReasoning ? 140 : 180)
                    .animation(.easeInOut(duration: 0.3), value: showReasoning)
                    
                    HStack {
                        Button("Revert") {
                            withAnimation {
                                improvedText = ""
                                reasoningText = ""
                                showReasoning = false
                                showDiff = false
                            }
                        }
                        .buttonStyle(.bordered)
                        .help("Clear the current improvement")
                        
                        Spacer()
                        
                        Button("Copy to Clipboard") {
                            copyToClipboard(improvedText)
                            displayToast(message: "Copied to clipboard", type: .success)
                        }
                        .buttonStyle(.bordered)
                        .help("Copy the improved prompt to the clipboard")
                        
                        Button("Apply Improvement") {
                            Task {
                                await applyImprovement()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .help("Save this improvement as a new version of the prompt")
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: !improvedText.isEmpty)
            }
            
            Spacer()
            
            // API key management
            if !isAPIKeyConfigured {
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
                    .help("Go to Settings to add or update your API keys")
                }
                .padding()
                .background(warningBackgroundColor)
                .cornerRadius(8)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: !isAPIKeyConfigured)
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
    
    /// Validates the prompt before sending to the LLM
    private func validatePrompt(_ text: String) -> Bool {
        // Check for prompt length - most APIs have token limits
        if text.count > 10000 {
            errorMessage = "Prompt is too long (over 10,000 characters). Please reduce the length."
            displayToast(message: errorMessage ?? "Prompt is too long", type: .error)
            return false
        }
        
        // Check for empty prompt
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Prompt cannot be empty. Please enter valid content."
            displayToast(message: errorMessage ?? "Prompt is empty", type: .error)
            return false
        }
        
        return true
    }
    
    /// Generates an improved version of the prompt using the selected LLM
    private func generateImprovement() async {
        guard let prompt = prompt else {
            displayToast(message: "No prompt found to improve", type: .error)
            return
        }
        
        // Update UI state
        await MainActor.run {
            errorMessage = nil
            isImproving = false
            isValidatingPrompt = true
            improvedText = ""
            reasoningText = ""
            showReasoning = false
            retryCount = 0
        }
        
        // Validate prompt before sending
        let isValid = await MainActor.run {
            return validatePrompt(prompt.text)
        }
        
        if !isValid {
            await MainActor.run {
                isValidatingPrompt = false
            }
            return
        }
        
        await MainActor.run {
            isValidatingPrompt = false
            isImproving = true
        }
        
        // Check if we need to use an alternative provider due to missing API key
        var modelToUse = store.selectedLLMModel
        if !isAPIKeyConfigured && !configuredProviders.isEmpty {
            // Find the first configured provider and use its first model
            if let firstAvailableProvider = configuredProviders.first,
               let firstModel = firstAvailableProvider.models.first {
                modelToUse = firstModel
                await MainActor.run {
                    displayToast(message: "Using \(firstModel.displayName) instead (API key configured)", type: .info)
                }
            }
        }
        
        // Try improvement with retry mechanism
        var shouldRetry = false
        var result: Result<String, Error>? = nil
        
        repeat {
            shouldRetry = false
            
            do {
                // Request improved prompt from store with potentially different model
                result = await withCheckedContinuation { continuation in
                    // Use temporary override of the model if needed
                    let originalModel = store.selectedLLMModel
                    if modelToUse != originalModel {
                        store.selectedLLMModel = modelToUse
                    }
                    
                    store.improvePromptWithLLM(promptID: promptID, useReasoning: useReasoning) { result in
                        // Restore original model selection if changed
                        if modelToUse != originalModel {
                            Task { @MainActor in
                                store.selectedLLMModel = originalModel
                            }
                        }
                        continuation.resume(returning: result)
                    }
                }
                
                // If we get a network error, retry up to 3 times
                if case .failure(let error) = result {
                    let nsError = error as NSError
                    if (nsError.domain == "NetworkError" || nsError.domain == "TimeoutError") && retryCount < 3 {
                        retryCount += 1
                        shouldRetry = true
                        
                        // Add exponential backoff
                        let backoffTime = Double(1 << retryCount) * 0.5 // 1s, 2s, 4s
                        await MainActor.run {
                            displayToast(message: "Network issue, retrying in \(backoffTime)s (Attempt \(retryCount)/3)", type: .warning)
                        }
                        
                        // Wait before retrying
                        try await Task.sleep(nanoseconds: UInt64(backoffTime * 1_000_000_000))
                    } else if nsError.domain == "APIKeyNotFound" && !configuredProviders.isEmpty {
                        // Try a different provider if this one's API key is missing or invalid
                        if let nextProvider = configuredProviders.first(where: { $0 != modelToUse.provider }),
                           let alternativeModel = nextProvider.models.first {
                            modelToUse = alternativeModel
                            await MainActor.run {
                                displayToast(message: "Trying with \(alternativeModel.displayName) instead", type: .info)
                            }
                            shouldRetry = true
                        }
                    }
                }
            } catch {
                // Handle task cancellation
                if error is CancellationError {
                    await MainActor.run {
                        isImproving = false
                        displayToast(message: "Improvement cancelled", type: .info)
                    }
                    return
                }
                
                result = .failure(error)
            }
        } while shouldRetry && !Task.isCancelled
        
        // Update UI with result
        await MainActor.run {
            isImproving = false
            
            if let result = result {
                switch result {
                case .success(let improved):
                    parseLLMResponse(improved)
                    
                    // Show message about which model was actually used if different
                    if modelToUse != store.selectedLLMModel {
                        displayToast(message: "Prompt improved successfully with \(modelToUse.displayName)", type: .success)
                    } else {
                        displayToast(message: "Prompt improved successfully", type: .success)
                    }
                    
                case .failure(let error):
                    handleError(error)
                }
            }
        }
    }
    
    /// Parses the response from the LLM, separating reasoning from improved prompt
    private func parseLLMResponse(_ response: String) {
        // Support multiple formats of LLM responses
        let reasoningMarkers = [
            "REASONING:", "Reasoning:", "REASONING PROCESS:", "Here's my reasoning:", 
            "RATIONALE:", "Rationale:", "MY THOUGHT PROCESS:", "My thought process:"
        ]
        let promptMarkers = [
            "IMPROVED PROMPT:", "Improved Prompt:", "FINAL PROMPT:", "Here's the improved prompt:",
            "REVISED PROMPT:", "Revised Prompt:", "NEW PROMPT:", "IMPROVED VERSION:", "RESULT:"
        ]
        
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
        
        // Check for JSON format - some models return structured data
        if !foundReasoning && !foundPrompt && response.contains("{") && response.contains("}") {
            if let startIndex = response.firstIndex(of: "{"), 
               let endIndex = response.lastIndex(of: "}"), 
               startIndex < endIndex {
                
                let jsonSubstring = response[startIndex...endIndex]
                let jsonString = String(jsonSubstring)
                
                do {
                    if let data = jsonString.data(using: .utf8),
                       let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        
                        // Check for common JSON keys used by different models
                        if let improvedPrompt = json["improved_prompt"] as? String ?? 
                                           json["improvedPrompt"] as? String ??
                                           json["result"] as? String {
                            improved = improvedPrompt
                            foundPrompt = true
                        }
                        
                        if let reasoningExplanation = json["reasoning"] as? String ??
                                                json["explanation"] as? String ??
                                                json["rationale"] as? String {
                            reasoning = reasoningExplanation
                            foundReasoning = true
                        }
                    }
                } catch {
                    // JSON parsing failed, continue with other methods
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

// MARK: - SuggestionRow
/// A view that shows differences between original and improved prompts
struct SuggestionRow: View {
    let original: String
    let improved: String
    let textColor: Color
    let backgroundColor: Color
    
    @State private var isExpanded = false
    
    private var diffLines: [(original: String?, improved: String?, isDifferent: Bool)] {
        return computeDiff(original: original, improved: improved)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Differences")
                        .font(.subheadline.bold())
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(0..<diffLines.count, id: \.self) { index in
                            let diff = diffLines[index]
                            
                            if diff.isDifferent {
                                HStack(alignment: .top, spacing: 10) {
                                    if let original = diff.original {
                                        Text(original)
                                            .foregroundColor(.red)
                                            .strikethrough()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(4)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(4)
                                    } else {
                                        Spacer()
                                    }
                                    
                                    if let improved = diff.improved {
                                        Text(improved)
                                            .foregroundColor(.green)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(4)
                                            .background(Color.green.opacity(0.1))
                                            .cornerRadius(4)
                                    } else {
                                        Spacer()
                                    }
                                }
                            } else if let text = diff.original {
                                Text(text)
                                    .foregroundColor(textColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            } else {
                // Show a summary of differences when collapsed
                HStack {
                    Text("Click to see \(diffLines.filter { $0.isDifferent }.count) differences")
                        .font(.caption)
                        .foregroundColor(textColor.opacity(0.7))
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            
            Divider()
            
            // Complete improved text
            Text("Complete Improved Text:")
                .font(.subheadline.bold())
                .padding(.top, 4)
            
            Text(improved)
                .foregroundColor(textColor)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
    
    // Simple diffing algorithm to find differences between original and improved
    private func computeDiff(original: String, improved: String) -> [(original: String?, improved: String?, isDifferent: Bool)] {
        let originalLines = original.components(separatedBy: .newlines)
        let improvedLines = improved.components(separatedBy: .newlines)
        
        var result: [(original: String?, improved: String?, isDifferent: Bool)] = []
        
        // Simple line-by-line diff
        let maxLen = max(originalLines.count, improvedLines.count)
        
        for i in 0..<maxLen {
            let originalLine = i < originalLines.count ? originalLines[i] : nil
            let improvedLine = i < improvedLines.count ? improvedLines[i] : nil
            
            let isDifferent = originalLine != improvedLine
            result.append((originalLine, improvedLine, isDifferent))
        }
        
        return result
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