import Foundation

struct PromptVersion: Identifiable, Codable {
    let id: UUID
    var text: String
    var timestamp: Date
    var improvedByLLM: Bool
    var llmModel: String?
    var notes: String?
    
    init(id: UUID = UUID(), text: String, timestamp: Date = Date(), improvedByLLM: Bool = false, llmModel: String? = nil, notes: String? = nil) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.improvedByLLM = improvedByLLM
        self.llmModel = llmModel
        self.notes = notes
    }
}

struct Prompt: Identifiable, Codable {
    let id: UUID
    var title: String
    var text: String
    var folder: String // Name of the folder it belongs to
    var type: PromptType
    var versions: [PromptVersion]
    
    init(id: UUID = UUID(), title: String, text: String, folder: String, type: PromptType = .general, versions: [PromptVersion] = []) {
        self.id = id
        self.title = title
        self.text = text
        self.folder = folder
        self.type = type
        
        // If no versions are provided, create an initial version with the current text
        if versions.isEmpty {
            self.versions = [PromptVersion(text: text)]
        } else {
            self.versions = versions
        }
    }
}

enum PromptType: String, Codable, CaseIterable {
    case general = "General"
    case cursorFix = "Cursor Fix"
    case plannerMode = "Planner Mode"
}
