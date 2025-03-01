import Foundation
import SwiftUI

// This file tests the app's type system
// It uses types defined directly in Models.swift

struct ModuleTest {
    // Use the types directly
    let provider: ModelProvider = .openAI
    let model: LLMModel = .gpt4
    let toastType: ToastType = .info
    
    // Function to test if we can create instances of types
    func testTypes() {
        let prompt = Prompt(
            id: UUID(),
            title: "Test",
            text: "Test prompt",
            type: .general,
            tags: [],
            versions: []
        )
        print("Created prompt: \(prompt.title)")
    }
} 