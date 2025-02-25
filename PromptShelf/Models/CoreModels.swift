import Foundation

// MARK: - Domain Models

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
    
    public var id: String { rawValue }
}

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

// MARK: - API Usage Statistics

public struct APIUsageStats: Codable {
    public var totalCalls: Int = 0
    public var totalTokensUsed: Int = 0
    public var callsByModel: [String: Int] = [:]
    public var tokensByModel: [String: Int] = [:]
    public var lastUpdated: Date = Date()
    
    public init() {}
    
    // Method to estimate token count from text
    public func estimateTokenCount(text: String) -> Int {
        // Simple estimation: ~4 characters per token for English text
        return max(1, text.count / 4)
    }
    
    // Calculate the estimated cost of API usage
    public func estimatedCost() -> Double {
        var totalCost: Double = 0
        
        for (model, tokens) in tokensByModel {
            let costPer1KTokens: Double
            
            // Set cost based on model
            if model.contains("gpt-4") {
                costPer1KTokens = 0.03 // $0.03 per 1K tokens for GPT-4
            } else if model.contains("gpt-3.5") {
                costPer1KTokens = 0.002 // $0.002 per 1K tokens for GPT-3.5
            } else if model.contains("claude-3-opus") {
                costPer1KTokens = 0.03 // $0.03 per 1K tokens for Claude 3 Opus
            } else if model.contains("claude-3-sonnet") {
                costPer1KTokens = 0.015 // $0.015 per 1K tokens for Claude 3 Sonnet
            } else {
                costPer1KTokens = 0.01 // Default cost
            }
            
            totalCost += Double(tokens) / 1000.0 * costPer1KTokens
        }
        
        return totalCost
    }
}

// MARK: - Service Protocols

/// Protocol for LLM API requests
public protocol LLMRequestProtocol {
    var apiKey: String { get }
    var prompt: String { get }
    var model: String { get }
    var useReasoning: Bool { get }
    
    func fetchImprovement(completion: @escaping (Result<Any, Error>) -> Void)
}

/// Protocol for API key management
public protocol APIKeyManaging {
    func getAPIKey(service: String) -> String?
    func saveAPIKey(service: String, key: String) -> Bool
    func deleteAPIKey(service: String) -> Bool
}

/// Protocol for prompt storage and management
public protocol PromptManaging: APIKeyManaging, ObservableObject {
    var prompts: [UUID: Prompt] { get set }
    var selectedLLMModel: LLMModel { get set }
    var apiUsageStats: APIUsageStats { get set }
    
    func savePrompt(_ prompt: Prompt) -> Bool
    func deletePrompt(id: UUID) -> Bool
    func saveAPIUsageStats() -> Bool
}

// MARK: - LLM Request Implementation

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
    
    public func fetchImprovement(completion: @escaping (Result<Any, Error>) -> Void) {
        // Implementation details would go here depending on the API provider
        // This is a stub that would be replaced with actual implementation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.apiKey.isEmpty || self.apiKey == "invalid" {
                completion(.failure(NSError(domain: "APIError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid API key"])))
            } else {
                completion(.success("API response would go here"))
            }
        }
    }
} 