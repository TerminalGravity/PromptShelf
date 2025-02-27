import Foundation
import SwiftUI

// This file is used to test that all types are correctly defined
// and accessible in the module

public struct TypeTest {
    // Test PromptStore and its dependencies
    @ObservedObject private var store: PromptStore = PromptStore()
    
    // Test LLMModel
    private var model: LLMModel = .gpt4
    
    // Test ModelProvider
    private var provider: ModelProvider = .openAI
    
    // Test LLMRequest
    private func testRequest() {
        Task {
            do {
                let request = LLMRequest(
                    apiKey: "test-key",
                    prompt: "Test prompt",
                    model: LLMModel.gpt4.rawValue
                )
                let response = try await request.fetchImprovement()
                print("Success: \(response)")
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    // Test Prompt and PromptVersion
    private var prompt: Prompt = Prompt(
        title: "Test Prompt",
        text: "This is a test prompt",
        folder: "Tests",
        type: .general
    )
    
    public init() {}
    
    // Test function to make sure everything is visible
    public func runTest() {
        print("Store: \(store)")
        print("Model: \(model.displayName)")
        print("Provider: \(provider.displayName)")
        print("Prompt: \(prompt.title)")
        
        testRequest()
    }
} 