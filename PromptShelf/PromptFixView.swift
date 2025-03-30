import SwiftUI

struct PromptFixView: View {
    @ObservedObject var store: PromptStore
    let promptID: UUID
    @Binding var isShowing: Bool
    
    @State private var isLoading = false
    @State private var fixedText = ""
    @State private var errorMessage: String? = nil
    @State private var currentStep = FixStep.identifyIssues
    @State private var possibleIssues = [
        FixIssue(id: 1, text: "Too vague or ambiguous", selected: false),
        FixIssue(id: 2, text: "Missing context or background", selected: false),
        FixIssue(id: 3, text: "Unclear expectations or deliverables", selected: false),
        FixIssue(id: 4, text: "Lacking specific examples", selected: false),
        FixIssue(id: 5, text: "Conflicting or contradictory instructions", selected: false),
        FixIssue(id: 6, text: "Too verbose or redundant", selected: false),
        FixIssue(id: 7, text: "Incorrect formatting or structure", selected: false)
    ]
    @State private var userNotes = ""
    @State private var validationResults = ""
    
    private var prompt: Prompt? {
        store.prompts[promptID]
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                Text("Cursor Fix Workflow")
                    .font(.title2.bold())
                    .foregroundColor(.green)
                
                Spacer()
                
                Button("Close") {
                    isShowing = false
                }
                .buttonStyle(.bordered)
            }
            
            // Progress indicator
            StepProgressView(currentStep: currentStep)
                .padding(.vertical)
            
            // Original prompt (always visible)
            VStack(alignment: .leading) {
                Text("Original Prompt")
                    .font(.headline)
                
                ScrollView {
                    Text(prompt?.text ?? "")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(height: 100)
            }
            
            // Current step content
            Group {
                switch currentStep {
                case .identifyIssues:
                    identifyIssuesView
                case .narrowDown:
                    narrowDownView
                case .validatePrompt:
                    validatePromptView
                case .implementFix:
                    implementFixView
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            // Navigation buttons
            HStack {
                if currentStep != .identifyIssues {
                    Button("Back") {
                        moveBack()
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                Button(nextButtonText) {
                    moveNext()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canMoveNext)
            }
        }
        .padding()
        .frame(width: 700, height: 600)
    }
    
    // MARK: - Step Views
    
    private var identifyIssuesView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step 1: Identify Possible Issues")
                .font(.headline)
            
            Text("Select all potential issues with this prompt:")
                .font(.subheadline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(0..<possibleIssues.count, id: \.self) { index in
                        Toggle(isOn: $possibleIssues[index].selected) {
                            Text(possibleIssues[index].text)
                                .font(.body)
                        }
                        .toggleStyle(.checkbox)
                    }
                }
                .padding()
            }
            .frame(height: 180)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var narrowDownView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step 2: Narrow Down the Issues")
                .font(.headline)
            
            Text("From your selected issues, identify the most critical ones (1-2 issues):")
                .font(.subheadline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(possibleIssues.indices.filter { possibleIssues[$0].selected }, id: \.self) { index in
                        Toggle(isOn: $possibleIssues[index].critical) {
                            Text(possibleIssues[index].text)
                                .font(.body)
                        }
                        .toggleStyle(.checkbox)
                    }
                }
                .padding()
            }
            .frame(height: 120)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            Text("Additional notes about the issues:")
                .font(.subheadline)
            
            TextEditor(text: $userNotes)
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
        }
    }
    
    private var validatePromptView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step 3: Validate the Prompt")
                .font(.headline)
            
            Text("Test how different LLMs respond to this prompt to identify issues:")
                .font(.subheadline)
            
            HStack {
                Picker("Test With:", selection: $store.selectedLLMModel) {
                    ForEach(LLMModel.allCases, id: \.self) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 250)
                
                Spacer()
                
                Button(action: validateWithLLM) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        } else {
                            Text("Run Test")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || prompt == nil || store.getAPIKey(service: store.selectedLLMModel.rawValue) == nil)
            }
            
            if !validationResults.isEmpty {
                Text("Test Results:")
                    .font(.subheadline)
                
                ScrollView {
                    Text(validationResults)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                }
                .frame(height: 120)
            }
        }
    }
    
    private var implementFixView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step 4: Implement the Fix")
                .font(.headline)
            
            if fixedText.isEmpty {
                VStack {
                    Button(action: generateFixWithLLM) {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                            } else {
                                Text("Generate Fix with LLM")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || prompt == nil || store.getAPIKey(service: store.selectedLLMModel.rawValue) == nil)
                    
                    Text("Or manually enter your fixed prompt below")
                        .font(.caption)
                        .padding(.top, 4)
                }
                
                TextEditor(text: $fixedText)
                    .frame(height: 180)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
            } else {
                Text("Fixed Prompt:")
                    .font(.subheadline)
                
                ScrollView {
                    Text(fixedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(8)
                }
                .frame(height: 180)
                
                HStack {
                    Spacer()
                    
                    Button("Apply Fix") {
                        applyFix()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private var nextButtonText: String {
        switch currentStep {
        case .identifyIssues:
            return "Next: Narrow Down"
        case .narrowDown:
            return "Next: Validate"
        case .validatePrompt:
            return "Next: Implement Fix"
        case .implementFix:
            return "Finish"
        }
    }
    
    private var canMoveNext: Bool {
        switch currentStep {
        case .identifyIssues:
            return possibleIssues.contains(where: { $0.selected })
        case .narrowDown:
            return possibleIssues.contains(where: { $0.selected && $0.critical })
        case .validatePrompt:
            return true
        case .implementFix:
            return !fixedText.isEmpty
        }
    }
    
    private func moveNext() {
        switch currentStep {
        case .identifyIssues:
            currentStep = .narrowDown
        case .narrowDown:
            currentStep = .validatePrompt
        case .validatePrompt:
            currentStep = .implementFix
        case .implementFix:
            applyFix()
            isShowing = false
        }
    }
    
    private func moveBack() {
        switch currentStep {
        case .narrowDown:
            currentStep = .identifyIssues
        case .validatePrompt:
            currentStep = .narrowDown
        case .implementFix:
            currentStep = .validatePrompt
        default:
            break
        }
    }
    
    private func validateWithLLM() {
        guard let promptText = prompt?.text else { return }
        errorMessage = nil
        isLoading = true
        
        // Create a validation prompt
        let validationPrompt = """
        I need you to analyze this prompt and tell me if it has any issues or problems:
        
        PROMPT:
        \(promptText)
        
        Issues to check for:
        \(possibleIssues.filter { $0.selected && $0.critical }.map { "- " + $0.text }.joined(separator: "\n"))
        
        Additional notes:
        \(userNotes)
        
        Please provide a brief analysis and suggestions for improvement.
        """
        
        // Call the LLM with the validation prompt
        let llmRequest = LLMRequest(
            prompt: validationPrompt,
            model: store.selectedLLMModel,
            useReasoning: false
        )
        
        llmRequest.fetchImprovement { result in
            isLoading = false
            
            switch result {
            case .success(let response):
                validationResults = response
            case .failure(let error):
                errorMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    private func generateFixWithLLM() {
        guard let promptText = prompt?.text else { return }
        errorMessage = nil
        isLoading = true
        
        // Collect the critical issues
        let criticalIssuesList = possibleIssues
            .filter { $0.selected && $0.critical }
            .map { "- " + $0.text }
            .joined(separator: "\n")
        
        // Create a fix generation prompt
        let fixPrompt = """
        I need you to rewrite and fix the following prompt.
        
        ORIGINAL PROMPT:
        \(promptText)
        
        ISSUES TO FIX:
        \(criticalIssuesList)
        
        VALIDATION RESULTS:
        \(validationResults)
        
        USER NOTES:
        \(userNotes)
        
        Please provide ONLY the fixed prompt text, with no additional explanations.
        """
        
        // Call the LLM with the fix prompt
        let llmRequest = LLMRequest(
            prompt: fixPrompt,
            model: store.selectedLLMModel,
            useReasoning: false
        )
        
        llmRequest.fetchImprovement { result in
            isLoading = false
            
            switch result {
            case .success(let response):
                fixedText = response
            case .failure(let error):
                errorMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    private func applyFix() {
        guard !fixedText.isEmpty, let promptID = prompt?.id else { return }
        
        // Create notes about what issues were fixed
        let issuesList = possibleIssues
            .filter { $0.selected && $0.critical }
            .map { "- " + $0.text }
            .joined(separator: "\n")
        
        let notes = """
        Fixed using Cursor Fix workflow.
        
        Issues addressed:
        \(issuesList)
        
        User notes:
        \(userNotes)
        """
        
        _ = store.savePromptVersion(
            id: promptID, 
            text: fixedText,
            improvedByLLM: true,
            llmModel: store.selectedLLMModel.rawValue,  // This method expects a String
            notes: notes
        )
        
        isShowing = false
    }
}

// MARK: - Helper Structs

struct FixIssue {
    var id: Int
    var text: String
    var selected: Bool
    var critical: Bool = false
}

enum FixStep: Int, CaseIterable {
    case identifyIssues = 0
    case narrowDown = 1
    case validatePrompt = 2
    case implementFix = 3
}

struct StepProgressView: View {
    let currentStep: FixStep
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(FixStep.allCases, id: \.self) { step in
                VStack {
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Group {
                                if step.rawValue < currentStep.rawValue {
                                    Image(systemName: "checkmark").foregroundColor(.white).font(.caption)
                                } else {
                                    Text("\(step.rawValue + 1)").foregroundColor(.white).font(.caption)
                                }
                            }
                        )
                    
                    Text(step.title)
                        .font(.caption)
                        .foregroundColor(step == currentStep ? .primary : .secondary)
                }
                
                if step != FixStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? Color.green : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

extension FixStep {
    var title: String {
        switch self {
        case .identifyIssues:
            return "Identify"
        case .narrowDown:
            return "Narrow Down"
        case .validatePrompt:
            return "Validate"
        case .implementFix:
            return "Implement"
        }
    }
} 