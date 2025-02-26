import Foundation
import SwiftUI
import Combine

// This file serves as the single source of truth for all types used in the project
// All types are defined here to avoid ambiguous type lookup issues

// MARK: - Core Enums

/// Model Provider types (OpenAI, Anthropic, etc.)
public enum ModelProvider: String, CaseIterable, Identifiable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case google = "google"
    case deepSeek = "deepseek"
    case grok = "grok"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .google: return "Google"
        case .deepSeek: return "DeepSeek"
        case .grok: return "Grok"
        }
    }
    
    public var models: [LLMModel] {
        LLMModel.allCases.filter { $0.provider == self }
    }
}

/// Language model types (GPT-4, Claude, etc.)
public enum LLMModel: String, CaseIterable, Identifiable {
    // OpenAI Models
    case gpt4 = "gpt-4"
    case gpt4Turbo = "gpt-4-turbo"
    case gpt4o = "gpt-4o"
    case gpt35Turbo = "gpt-3.5-turbo"
    case o1 = "o1"
    case o1Mini = "o1-mini"
    
    // Anthropic Models
    case claude3Opus = "claude-3-opus"
    case claude3Sonnet = "claude-3-sonnet"
    case claude3Haiku = "claude-3-haiku"
    
    // Google Models
    case geminiPro = "gemini-pro"
    case geminiUltra = "gemini-ultra"
    
    // DeepSeek Models
    case deepSeekCoder = "deepseek-coder"
    case deepSeekChat = "deepseek-chat"
    
    // Grok Models
    case grok1 = "grok-1"
    
    public var id: String { rawValue }
    
    public var provider: ModelProvider {
        switch self {
        case .gpt4, .gpt4Turbo, .gpt4o, .gpt35Turbo, .o1, .o1Mini:
            return .openAI
        case .claude3Opus, .claude3Sonnet, .claude3Haiku:
            return .anthropic
        case .geminiPro, .geminiUltra:
            return .google
        case .deepSeekCoder, .deepSeekChat:
            return .deepSeek
        case .grok1:
            return .grok
        }
    }
    
    public var displayName: String {
        switch self {
        case .gpt4: return "GPT-4"
        case .gpt4Turbo: return "GPT-4 Turbo"
        case .gpt4o: return "GPT-4o"
        case .gpt35Turbo: return "GPT-3.5 Turbo"
        case .o1: return "o1"
        case .o1Mini: return "o1-mini"
        case .claude3Opus: return "Claude 3 Opus"
        case .claude3Sonnet: return "Claude 3 Sonnet"
        case .claude3Haiku: return "Claude 3 Haiku"
        case .geminiPro: return "Gemini Pro"
        case .geminiUltra: return "Gemini Ultra"
        case .deepSeekCoder: return "DeepSeek Coder"
        case .deepSeekChat: return "DeepSeek Chat"
        case .grok1: return "Grok-1"
        }
    }
    
    public var hasReasoningCapability: Bool {
        switch self {
        // Advanced OpenAI models support reasoning
        case .gpt4, .gpt4Turbo, .gpt4o, .o1:
            return true
        // Claude 3 Opus and Sonnet have strong reasoning abilities
        case .claude3Opus, .claude3Sonnet:
            return true
        // Gemini Ultra supports reasoning
        case .geminiUltra:
            return true
        // Other models have more limited reasoning capabilities
        default:
            return false
        }
    }
}

/// Prompt type categories
public enum PromptType: String, Codable, CaseIterable {
    case general = "General"
    case cursorFix = "Cursor Fix"
    case plannerMode = "Planner Mode"
}

/// Settings section types
public enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case models = "Models"
    case apiKeys = "API Keys"
    case appearance = "Appearance"
    case advanced = "Advanced"
    case about = "About"
    
    public var id: String { rawValue }
    
    public var displayName: String { rawValue }
    
    public var iconName: String {
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

/// App theme options
public enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    public var id: String { rawValue }
    
    public var displayName: String { rawValue }
}

/// Toast notification types
public enum ToastType: String, Identifiable {
    case success = "Success"
    case error = "Error"
    case info = "Info"
    case warning = "Warning"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .success: return "checkmark.circle"
        case .error: return "xmark.circle"
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        }
    }
    
    public var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        case .warning: return .orange
        }
    }
}

/// Planner step enum
public enum PlannerStep: Int, CaseIterable {
    case analyze = 0
    case clarifyQuestions = 1
    case createPlan = 2
    case implementPlan = 3
    
    public var title: String {
        switch self {
        case .analyze:
            return "Analyze"
        case .clarifyQuestions:
            return "Questions"
        case .createPlan:
            return "Plan"
        case .implementPlan:
            return "Implement"
        }
    }
}

// MARK: - Core Structs

/// Prompt version history model
public struct PromptVersion: Identifiable, Codable {
    public let id: UUID
    public var text: String
    public var timestamp: Date
    public var improvedByLLM: Bool
    public var llmModel: String?
    public var notes: String?
    
    public init(id: UUID = UUID(), text: String, timestamp: Date = Date(), improvedByLLM: Bool = false, llmModel: String? = nil, notes: String? = nil) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.improvedByLLM = improvedByLLM
        self.llmModel = llmModel
        self.notes = notes
    }
}

/// Main prompt model
public struct Prompt: Identifiable, Codable {
    public let id: UUID
    public var title: String
    public var text: String
    public var folder: String
    public var type: PromptType
    public var versions: [PromptVersion]
    
    public init(id: UUID = UUID(), title: String, text: String, folder: String, type: PromptType = .general, versions: [PromptVersion] = []) {
        self.id = id
        self.title = title
        self.text = text
        self.folder = folder
        self.type = type
        
        // If no versions are provided, create an initial version with the current text
        if versions.isEmpty {
            self.versions = [PromptVersion(text: text)]
        } else {
            self.versions = versions
        }
    }
}

/// API usage statistics
public struct APIUsageStats: Codable {
    public var totalCalls: Int
    public var totalTokensUsed: Int
    public var callsByModel: [String: Int]
    public var tokensByModel: [String: Int]
    public var lastUpdated: Date
    
    public init(totalCalls: Int = 0, totalTokensUsed: Int = 0, callsByModel: [String: Int] = [:], tokensByModel: [String: Int] = [:], lastUpdated: Date = Date()) {
        self.totalCalls = totalCalls
        self.totalTokensUsed = totalTokensUsed
        self.callsByModel = callsByModel
        self.tokensByModel = tokensByModel
        self.lastUpdated = lastUpdated
    }
    
    public func estimatedCost() -> Double {
        // Calculate estimated cost based on tokens used and model pricing
        // This is a simplified calculation
        var cost: Double = 0.0
        
        for (model, tokens) in tokensByModel {
            if model.contains("gpt-4") {
                // GPT-4 pricing (simplified)
                cost += Double(tokens) * 0.00003
            } else if model.contains("gpt-3.5") {
                // GPT-3.5 pricing (simplified)
                cost += Double(tokens) * 0.000002
            } else if model.contains("claude-3-opus") {
                // Claude 3 Opus pricing (simplified)
                cost += Double(tokens) * 0.00003
            } else if model.contains("claude-3-sonnet") {
                // Claude 3 Sonnet pricing (simplified)
                cost += Double(tokens) * 0.00001
            } else {
                // Default pricing for other models
                cost += Double(tokens) * 0.000005
            }
        }
        
        return cost
    }
}

/// Cache settings
public struct CacheSettings: Codable {
    public var enableCache: Bool
    public var maxCacheSize: Int // in MB
    public var cacheDuration: Int // in days
    
    public init(enableCache: Bool = true, maxCacheSize: Int = 100, cacheDuration: Int = 7) {
        self.enableCache = enableCache
        self.maxCacheSize = maxCacheSize
        self.cacheDuration = cacheDuration
    }
}

/// LLM Request Implementation
public struct LLMRequest: LLMRequestProtocol {
    public let apiKey: String
    public let prompt: String
    public let model: String
    public let useReasoning: Bool
    
    public init(apiKey: String, prompt: String, model: String, useReasoning: Bool = false) {
        self.apiKey = apiKey
        self.prompt = prompt
        self.model = model
        self.useReasoning = useReasoning
    }
    
    public func fetchImprovement() async throws -> String {
        // In a real implementation, this would call an API
        // For now, we'll just simulate an API call
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay (1 second)
        
        // Simulate a successful response
        return "This is a simulated response from the model: \(model)"
    }
}

// MARK: - Core Protocols

/// Protocol for LLM API requests
public protocol LLMRequestProtocol {
    var apiKey: String { get }
    var prompt: String { get }
    var model: String { get }
    var useReasoning: Bool { get }
    
    func fetchImprovement() async throws -> String
}

/// Protocol for API key management
public protocol APIKeyManaging {
    func getAPIKey(service: String) -> String?
    func saveAPIKey(service: String, key: String) -> Bool
    func deleteAPIKey(service: String) -> Bool
}

/// Protocol for prompt management
public protocol PromptManaging: ObservableObject {
    var prompts: [UUID: Prompt] { get set }
    var selectedLLMModel: LLMModel { get set }
    var apiUsageStats: APIUsageStats { get set }
    
    func savePrompt(_ prompt: Prompt) -> Bool
    func deletePrompt(id: UUID) -> Bool
    func saveAPIUsageStats() -> Bool
    
    // API key management methods
    func getAPIKey(service: String) -> String?
    func saveAPIKey(service: String, key: String) -> Bool
    func deleteAPIKey(service: String) -> Bool
}

// MARK: - Core Classes

/// PromptStore class for managing prompts
public class PromptStore: ObservableObject, PromptManaging {
    @Published public var prompts: [UUID: Prompt] = [:]
    @Published public var selectedLLMModel: LLMModel = .gpt4
    @Published public var apiUsageStats: APIUsageStats = APIUsageStats()
    
    public init() {}
    
    public func savePrompt(_ prompt: Prompt) -> Bool {
        prompts[prompt.id] = prompt
        return true
    }
    
    public func deletePrompt(id: UUID) -> Bool {
        prompts.removeValue(forKey: id)
        return true
    }
    
    public func getAPIKey(service: String) -> String? {
        // This would be implemented with actual keychain access
        return nil
    }
    
    public func saveAPIKey(service: String, key: String) -> Bool {
        // This would be implemented with actual keychain access
        return true
    }
    
    public func deleteAPIKey(service: String) -> Bool {
        // This would be implemented with actual keychain access
        return true
    }
    
    public func saveAPIUsageStats() -> Bool {
        // This would be implemented with actual persistence
        return true
    }
    
    // Save a new version of a prompt
    public func savePromptVersion(id: UUID, text: String, improvedByLLM: Bool = false, llmModel: String? = nil, notes: String? = nil) -> Bool {
        guard var prompt = prompts[id] else { return false }
        
        // Create a new version
        let newVersion = PromptVersion(
            text: text,
            timestamp: Date(),
            improvedByLLM: improvedByLLM,
            llmModel: llmModel,
            notes: notes
        )
        
        // Add version to history
        prompt.versions.append(newVersion)
        
        // Update current text
        prompt.text = text
        
        // Save prompt
        prompts[id] = prompt
        
        // Save prompts to persistent storage
        savePrompts()
        
        return true
    }
    
    // Save prompts to persistent storage
    public func savePrompts() -> Bool {
        // This would be implemented with actual persistence
        return true
    }
    
    // Get all folders
    public func folders() -> [String] {
        return Array(Set(prompts.values.map { $0.folder })).sorted()
    }
    
    // Get prompts by type
    public func promptsByType(type: PromptType) -> [Prompt] {
        return prompts.values.filter { $0.type == type }.sorted(by: { $0.title < $1.title })
    }
    
    // Update prompt text
    public func updatePromptText(id: UUID, newText: String) -> Bool {
        guard var prompt = prompts[id] else { return false }
        
        if prompt.text != newText {
            // Add current text as a version first
            let currentVersion = PromptVersion(text: prompt.text)
            prompt.versions.append(currentVersion)
            
            // Update text
            prompt.text = newText
            
            // Save prompt
            prompts[id] = prompt
            savePrompts()
        }
        
        return true
    }
    
    // Add a new prompt
    public func addPrompt(title: String, text: String, folder: String, type: PromptType = .general) -> UUID {
        let prompt = Prompt(
            title: title,
            text: text,
            folder: folder,
            type: type
        )
        
        prompts[prompt.id] = prompt
        savePrompts()
        
        return prompt.id
    }
    
    // Improve a prompt with LLM
    public func improvePromptWithLLM(promptId: UUID, useReasoning: Bool = false, completion: @escaping (Bool, String?) -> Void) {
        // Check if prompt exists
        guard let prompt = prompts[promptId] else {
            completion(false, "Prompt not found")
            return
        }
        
        // Check if API key exists
        guard let apiKey = getAPIKey(service: selectedLLMModel.provider.rawValue) else {
            completion(false, "API key not found")
            return
        }
        
        // Create LLM request
        let request = LLMRequest(
            apiKey: apiKey,
            prompt: prompt.text,
            model: selectedLLMModel.rawValue,
            useReasoning: useReasoning
        )
        
        // Post notification that processing has started
        NotificationCenter.default.post(
            name: NSNotification.Name("LLMProcessingStarted"),
            object: nil
        )
        
        // Execute request asynchronously
        Task {
            do {
                // Fetch improvement from LLM
                let improvedText = try await request.fetchImprovement()
                
                // Update API usage stats
                // This would be more detailed in a real implementation with token counting
                apiUsageStats.totalCalls += 1
                apiUsageStats.totalTokensUsed += 200  // Simplistic approximation
                
                if var modelCalls = apiUsageStats.callsByModel[selectedLLMModel.rawValue] {
                    modelCalls += 1
                    apiUsageStats.callsByModel[selectedLLMModel.rawValue] = modelCalls
                } else {
                    apiUsageStats.callsByModel[selectedLLMModel.rawValue] = 1
                }
                
                if var modelTokens = apiUsageStats.tokensByModel[selectedLLMModel.rawValue] {
                    modelTokens += 200  // Simplistic approximation
                    apiUsageStats.tokensByModel[selectedLLMModel.rawValue] = modelTokens
                } else {
                    apiUsageStats.tokensByModel[selectedLLMModel.rawValue] = 200
                }
                
                apiUsageStats.lastUpdated = Date()
                saveAPIUsageStats()
                
                // Save the improved prompt
                savePromptVersion(
                    id: promptId,
                    text: improvedText,
                    improvedByLLM: true,
                    llmModel: selectedLLMModel.rawValue,
                    notes: useReasoning ? "Improved with reasoning by \(selectedLLMModel.displayName)" : "Improved by \(selectedLLMModel.displayName)"
                )
                
                // Complete with success
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                // Post notification that processing has failed
                NotificationCenter.default.post(
                    name: NSNotification.Name("LLMProcessingFailed"),
                    object: nil,
                    userInfo: ["error": error.localizedDescription]
                )
                
                // Complete with error
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    // Improve a prompt with LLM returning the result
    public func improvePromptWithLLM(promptID: UUID, useReasoning: Bool = false, completion: @escaping (Result<String, Error>) -> Void) {
        // Check if prompt exists
        guard let prompt = prompts[promptID] else {
            let error = NSError(domain: "PromptNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Prompt not found"])
            completion(.failure(error))
            return
        }
        
        // Check if API key exists
        guard let apiKey = getAPIKey(service: selectedLLMModel.provider.rawValue) else {
            let error = NSError(domain: "APIKeyNotFound", code: 403, userInfo: [NSLocalizedDescriptionKey: "API key not found"])
            completion(.failure(error))
            return
        }
        
        // Create LLM request
        let request = LLMRequest(
            apiKey: apiKey,
            prompt: prompt.text,
            model: selectedLLMModel.rawValue,
            useReasoning: useReasoning
        )
        
        // Execute request asynchronously
        Task {
            do {
                // Fetch improvement from LLM
                let improvedText = try await request.fetchImprovement()
                
                // Update API usage stats
                apiUsageStats.totalCalls += 1
                apiUsageStats.totalTokensUsed += 200  // Simplistic approximation
                
                if var modelCalls = apiUsageStats.callsByModel[selectedLLMModel.rawValue] {
                    modelCalls += 1
                    apiUsageStats.callsByModel[selectedLLMModel.rawValue] = modelCalls
                } else {
                    apiUsageStats.callsByModel[selectedLLMModel.rawValue] = 1
                }
                
                if var modelTokens = apiUsageStats.tokensByModel[selectedLLMModel.rawValue] {
                    modelTokens += 200  // Simplistic approximation
                    apiUsageStats.tokensByModel[selectedLLMModel.rawValue] = modelTokens
                } else {
                    apiUsageStats.tokensByModel[selectedLLMModel.rawValue] = 200
                }
                
                apiUsageStats.lastUpdated = Date()
                saveAPIUsageStats()
                
                // Complete with success
                DispatchQueue.main.async {
                    completion(.success(improvedText))
                }
            } catch {
                // Complete with error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Toast notification methods
    public func showToast(message: String, type: ToastType) -> Bool {
        // This would be implemented with actual UI updates
        return true
    }
}

/// Settings view model
public class SettingsViewModel: ObservableObject {
    // Model-related properties
    @Published public var availableProviders: [ModelProvider] = ModelProvider.allCases
    @Published public var availableModels: [LLMModel] = LLMModel.allCases
    
    // API key-related properties
    @Published public var openAIKey: String = ""
    @Published public var anthropicKey: String = ""
    @Published public var googleKey: String = ""
    
    // Settings-related properties
    @Published public var selectedSection: SettingsSection = .general
    
    // Appearance-related properties
    @Published public var selectedTheme: AppTheme = .system
    @Published public var fontScale: Double = 1.0
    
    // Cache-related properties
    @Published public var cacheSettings: CacheSettings = CacheSettings()
    
    // Toast-related properties
    @Published public var showToast: Bool = false
    @Published public var toastMessage: String = ""
    @Published public var toastType: ToastType = .info
    @Published public var toastDuration: Double = 3.0
    
    // Reference to the prompt store
    private var promptStore: PromptManaging
    
    public init(promptStore: PromptManaging) {
        self.promptStore = promptStore
        
        // Load API keys from the store
        if let openAIKey = promptStore.getAPIKey(service: "openai") {
            self.openAIKey = openAIKey
        }
        
        if let anthropicKey = promptStore.getAPIKey(service: "anthropic") {
            self.anthropicKey = anthropicKey
        }
        
        if let googleKey = promptStore.getAPIKey(service: "google") {
            self.googleKey = googleKey
        }
    }
    
    public func saveAPIKey(service: String, key: String) {
        let success = promptStore.saveAPIKey(service: service, key: key)
        
        if success {
            showToast(message: "API key saved successfully", type: .success)
        } else {
            showToast(message: "Failed to save API key", type: .error)
        }
    }
    
    public func deleteAPIKey(service: String) {
        let success = promptStore.deleteAPIKey(service: service)
        
        if success {
            showToast(message: "API key deleted successfully", type: .success)
        } else {
            showToast(message: "Failed to delete API key", type: .error)
        }
    }
    
    public func selectModel(model: LLMModel) {
        promptStore.selectedLLMModel = model
        showToast(message: "Selected model: \(model.displayName)", type: .info)
    }
    
    public func showToast(message: String, type: ToastType, duration: Double = 3.0) {
        self.toastMessage = message
        self.toastType = type
        self.toastDuration = duration
        self.showToast = true
    }
}

// MARK: - Type Aliases

// These type aliases are provided for backward compatibility
// and to make the code more readable in some contexts

public typealias ModelProviderType = ModelProvider
public typealias LLMModelType = LLMModel
public typealias PromptTypeEnum = PromptType
public typealias PromptVersionType = PromptVersion
public typealias PromptModelType = Prompt
public typealias APIUsageStatsType = APIUsageStats
public typealias LLMRequestType = LLMRequest
public typealias LLMRequestProtocolType = LLMRequestProtocol
public typealias APIKeyManagingType = APIKeyManaging
public typealias PromptManagingType = PromptManaging
public typealias SettingsSectionType = SettingsSection
public typealias AppThemeType = AppTheme
public typealias ToastTypeType = ToastType
public typealias CacheSettingsType = CacheSettings
public typealias PromptStoreType = PromptStore 