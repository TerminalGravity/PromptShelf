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
    case o3Mini = "o3-mini"
    case o3 = "o3"
    case whisper = "whisper-1"
    
    // Anthropic Models
    case claude3Opus = "claude-3-opus-20240229"
    case claude3Sonnet = "claude-3-sonnet-20240229"
    case claude3Haiku = "claude-3-haiku-20240307"
    case claude3_7Sonnet = "claude-3-7-sonnet-20250219"
    
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
        case .gpt4, .gpt4Turbo, .gpt4o, .gpt35Turbo, .o1, .o1Mini, .o3Mini, .o3, .whisper:
            return .openAI
        case .claude3Opus, .claude3Sonnet, .claude3Haiku, .claude3_7Sonnet:
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
        case .o3Mini: return "o3-mini"
        case .o3: return "o3"
        case .whisper: return "Whisper"
        case .claude3Opus: return "Claude 3 Opus"
        case .claude3Sonnet: return "Claude 3 Sonnet"
        case .claude3Haiku: return "Claude 3 Haiku"
        case .claude3_7Sonnet: return "Claude 3.7 Sonnet"
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
        case .gpt4, .gpt4Turbo, .gpt4o, .o1, .o3:
            return true
        // Claude 3 Opus and Sonnet have strong reasoning abilities
        case .claude3Opus, .claude3Sonnet, .claude3_7Sonnet:
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

/// API key validation result
public enum APIKeyValidationResult: Equatable {
    case valid
    case invalid(reason: String)
    case expired(until: Date?)
    case malformed(details: String)
    case unknown
    
    public var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    public var message: String {
        switch self {
        case .valid:
            return "API key is valid"
        case .invalid(let reason):
            return "Invalid API key: \(reason)"
        case .expired(let until):
            if let date = until {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "API key expired until \(formatter.string(from: date))"
            }
            return "API key has expired"
        case .malformed(let details):
            return "Malformed API key: \(details)"
        case .unknown:
            return "API key validation failed"
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
    public let maxTokens: Int
    public let temperature: Double
    
    public init(apiKey: String, prompt: String, model: String, useReasoning: Bool = false, maxTokens: Int = 2048, temperature: Double = 0.7) {
        self.apiKey = apiKey
        self.prompt = prompt
        self.model = model
        self.useReasoning = useReasoning
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
    
    public func fetchImprovement() async throws -> String {
        // Determine which provider to use based on the model
        let modelType = LLMModel(rawValue: model) ?? .gpt4
        
        switch modelType.provider {
        case .openAI:
            return try await fetchOpenAIImprovement()
        case .anthropic:
            return try await fetchAnthropicImprovement()
        case .google:
            return try await fetchGoogleImprovement()
        case .deepSeek:
            return try await fetchDeepSeekImprovement()
        case .grok:
            return try await fetchGrokImprovement()
        }
    }
    
    // MARK: - Provider-specific implementations
    
    /// Fetch improvements using OpenAI's API
    private func fetchOpenAIImprovement() async throws -> String {
        let endpoint = "https://api.openai.com/v1/chat/completions"
        
        // Check if we're using an o3 model
        let isO3Model = model.contains("o3")
        
        // Prepare prompt with instructions
        let systemPrompt = useReasoning ? 
            "You are an expert prompt engineer. Improve the given prompt and explain your reasoning in detail." :
            "You are an expert prompt engineer. Improve the given prompt."
        
        let userPrompt = useReasoning ?
            "Please improve the following prompt. First explain your reasoning process in a section titled 'REASONING:', then provide the improved prompt in a section titled 'IMPROVED PROMPT:'\n\n\(prompt)" :
            "Please improve the following prompt. Make it clearer, more specific, and more effective:\n\n\(prompt)"
        
        // Create the base request body
        var requestBody: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "temperature": temperature
        ]
        
        // Special handling for o3 models
        if isO3Model {
            // Use developer role instead of system for o3 models
            let developerMessage = useReasoning ?
                "Analyze the given prompt and provide reasoning followed by an improved version. Format your response with REASONING: and IMPROVED PROMPT: sections." :
                "Analyze the given prompt and provide an improved version."
            
            requestBody["messages"] = [
                ["role": "developer", "content": developerMessage],
                ["role": "user", "content": userPrompt]
            ]
            
            // Add reasoning_effort parameter for o3 models
            requestBody["reasoning_effort"] = "medium"
            
            // Add response_format for structured output
            requestBody["response_format"] = ["type": "json_object"]
        } else {
            // Standard messages format for other models
            requestBody["messages"] = [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ]
        }
        
        // Serialize the request body to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "InvalidRequestError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"])
        }
        
        // Create the URL request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("promptshelf-app/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add timeout
        request.timeoutInterval = 30.0
        
        // Send the request and handle the response
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for HTTP errors
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Successfully received response
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let firstChoice = choices.first else {
                    throw NSError(domain: "ParseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response: missing choices"])
                }
                
                // Check if we're using an o3 model with JSON response format
                if isO3Model {
                    // Handle o3 model JSON response
                    if let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? [String: Any] {
                        // Extract reasoning and improved prompt from JSON content
                        if let reasoning = content["reasoning"] as? String,
                           let improvedPrompt = content["improved_prompt"] as? String {
                            // Format the response to match expected format
                            return "REASONING:\n\(reasoning)\n\nIMPROVED PROMPT:\n\(improvedPrompt)"
                        } else if let contentString = message["content"] as? String {
                            // Fallback if content is a string
                            return contentString
                        }
                    }
                }
                
                // Standard handling for other models
                if let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    return content
                } else if let text = firstChoice["text"] as? String {
                    // Older API version fallback
                    return text
                } else {
                    throw NSError(domain: "ParseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response: unexpected format"])
                }
                
            case 401:
                throw NSError(domain: "AuthenticationError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid API key"])
                
            case 429:
                // Try to parse rate limit details
                var retryAfter: Double = 60.0 // Default retry after 60 seconds
                if let retryHeader = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                   let retrySeconds = Double(retryHeader) {
                    retryAfter = retrySeconds
                }
                
                throw NSError(domain: "RateLimitError", code: 429, userInfo: [
                    NSLocalizedDescriptionKey: "Rate limit exceeded",
                    "retryAfter": retryAfter
                ])
                
            case 400:
                // Try to extract error message from response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw NSError(domain: "InvalidPromptError", code: 400, userInfo: [NSLocalizedDescriptionKey: message])
                } else {
                    throw NSError(domain: "InvalidPromptError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid request"])
                }
                
            case 500, 502, 503, 504:
                throw NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
                
            default:
                throw NSError(domain: "NetworkError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unexpected error"])
            }
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut:
                throw NSError(domain: "TimeoutError", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Request timed out"])
            case .notConnectedToInternet:
                throw NSError(domain: "NetworkError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])
            default:
                throw NSError(domain: "NetworkError", code: urlError.code.rawValue, userInfo: [NSLocalizedDescriptionKey: urlError.localizedDescription])
            }
        }
    }
    
    /// Fetch improvements using Anthropic's API
    private func fetchAnthropicImprovement() async throws -> String {
        let endpoint = "https://api.anthropic.com/v1/messages"
        
        // Check if we're using Claude 3.7 model with extended thinking
        let isClaude37 = model.contains("claude-3-7")
        
        // Prepare system prompt with instructions
        let systemPrompt = useReasoning ?
            "You are an expert prompt engineer. Improve the given prompt and explain your reasoning in detail." :
            "You are an expert prompt engineer. Improve the given prompt."
        
        // Enhanced system prompt for Claude 3.7
        let claude37SystemPrompt = useReasoning ?
            "You are an expert at improving prompts. Analyze the given prompt and suggest improvements that make it clearer, more specific, and more likely to generate high-quality responses. Format your response with REASONING: and IMPROVED PROMPT: sections. Use extended thinking to thoroughly analyze the prompt structure, content, and potential improvements." :
            "You are an expert at improving prompts. Analyze the given prompt and suggest improvements that make it clearer, more specific, and more likely to generate high-quality responses."
        
        let userPrompt = useReasoning ?
            "Please improve the following prompt. First explain your reasoning process in a section titled 'REASONING:', then provide the improved prompt in a section titled 'IMPROVED PROMPT:'\n\n\(prompt)" :
            "Please improve the following prompt. Make it clearer, more specific, and more effective:\n\n\(prompt)"
        
        // Define content blocks
        let userContent: [[String: Any]] = [
            ["type": "text", "text": userPrompt]
        ]
        
        // Create the base request body for Anthropic's API
        var requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": userContent]
            ],
            "max_tokens": maxTokens,
            "temperature": temperature
        ]
        
        // Use the appropriate system prompt based on model
        if isClaude37 {
            requestBody["system"] = claude37SystemPrompt
            
            // Add thinking parameter for Claude 3.7
            requestBody["thinking"] = 1
            
            // Add thinking_budget with a reasonable limit to prevent excessive token usage
            // Default is 128,000 which could be expensive
            requestBody["thinking_budget"] = 32000 // Reduced to 32k tokens for cost control
        } else {
            requestBody["system"] = systemPrompt
        }
        
        // Serialize the request body to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "InvalidRequestError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"])
        }
        
        // Create the URL request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("promptshelf-app", forHTTPHeaderField: "anthropic-client-name")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version") // Updated version header
        request.addValue("promptshelf-app/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add timeout
        request.timeoutInterval = 30.0
        
        // Send the request and handle the response
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for HTTP errors
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            switch httpResponse.statusCode {
            case 200, 201:
                // Successfully received response - try to parse
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw NSError(domain: "ParseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response: invalid JSON"])
                }
                
                // Parse content blocks
                if let content = json["content"] as? [[String: Any]] {
                    var fullText = ""
                    
                    // Concatenate all text blocks
                    for block in content {
                        if let type = block["type"] as? String, type == "text",
                           let text = block["text"] as? String {
                            fullText += text
                        }
                    }
                    
                    if !fullText.isEmpty {
                        // Check if this is Claude 3.7 with thinking tokens
                        if isClaude37 && json["usage"] != nil {
                            // Try to extract thinking tokens for usage tracking
                            if let usage = json["usage"] as? [String: Any],
                               let thinkingTokens = usage["thinking_tokens"] as? Int {
                                // Log thinking tokens usage
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("TokenUsageUpdate"),
                                    object: nil,
                                    userInfo: [
                                        "model": model,
                                        "thinkingTokens": thinkingTokens
                                    ]
                                )
                            }
                        }
                        
                        return fullText
                    }
                }
                
                // Fallback to older response format
                if let messageContent = json["message"] as? [String: Any],
                   let content = messageContent["content"] as? String {
                    return content
                }
                
                throw NSError(domain: "ParseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response: no content found"])
                
            case 401:
                throw NSError(domain: "AuthenticationError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid API key"])
                
            case 429:
                // Try to parse rate limit details
                var retryAfter: Double = 60.0 // Default retry after 60 seconds
                if let retryHeader = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                   let retrySeconds = Double(retryHeader) {
                    retryAfter = retrySeconds
                }
                
                throw NSError(domain: "RateLimitError", code: 429, userInfo: [
                    NSLocalizedDescriptionKey: "Rate limit exceeded",
                    "retryAfter": retryAfter
                ])
                
            case 400:
                // Try to extract error message from response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        throw NSError(domain: "InvalidPromptError", code: 400, userInfo: [NSLocalizedDescriptionKey: message])
                    } else if let message = json["detail"] as? String {
                        // Alternative error format
                        throw NSError(domain: "InvalidPromptError", code: 400, userInfo: [NSLocalizedDescriptionKey: message])
                    }
                }
                throw NSError(domain: "InvalidPromptError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid request"])
                
            case 500, 502, 503, 504:
                throw NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
                
            default:
                throw NSError(domain: "NetworkError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unexpected error"])
            }
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut:
                throw NSError(domain: "TimeoutError", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Request timed out"])
            case .notConnectedToInternet:
                throw NSError(domain: "NetworkError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])
            default:
                throw NSError(domain: "NetworkError", code: urlError.code.rawValue, userInfo: [NSLocalizedDescriptionKey: urlError.localizedDescription])
            }
        }
    }
    
    /// Fetch improvements using Google's API (placeholder)
    private func fetchGoogleImprovement() async throws -> String {
        // Placeholder for Google API implementation
        throw NSError(domain: "UnsupportedModelError", code: 501, userInfo: [
            NSLocalizedDescriptionKey: "Google API support is coming soon. Please use an OpenAI or Anthropic model."
        ])
    }
    
    /// Fetch improvements using DeepSeek's API (placeholder)
    private func fetchDeepSeekImprovement() async throws -> String {
        // Placeholder for DeepSeek API implementation
        throw NSError(domain: "UnsupportedModelError", code: 501, userInfo: [
            NSLocalizedDescriptionKey: "DeepSeek API support is coming soon. Please use an OpenAI or Anthropic model."
        ])
    }
    
    /// Fetch improvements using Grok's API (placeholder)
    private func fetchGrokImprovement() async throws -> String {
        // Placeholder for Grok API implementation
        throw NSError(domain: "UnsupportedModelError", code: 501, userInfo: [
            NSLocalizedDescriptionKey: "Grok API support is coming soon. Please use an OpenAI or Anthropic model."
        ])
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
    func validateAPIKey(service: String, key: String) -> APIKeyValidationResult
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
        return KeychainManager.shared.getAPIKey(service: service)
    }
    
    public func saveAPIKey(service: String, key: String) -> Bool {
        // Validate the key before saving
        let validationResult = validateAPIKey(service: service, key: key)
        if !validationResult.isValid {
            // Log the validation failure but still save if it's just a format warning
            if case .malformed = validationResult {
                // Still save, but this might be a problem later
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowToast"),
                    object: nil,
                    userInfo: ["message": "Warning: \(validationResult.message)", "type": ToastType.warning.rawValue]
                )
                return KeychainManager.shared.saveAPIKey(service: service, key: key)
            } else {
                // Don't save invalid keys
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowToast"),
                    object: nil,
                    userInfo: ["message": validationResult.message, "type": ToastType.error.rawValue]
                )
                return false
            }
        }
        
        return KeychainManager.shared.saveAPIKey(service: service, key: key)
    }
    
    public func deleteAPIKey(service: String) -> Bool {
        return KeychainManager.shared.deleteAPIKey(service: service)
    }
    
    public func validateAPIKey(service: String, key: String) -> APIKeyValidationResult {
        // Check for empty key
        if key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .malformed(details: "Key is empty")
        }
        
        // Trim the key to avoid common issues
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Different validation logic based on the service
        switch service {
        case ModelProvider.openAI.rawValue:
            // OpenAI keys typically start with "sk-" and are 51 characters long
            if !trimmedKey.hasPrefix("sk-") {
                return .malformed(details: "OpenAI API keys should start with 'sk-'")
            }
            if trimmedKey.count < 30 {
                return .malformed(details: "OpenAI API keys should be at least 30 characters")
            }
            
            // Make a minimal validation request to verify the key works
            Task {
                do {
                    let result = try await validateOpenAIKey(key: trimmedKey)
                    // This would update the UI if needed - actual implementation would depend on app architecture
                    NotificationCenter.default.post(
                        name: NSNotification.Name("APIKeyValidated"),
                        object: nil,
                        userInfo: ["service": service, "result": result]
                    )
                } catch {
                    // Handle validation errors
                    NotificationCenter.default.post(
                        name: NSNotification.Name("APIKeyValidated"),
                        object: nil,
                        userInfo: [
                            "service": service, 
                            "result": APIKeyValidationResult.invalid(reason: error.localizedDescription)
                        ]
                    )
                }
            }
            
        case ModelProvider.anthropic.rawValue:
            // Anthropic keys should start with "sk-ant-" and be of sufficient length
            if !trimmedKey.hasPrefix("sk-ant-") {
                return .malformed(details: "Anthropic API keys should start with 'sk-ant-'")
            }
            if trimmedKey.count < 30 {
                return .malformed(details: "Anthropic API keys should be at least 30 characters")
            }
            
            // Make a minimal validation request to verify the key works
            Task {
                do {
                    let result = try await validateAnthropicKey(key: trimmedKey)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("APIKeyValidated"),
                        object: nil,
                        userInfo: ["service": service, "result": result]
                    )
                } catch {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("APIKeyValidated"),
                        object: nil,
                        userInfo: [
                            "service": service, 
                            "result": APIKeyValidationResult.invalid(reason: error.localizedDescription)
                        ]
                    )
                }
            }
            
        case ModelProvider.google.rawValue:
            // Google API keys are typically 39 characters
            if trimmedKey.count < 20 {
                return .malformed(details: "Google API keys should be at least 20 characters")
            }
            
        case ModelProvider.deepSeek.rawValue, ModelProvider.grok.rawValue:
            // Basic length check for other providers
            if trimmedKey.count < 10 {
                return .malformed(details: "API key appears too short")
            }
            
        default:
            // General validation for unknown providers
            if trimmedKey.count < 10 {
                return .malformed(details: "API key appears too short")
            }
        }
        
        // Check for common issues
        if trimmedKey.contains(" ") {
            return .malformed(details: "API key contains spaces")
        }
        
        // Key passed basic validation
        return .valid
    }
    
    /// Validates an OpenAI API key by making a minimal API call
    private func validateOpenAIKey(key: String) async throws -> APIKeyValidationResult {
        let endpoint = "https://api.openai.com/v1/models"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10.0 // Short timeout for validation
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .unknown
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Successfully validated
                return .valid
                
            case 401:
                // Invalid API key
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    return .invalid(reason: message)
                }
                return .invalid(reason: "Authentication failed")
                
            case 429:
                // Rate limited - this actually means the key is valid but rate limited
                if let retryHeader = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                   let retrySeconds = Double(retryHeader),
                   let retryDate = Calendar.current.date(byAdding: .second, value: Int(retrySeconds), to: Date()) {
                    return .expired(until: retryDate)
                }
                return .expired(until: nil)
                
            default:
                // Other error
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    return .invalid(reason: message)
                }
                return .invalid(reason: "Validation failed with code \(httpResponse.statusCode)")
            }
        } catch {
            return .invalid(reason: "Network error: \(error.localizedDescription)")
        }
    }
    
    /// Validates an Anthropic API key by making a minimal API call
    private func validateAnthropicKey(key: String) async throws -> APIKeyValidationResult {
        let endpoint = "https://api.anthropic.com/v1/models"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.addValue(key, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 10.0 // Short timeout for validation
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .unknown
            }
            
            switch httpResponse.statusCode {
            case 200, 201:
                // Successfully validated
                return .valid
                
            case 401:
                // Invalid API key
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        return .invalid(reason: message)
                    } else if let type = json["type"] as? String, type == "auth_error" {
                        return .invalid(reason: "Authentication failed")
                    }
                }
                return .invalid(reason: "Authentication failed")
                
            case 429:
                // Rate limited - this actually means the key is valid but rate limited
                if let retryHeader = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                   let retrySeconds = Double(retryHeader),
                   let retryDate = Calendar.current.date(byAdding: .second, value: Int(retrySeconds), to: Date()) {
                    return .expired(until: retryDate)
                }
                return .expired(until: nil)
                
            default:
                // Other error
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        return .invalid(reason: message)
                    } else if let detail = json["detail"] as? String {
                        return .invalid(reason: detail)
                    }
                }
                return .invalid(reason: "Validation failed with code \(httpResponse.statusCode)")
            }
        } catch {
            return .invalid(reason: "Network error: \(error.localizedDescription)")
        }
    }
    
    /// Check if API key is configured and valid for the given provider
    public func isProviderConfigured(_ provider: ModelProvider) -> Bool {
        guard let key = getAPIKey(service: provider.rawValue) else {
            return false
        }
        
        // Perform basic validation
        let result = validateAPIKey(service: provider.rawValue, key: key)
        return result.isValid
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
        
        // Execute request asynchronously with retry logic
        Task {
            let maxRetries = 3
            var currentRetry = 0
            
            while currentRetry <= maxRetries {
                do {
                    if currentRetry > 0 {
                        // Add exponential backoff
                        let backoffTime = Double(1 << currentRetry) * 0.5 // 1, 2, 4 seconds
                        try await Task.sleep(nanoseconds: UInt64(backoffTime * 1_000_000_000))
                        
                        // Notify about retry
                        NotificationCenter.default.post(
                            name: NSNotification.Name("LLMProcessingRetry"),
                            object: nil,
                            userInfo: ["attempt": currentRetry, "maxRetries": maxRetries]
                        )
                    }
                    
                    // Fetch improvement from LLM
                    let improvedText = try await request.fetchImprovement()
                    
                    // Update API usage stats with more accurate approximation
                    // Calculate approximate token count based on text length (4 chars ≈ 1 token)
                    let inputTokens = Int(Double(prompt.text.count) / 4.0)
                    let outputTokens = Int(Double(improvedText.count) / 4.0)
                    let totalTokens = inputTokens + outputTokens
                    
                    apiUsageStats.totalCalls += 1
                    apiUsageStats.totalTokensUsed += totalTokens
                    
                    if var modelCalls = apiUsageStats.callsByModel[selectedLLMModel.rawValue] {
                        modelCalls += 1
                        apiUsageStats.callsByModel[selectedLLMModel.rawValue] = modelCalls
                    } else {
                        apiUsageStats.callsByModel[selectedLLMModel.rawValue] = 1
                    }
                    
                    if var modelTokens = apiUsageStats.tokensByModel[selectedLLMModel.rawValue] {
                        modelTokens += totalTokens
                        apiUsageStats.tokensByModel[selectedLLMModel.rawValue] = modelTokens
                    } else {
                        apiUsageStats.tokensByModel[selectedLLMModel.rawValue] = totalTokens
                    }
                    
                    apiUsageStats.lastUpdated = Date()
                    saveAPIUsageStats()
                    
                    // Complete with success
                    DispatchQueue.main.async {
                        completion(.success(improvedText))
                    }
                    
                    // Successful completion, break out of retry loop
                    break
                    
                } catch let error as NSError {
                    // Check if we should retry based on error type
                    let shouldRetry = shouldRetryRequest(error: error, currentAttempt: currentRetry, maxRetries: maxRetries)
                    
                    if shouldRetry {
                        currentRetry += 1
                        continue
                    } else {
                        // Complete with error if this is a non-retryable error or we've exhausted retries
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        break
                    }
                } catch {
                    // Complete with unexpected error
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    break
                }
            }
        }
    }
    
    /// Determines if a request should be retried based on the error and attempt count
    private func shouldRetryRequest(error: NSError, currentAttempt: Int, maxRetries: Int) -> Bool {
        // If we've reached max retries, don't retry further
        if currentAttempt >= maxRetries {
            return false
        }
        
        // Determine if error is retriable based on error domain and code
        switch error.domain {
        case "TimeoutError", "NetworkError":
            // Network-related errors are usually temporary and can be retried
            return true
            
        case "RateLimitError":
            // Rate limit errors should be retried with backoff
            // Check if the error has a retry-after information
            if let retryAfter = error.userInfo["retryAfter"] as? Double {
                // If retry delay is too long, inform the caller rather than waiting
                if retryAfter > 10.0 {
                    return false
                }
                return true
            }
            return true
            
        case "ServerError":
            // Server errors (5xx) can usually be retried
            return true
            
        case "AuthenticationError", "APIKeyNotFound", "InvalidPromptError":
            // Auth errors or invalid requests should not be retried
            return false
            
        default:
            // For unknown error types, don't retry
            return false
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

// MARK: - KeychainManager

/// Singleton class to manage API keys in the keychain
public class KeychainManager {
    public static let shared = KeychainManager()
    
    private let serviceName = "com.promptshelf.apikeys"
    
    private init() {}
    
    /// Get an API key from the keychain
    public func getAPIKey(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, 
              let data = item as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    /// Save an API key to the keychain
    public func saveAPIKey(service: String, key: String) -> Bool {
        // Delete existing key if it exists
        deleteAPIKey(service: service)
        
        guard let data = key.data(using: .utf8) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: service,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Delete an API key from the keychain
    public func deleteAPIKey(service: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
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