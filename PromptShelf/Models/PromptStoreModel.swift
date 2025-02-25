import Foundation
import SwiftUI
import Combine

// This is a stub for the PromptStore class with just the needed APIs for the Settings view
class PromptStore: ObservableObject {
    struct APIUsageStats: Codable {
        var totalCalls: Int = 0
        var totalTokensUsed: Int = 0
        var callsByModel: [String: Int] = [:]
        var tokensByModel: [String: Int] = [:]
        var lastUpdated: Date = Date()
        
        func estimatedCost() -> Double { return 0.0 }
    }
    
    @Published var prompts: [UUID: Prompt] = [:]
    @Published var selectedLLMModel: LLMModel = .gpt4
    @Published var apiUsageStats: APIUsageStats = APIUsageStats()
    
    func getAPIKey(service: String) -> String? { return nil }
    func saveAPIKey(service: String, key: String) -> Bool { return true }
    func deleteAPIKey(service: String) -> Bool { return true }
} 