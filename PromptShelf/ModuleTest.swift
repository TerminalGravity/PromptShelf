import Foundation
import SwiftUI

// This file tests whether the module system is working correctly
// It tries to import the Models module and use types from it

// Import the Models file directly
import Foundation
import SwiftUI
// No need to import PromptShelf.Models as we're in the same module

// Test struct that uses types from the Models module
struct ModuleTest {
    // Try to use types from the Models module
    let provider: ModelProvider = .openAI
    let model: LLMModel = .gpt4
    let toastType: ToastType = .info
    
    // Function to test if we can create instances of types from the Models module
    func testTypes() {
        let prompt = Prompt(id: UUID(), title: "Test", text: "Test prompt", type: .general, tags: [], versions: [])
        print("Created prompt: \(prompt.title)")
    }
} 