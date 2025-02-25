import Foundation
import SwiftUI

// This file is used to test that all types are correctly defined
// and accessible in the module

struct TypeTest {
    // Test PromptStore and its dependencies
    private var store: PromptStore = PromptStore()
    
    // Test LLMModel
    private var model: LLMModel = .gpt4
    
    // Test ModelProvider
    private var provider: ModelProvider = .openAI
    
    // Test LLMRequest
    private func testRequest() {
        let request = LLMRequest(
            apiKey: "test-key",
            prompt: "Test prompt",
            model: LLMModel.gpt4.rawValue
        )
        
        // Test the request method
        request.fetchImprovement { result in
            switch result {
            case .success(let response):
                print("Success: \(response)")
            case .failure(let error):
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
    
    // Test function to make sure everything is visible
    func runTest() {
        print("Store: \(store)")
        print("Model: \(model.displayName)")
        print("Provider: \(provider.displayName)")
        print("Prompt: \(prompt.title)")
        
        testRequest()
    }
} 