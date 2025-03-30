import Foundation
import SwiftUI
import Combine

// MARK: - Core Model Definitions
// Simple definitions of the core types needed by the app

// Model Provider
public enum ModelProvider: String, CaseIterable, Identifiable, Codable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case google = "Google"
    
    public var id: String { rawValue }
    
    public var displayName: String { rawValue }
    
    // Models associated with this provider
    public var models: [LLMModel] {
        LLMModel.allCases.filter { $0.provider == self }
    }
}

// LLM Model
public enum LLMModel: String, CaseIterable, Identifiable, Codable {
    // OpenAI models
    case gpt4 = "gpt-4"
    case gpt4Turbo = "gpt-4-turbo"
    case gpt35Turbo = "gpt-3.5-turbo"
    
    // Anthropic models
    case claude3Opus = "claude-3-opus"
    case claude3Sonnet = "claude-3-sonnet"
    
    // Google models
    case geminiPro = "gemini-pro"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .gpt4: return "GPT-4"
        case .gpt4Turbo: return "GPT-4 Turbo"
        case .gpt35Turbo: return "GPT-3.5 Turbo"
        case .claude3Opus: return "Claude 3 Opus"
        case .claude3Sonnet: return "Claude 3 Sonnet"
        case .geminiPro: return "Gemini Pro"
        }
    }
    
    public var provider: ModelProvider {
        switch self {
        case .gpt4, .gpt4Turbo, .gpt35Turbo:
            return .openAI
        case .claude3Opus, .claude3Sonnet:
            return .anthropic
        case .geminiPro:
            return .google
        }
    }
    
    public var hasReasoningCapability: Bool {
        switch self {
        case .gpt4, .gpt4Turbo, .claude3Opus, .claude3Sonnet:
            return true
        default:
            return false
        }
    }
}

// LLM Request
public struct LLMRequest {
    public let prompt: String
    public let model: LLMModel
    public let useReasoning: Bool
    
    public init(prompt: String, model: LLMModel, useReasoning: Bool = false) {
        self.prompt = prompt
        self.model = model
        self.useReasoning = useReasoning
    }
    
    // Extension method for fetching improvements
    public func fetchImprovement(completion: @escaping (Result<String, Error>) -> Void) {
        // Simplified implementation for the example
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Simulating a successful response
            completion(.success("Improved text based on LLM model \(self.model.displayName)"))
            
            // Uncomment to test error handling
            // let error = NSError(domain: "LLMError", code: 500, userInfo: [NSLocalizedDescriptionKey: "API error"])
            // completion(.failure(error))
        }
    }
}

// Toast Type
public enum ToastType: String, Identifiable, Codable {
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

// Prompt Type
public enum PromptType: String, CaseIterable, Identifiable, Codable {
    case general = "General"
    case chatbot = "Chatbot"
    case creative = "Creative"
    case technical = "Technical"
    case cursorFix = "Cursor Fix"
    case plannerMode = "Planner Mode"
    
    public var id: String { rawValue }
}

// Prompt Version
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

// Prompt
public struct Prompt: Identifiable, Codable {
    public let id: UUID
    public var title: String
    public var text: String
    public var type: PromptType
    public var tags: [String]
    public var versions: [PromptVersion]
    public var folder: String?
    
    public init(id: UUID = UUID(), title: String, text: String, type: PromptType = .general, tags: [String] = [], versions: [PromptVersion] = [], folder: String? = nil) {
        self.id = id
        self.title = title
        self.text = text
        self.type = type
        self.tags = tags
        self.folder = folder
        
        // If no versions are provided, create an initial version with the current text
        if versions.isEmpty {
            self.versions = [PromptVersion(text: text)]
        } else {
            self.versions = versions
        }
    }
}

// API Usage Stats
public struct APIUsageStats: Codable {
    public var totalRequests: Int
    public var tokenCount: Int
    public var lastResetDate: Date
    
    public init(totalRequests: Int = 0, tokenCount: Int = 0, lastResetDate: Date = Date()) {
        self.totalRequests = totalRequests
        self.tokenCount = tokenCount
        self.lastResetDate = lastResetDate
    }
}

// Planner Step enum for PromptPlannerView
public enum PlannerStep: String, CaseIterable, Identifiable {
    case analyze = "Analyze"
    case clarifyQuestions = "Questions"
    case createPlan = "Plan"
    case implementPlan = "Improve"
    
    public var id: String { rawValue }
    
    public var title: String { rawValue }
}

// Toast View
public struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool
    
    public var body: some View {
        if isShowing {
            VStack {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: type.iconName)
                        .foregroundColor(type.color)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isShowing = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.windowBackgroundColor))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
}

// PromptStore (simplified version)
public class PromptStore: ObservableObject {
    @Published public var prompts: [UUID: Prompt] = [:]
    @Published public var selectedLLMModel: LLMModel = .gpt4
    @Published public var apiUsageStats: APIUsageStats = APIUsageStats()
    
    public init() {
        // Initialize with empty state
    }
    
    public func isProviderConfigured(_ provider: ModelProvider) -> Bool {
        // Simplified implementation
        return true
    }
    
    public func savePromptVersion(id: UUID, text: String, improvedByLLM: Bool = false, llmModel: String? = nil, notes: String? = nil) -> Bool {
        // Simplified implementation
        return true
    }
    
    public func improvePromptWithLLM(promptID: UUID, useReasoning: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        // Simplified implementation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success("Improved prompt text"))
        }
    }
    
    public func folders() -> [String] {
        // Return all unique folders and ensure "General" is always included
        var allFolders = Set(prompts.values.compactMap { $0.folder })
        allFolders.insert("General") // Always include General folder
        return Array(allFolders).sorted()
    }
    
    public func savePrompts() -> Bool {
        // Simplified implementation
        return true
    }
    
    public func updatePrompt(id: UUID, newPrompt: Prompt) -> Bool {
        prompts[id] = newPrompt
        return savePrompts()
    }
    
    public func addPrompt(title: String, text: String, folder: String, type: PromptType) {
        let newPrompt = Prompt(
            title: title,
            text: text,
            type: type,
            folder: folder
        )
        prompts[newPrompt.id] = newPrompt
        savePrompts()
    }
    
    public func getAPIKey(service: String) -> String? {
        // Simplified implementation - in a real app this would securely retrieve from keychain
        // For now just return a mock key for testing
        return "mock_api_key_for_\(service)"
    }
}

// Re-export Foundation types used throughout the app
@_exported import struct Foundation.UUID
@_exported import struct Foundation.Date
@_exported import class Foundation.NSObject
@_exported import class Foundation.JSONEncoder
@_exported import class Foundation.JSONDecoder 