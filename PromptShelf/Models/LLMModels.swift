import Foundation
import SwiftUI

// This file contains LLM-specific extensions 
// Core LLM types are defined in Types.swift

// Extension to LLMModel to add the o3 and Claude 3.7 capabilities
extension LLMModel {
    // Indicates if the model supports the reasoning effort parameter (o3 models)
    public var supportsReasoningEffort: Bool {
        return self == .o3 || self == .o3Mini
    }
    
    // Indicates if the model supports extended thinking (Claude 3.7)
    public var supportsExtendedThinking: Bool {
        return self == .claude3_7Sonnet
    }
    
    // Default reasoning effort for o3 models
    public var defaultReasoningEffort: String {
        switch self {
        case .o3Mini: return "medium"
        case .o3: return "high"
        default: return "medium"
        }
    }
    
    // Default thinking budget for Claude 3.7
    public var defaultThinkingBudget: Int {
        return self == .claude3_7Sonnet ? 32000 : 0
    }
}

// ReasoningEffort enum for o3 models (simplified version)
public enum ReasoningEffort: String, CaseIterable {
    case low, medium, high
} 