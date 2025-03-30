import SwiftUI

struct PromptPlannerView: View {
    @ObservedObject var store: PromptStore
    let promptID: UUID
    @Binding var isShowing: Bool
    
    @State private var isLoading = false
    @State private var improvedText = ""
    @State private var errorMessage: String? = nil
    @State private var currentStep = PlannerStep.analyze
    
    // Analysis step
    @State private var promptGoal = ""
    @State private var promptStrengths = ""
    @State private var promptWeaknesses = ""
    
    // Questions step
    @State private var clarifyingQuestions = [
        PlannerQuestion(id: 1, text: "Who is the target audience for this prompt?", answer: ""),
        PlannerQuestion(id: 2, text: "What specific output format is expected?", answer: ""),
        PlannerQuestion(id: 3, text: "What context or background information is missing?", answer: ""),
        PlannerQuestion(id: 4, text: "What constraints or limitations should be considered?", answer: "")
    ]
    @State private var customQuestion = ""
    
    // Planning step
    @State private var planSteps = [
        PlannerStepItem(id: 1, text: "", complete: false)
    ]
    @State private var planNotes = ""
    
    // Implementation step
    @State private var showDiff = false
    
    private var prompt: Prompt? {
        store.prompts[promptID]
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                Text("Planner Mode Workflow")
                    .font(.title2.bold())
                    .foregroundColor(.purple)
                
                Spacer()
                
                Button("Close") {
                    isShowing = false
                }
                .buttonStyle(.bordered)
            }
            
            // Progress indicator
            StepProgressViewPlanner(currentStep: currentStep)
                .padding(.vertical)
            
            // Step content
            Group {
                switch currentStep {
                case .analyze:
                    analyzeView
                case .clarifyQuestions:
                    questionsView
                case .createPlan:
                    planningView
                case .implementPlan:
                    implementationView
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
                if currentStep != .analyze {
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
        .onAppear {
            // Pre-fill the prompt goal if empty
            if promptGoal.isEmpty, let _ = prompt?.text {
                promptGoal = "Improve the clarity and effectiveness of this prompt"
            }
        }
    }
    
    // MARK: - Step Views
    
    private var analyzeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step 1: Analyze Current Prompt")
                .font(.headline)
            
            // Original prompt
            VStack(alignment: .leading) {
                Text("Original Prompt:")
                    .font(.subheadline)
                
                ScrollView {
                    Text(prompt?.text ?? "")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(height: 100)
            }
            
            // Goal
            VStack(alignment: .leading) {
                Text("What's the goal of this prompt?")
                    .font(.subheadline)
                
                TextEditor(text: $promptGoal)
                    .frame(height: 60)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
            }
            
            HStack(spacing: 15) {
                // Strengths
                VStack(alignment: .leading) {
                    Text("Strengths:")
                        .font(.subheadline)
                    
                    TextEditor(text: $promptStrengths)
                        .frame(height: 80)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
                }
                
                // Weaknesses
                VStack(alignment: .leading) {
                    Text("Areas for Improvement:")
                        .font(.subheadline)
                    
                    TextEditor(text: $promptWeaknesses)
                        .frame(height: 80)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
                }
            }
            
            // Auto-analyze button
            HStack {
                Spacer()
                
                Button(action: analyzeWithLLM) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Text("Auto-Analyze with LLM")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || prompt == nil || store.getAPIKey(service: store.selectedLLMModel.rawValue) == nil)
            }
        }
    }
    
    private var questionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step 2: Clarifying Questions")
                .font(.headline)
            
            Text("Answer these questions to guide your prompt improvement:")
                .font(.subheadline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(0..<clarifyingQuestions.count, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(clarifyingQuestions[index].text)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            TextField("Answer", text: $clarifyingQuestions[index].answer)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .padding()
            }
            .frame(height: 220)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            // Add custom question
            HStack {
                TextField("Add a custom question...", text: $customQuestion)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: addCustomQuestion) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .disabled(customQuestion.isEmpty)
            }
        }
    }
    
    private var planningView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step 3: Create Improvement Plan")
                .font(.headline)
            
            Text("Define the steps to improve this prompt:")
                .font(.subheadline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(0..<planSteps.count, id: \.self) { index in
                        HStack {
                            Text("\(index + 1).")
                                .font(.body.bold())
                                .frame(width: 25, alignment: .leading)
                            
                            TextField("Step description", text: $planSteps[index].text)
                                .textFieldStyle(.roundedBorder)
                            
                            Button(action: {
                                withAnimation {
                                    if planSteps.count > 1 {
                                        planSteps.remove(at: index)
                                    }
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                            .opacity(planSteps.count > 1 ? 1.0 : 0.0)
                        }
                    }
                    
                    Button(action: addPlanStep) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Step")
                        }
                    }
                    .padding(.top, 5)
                }
                .padding()
            }
            .frame(height: 150)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            Text("Additional Notes:")
                .font(.subheadline)
            
            TextEditor(text: $planNotes)
                .frame(height: 60)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
            
            // Auto-generate plan button
            HStack {
                Spacer()
                
                Button(action: generatePlanWithLLM) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Text("Generate Plan with LLM")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || prompt == nil || store.getAPIKey(service: store.selectedLLMModel.rawValue) == nil)
            }
        }
    }
    
    private var implementationView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step 4: Implement the Plan")
                .font(.headline)
            
            if improvedText.isEmpty {
                VStack {
                    Button(action: implementPlanWithLLM) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        } else {
                            Text("Generate Improved Prompt with LLM")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || prompt == nil || store.getAPIKey(service: store.selectedLLMModel.rawValue) == nil)
                    
                    Text("Or manually implement your plan below")
                        .font(.caption)
                        .padding(.top, 4)
                }
                
                TextEditor(text: $improvedText)
                    .frame(height: 200)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
            } else {
                HStack {
                    Text("Improved Prompt:")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Toggle("Show Diff", isOn: $showDiff)
                }
                
                if showDiff && prompt != nil {
                    DiffView(originalText: prompt!.text, newText: improvedText)
                        .frame(height: 200)
                } else {
                    ScrollView {
                        Text(improvedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.purple.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .frame(height: 200)
                }
                
                HStack {
                    Spacer()
                    
                    Button("Apply Improvement") {
                        applyImprovement()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private var nextButtonText: String {
        switch currentStep {
        case .analyze:
            return "Next: Questions"
        case .clarifyQuestions:
            return "Next: Planning"
        case .createPlan:
            return "Next: Implementation"
        case .implementPlan:
            return "Finish"
        }
    }
    
    private var canMoveNext: Bool {
        switch currentStep {
        case .analyze:
            return !promptGoal.isEmpty
        case .clarifyQuestions:
            return clarifyingQuestions.contains(where: { !$0.answer.isEmpty })
        case .createPlan:
            return planSteps.contains(where: { !$0.text.isEmpty })
        case .implementPlan:
            return !improvedText.isEmpty
        }
    }
    
    private func moveNext() {
        switch currentStep {
        case .analyze:
            currentStep = .clarifyQuestions
        case .clarifyQuestions:
            currentStep = .createPlan
        case .createPlan:
            currentStep = .implementPlan
        case .implementPlan:
            applyImprovement()
            isShowing = false
        }
    }
    
    private func moveBack() {
        switch currentStep {
        case .clarifyQuestions:
            currentStep = .analyze
        case .createPlan:
            currentStep = .clarifyQuestions
        case .implementPlan:
            currentStep = .createPlan
        default:
            break
        }
    }
    
    private func addCustomQuestion() {
        guard !customQuestion.isEmpty else { return }
        
        let newQuestion = PlannerQuestion(
            id: clarifyingQuestions.map { $0.id }.max() ?? 0 + 1,
            text: customQuestion,
            answer: ""
        )
        
        clarifyingQuestions.append(newQuestion)
        customQuestion = ""
    }
    
    private func addPlanStep() {
        let newStep = PlannerStepItem(
            id: planSteps.map { $0.id }.max() ?? 0 + 1,
            text: "",
            complete: false
        )
        
        planSteps.append(newStep)
    }
    
    private func analyzeWithLLM() {
        guard let promptText = prompt?.text else { return }
        errorMessage = nil
        isLoading = true
        
        let analysisPrompt = """
        I need you to analyze this prompt and help me understand its strengths and areas for improvement:
        
        PROMPT:
        \(promptText)
        
        Please provide:
        1. A one-sentence goal statement for what this prompt is trying to achieve
        2. 2-3 strengths of this prompt
        3. 2-3 areas where this prompt could be improved
        
        Format your response as:
        Goal: [goal statement]
        Strengths:
        - [strength 1]
        - [strength 2]
        Areas for Improvement:
        - [area 1]
        - [area 2]
        """
        
        let llmRequest = LLMRequest(
            prompt: analysisPrompt,
            model: store.selectedLLMModel,
            useReasoning: false
        )
        
        llmRequest.fetchImprovement { result in
            isLoading = false
            
            switch result {
            case .success(let response):
                // Parse the response to extract goal, strengths, and weaknesses
                parseAnalysisResponse(response)
            case .failure(let error):
                errorMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    private func parseAnalysisResponse(_ response: String) {
        // Simple parsing - could be improved with regex
        if let goalRange = response.range(of: "Goal: ", options: .caseInsensitive) {
            let goalStart = goalRange.upperBound
            if let goalEnd = response[goalStart...].range(of: "\n")?.lowerBound {
                promptGoal = String(response[goalStart..<goalEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        if let strengthsRange = response.range(of: "Strengths:", options: .caseInsensitive) {
            let strengthsStart = strengthsRange.upperBound
            if let strengthsEnd = response[strengthsStart...].range(of: "Areas for Improvement:", options: .caseInsensitive)?.lowerBound {
                promptStrengths = String(response[strengthsStart..<strengthsEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        if let weaknessesRange = response.range(of: "Areas for Improvement:", options: .caseInsensitive) {
            let weaknessesStart = weaknessesRange.upperBound
            promptWeaknesses = String(response[weaknessesStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    private func generatePlanWithLLM() {
        guard let promptText = prompt?.text else { return }
        errorMessage = nil
        isLoading = true
        
        // Prepare the answered questions
        let answeredQuestions = clarifyingQuestions
            .filter { !$0.answer.isEmpty }
            .map { "Q: \($0.text)\nA: \($0.answer)" }
            .joined(separator: "\n\n")
        
        let planPrompt = """
        I need a step-by-step plan to improve this prompt:
        
        ORIGINAL PROMPT:
        \(promptText)
        
        GOAL:
        \(promptGoal)
        
        STRENGTHS:
        \(promptStrengths)
        
        AREAS FOR IMPROVEMENT:
        \(promptWeaknesses)
        
        QUESTIONS AND ANSWERS:
        \(answeredQuestions)
        
        Please provide a numbered list of 3-5 specific steps to improve this prompt.
        Format each step as: "Step #: [clear action to take]"
        """
        
        let llmRequest = LLMRequest(
            prompt: planPrompt,
            model: store.selectedLLMModel,
            useReasoning: false
        )
        
        llmRequest.fetchImprovement { result in
            isLoading = false
            
            switch result {
            case .success(let response):
                // Parse the response to extract steps
                parsePlanResponse(response)
            case .failure(let error):
                errorMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    private func parsePlanResponse(_ response: String) {
        // Clear existing steps
        planSteps.removeAll()
        
        // Parse each line that starts with "Step" or a number
        let lines = response.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.hasPrefix("Step") || trimmedLine.range(of: "^\\d+[.:]", options: .regularExpression) != nil {
                // Extract the step text after the step number/prefix
                if let colonRange = trimmedLine.range(of: ":") {
                    let stepText = String(trimmedLine[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !stepText.isEmpty {
                        let newStep = PlannerStepItem(
                            id: planSteps.count + 1,
                            text: stepText,
                            complete: false
                        )
                        planSteps.append(newStep)
                    }
                } else if let dotRange = trimmedLine.range(of: ". ") {
                    let stepText = String(trimmedLine[dotRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !stepText.isEmpty {
                        let newStep = PlannerStepItem(
                            id: planSteps.count + 1,
                            text: stepText,
                            complete: false
                        )
                        planSteps.append(newStep)
                    }
                }
            }
        }
        
        // If no steps were found, add a default empty step
        if planSteps.isEmpty {
            planSteps.append(PlannerStepItem(id: 1, text: "", complete: false))
        }
    }
    
    private func implementPlanWithLLM() {
        guard let promptText = prompt?.text else { return }
        errorMessage = nil
        isLoading = true
        
        // Prepare the steps
        let stepsText = planSteps
            .filter { !$0.text.isEmpty }
            .enumerated()
            .map { "Step \($0 + 1): \($1.text)" }
            .joined(separator: "\n")
        
        // Prepare the answered questions
        let answeredQuestions = clarifyingQuestions
            .filter { !$0.answer.isEmpty }
            .map { "Q: \($0.text)\nA: \($0.answer)" }
            .joined(separator: "\n\n")
        
        let implementPrompt = """
        I need you to improve this prompt following these specific steps and requirements:
        
        ORIGINAL PROMPT:
        \(promptText)
        
        GOAL:
        \(promptGoal)
        
        IMPROVEMENT PLAN:
        \(stepsText)
        
        PLAN NOTES:
        \(planNotes)
        
        ADDITIONAL CONTEXT:
        \(answeredQuestions)
        
        Please provide ONLY the improved prompt text, with no additional explanations or commentary.
        """
        
        let llmRequest = LLMRequest(
            prompt: implementPrompt,
            model: store.selectedLLMModel,
            useReasoning: false
        )
        
        llmRequest.fetchImprovement { result in
            isLoading = false
            
            switch result {
            case .success(let response):
                improvedText = response
            case .failure(let error):
                errorMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    private func applyImprovement() {
        guard !improvedText.isEmpty, let promptID = prompt?.id else { return }
        
        // Create the plan summary
        let planSummary = planSteps
            .filter { !$0.text.isEmpty }
            .enumerated()
            .map { "Step \($0 + 1): \($1.text)" }
            .joined(separator: "\n")
        
        // Create notes about the improvement
        let notes = """
        Improved using Planner Mode workflow.
        
        Goal: \(promptGoal)
        
        Improvement Plan:
        \(planSummary)
        
        Plan Notes:
        \(planNotes)
        """
        
        _ = store.savePromptVersion(
            id: promptID, 
            text: improvedText,
            improvedByLLM: true,
            llmModel: store.selectedLLMModel.rawValue,
            notes: notes
        )
        
        isShowing = false
    }
}

// MARK: - Helper Structs

struct PlannerQuestion {
    var id: Int
    var text: String
    var answer: String
}

struct PlannerStepItem {
    var id: Int
    var text: String
    var complete: Bool
}

// Using PlannerStep from Types.swift for the enum
// Using PlannerStepItem for the local step item structure

struct StepProgressViewPlanner: View {
    let currentStep: PlannerStep
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(PlannerStep.allCases, id: \.self) { step in
                stepView(for: step)
                
                if step != PlannerStep.allCases.last {
                    connectingLine(for: step)
                }
            }
        }
    }
    
    private func stepView(for step: PlannerStep) -> some View {
        VStack {
            stepCircle(for: step)
            
            Text(step.title)
                .font(.caption)
                .foregroundColor(step == currentStep ? .primary : .secondary)
        }
    }
    
    private func stepCircle(for step: PlannerStep) -> some View {
        Circle()
            .fill(step.rawValue <= currentStep.rawValue ? Color.purple : Color.gray.opacity(0.3))
            .frame(width: 20, height: 20)
            .overlay {
                stepCircleContent(for: step)
            }
    }
    
    @ViewBuilder
    private func stepCircleContent(for step: PlannerStep) -> some View {
        if step.rawValue < currentStep.rawValue {
            Image(systemName: "checkmark")
                .foregroundColor(.white)
                .font(.caption)
        } else {
            if let index = PlannerStep.allCases.firstIndex(of: step) {
                Text("\(index + 1)")
                    .foregroundColor(.white)
                    .font(.caption)
            }
        }
    }
    
    private func connectingLine(for step: PlannerStep) -> some View {
        Rectangle()
            .fill(step.rawValue < currentStep.rawValue ? Color.purple : Color.gray.opacity(0.3))
            .frame(height: 2)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Diff View

struct DiffView: View {
    let originalText: String
    let newText: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(diffLines, id: \.id) { line in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(lineColor(for: line.type))
                            .frame(width: 5)
                        
                        Text(line.text)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(lineColor(for: line.type).opacity(0.1))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var diffLines: [DiffLine] {
        // Simple diff implementation - could be improved with a proper diff algorithm
        let originalLines = originalText.components(separatedBy: .newlines)
        let newLines = newText.components(separatedBy: .newlines)
        
        var result: [DiffLine] = []
        
        // Find removed lines (in original but not in new)
        for (idx, line) in originalLines.enumerated() {
            if !newLines.contains(line) {
                result.append(DiffLine(id: "r\(idx)", text: line, type: .removed))
            }
        }
        
        // Add unchanged and added lines
        for (idx, line) in newLines.enumerated() {
            if originalLines.contains(line) {
                result.append(DiffLine(id: "u\(idx)", text: line, type: .unchanged))
            } else {
                result.append(DiffLine(id: "a\(idx)", text: line, type: .added))
            }
        }
        
        // Sort result to match original document order (very simple approach)
        return result.sorted { a, b in
            if a.type == .removed && b.type != .removed {
                return true
            } else if a.type != .removed && b.type == .removed {
                return false
            } else {
                return a.id < b.id
            }
        }
    }
    
    private func lineColor(for type: DiffLineType) -> Color {
        switch type {
        case .added:
            return .green
        case .removed:
            return .red
        case .unchanged:
            return .gray
        }
    }
}

struct DiffLine {
    let id: String
    let text: String
    let type: DiffLineType
}

enum DiffLineType {
    case added
    case removed
    case unchanged
} 