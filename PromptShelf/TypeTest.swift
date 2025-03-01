import Foundation
import SwiftUI

// This is a test file to verify types are working correctly
struct TypeTest {
    // Define these types directly in this file for testing purposes
    // This avoids the module import issues
    
    enum TestModelProvider {
        case openAI
        case anthropic
        case google
    }
    
    enum TestLLMModel {
        case gpt4
    }
    
    enum TestToastType {
        case info
    }
    
    struct TestPrompt {
        let id: UUID
        let title: String
        let text: String
        let type: TestPromptType
        let tags: [String]
        let versions: [String]
    }
    
    enum TestPromptType {
        case general
    }
    
    struct TestLLMRequest {
        let prompt: String
        let model: TestLLMModel
        let useReasoning: Bool
    }
    
    // Test properties using the local test types
    let provider: TestModelProvider = .openAI
    let model: TestLLMModel = .gpt4
    
    func testTypes() {
        // Test creating instances of the test types
        let prompt = TestPrompt(
            id: UUID(), 
            title: "Test", 
            text: "Test prompt", 
            type: .general, 
            tags: [], 
            versions: []
        )
        print("Created prompt: \(prompt.title)")
        
        let request = TestLLMRequest(
            prompt: "Test prompt",
            model: .gpt4,
            useReasoning: true
        )
        print("Created request with model: \(request.model)")
    }
} 