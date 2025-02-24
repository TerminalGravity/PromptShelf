import Foundation

class PromptStore: ObservableObject {
    @Published var prompts: [Prompt] = []
    private let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("PromptShelf.json")
    
    init() {
        loadPrompts()
    }
    
    func loadPrompts() {
        do {
            let data = try Data(contentsOf: fileURL)
            prompts = try JSONDecoder().decode([Prompt].self, from: data)
        } catch {
            prompts = [] // If no file exists yet, start with an empty array
        }
    }
    
    func savePrompts() {
        do {
            let data = try JSONEncoder().encode(prompts)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save prompts: \(error.localizedDescription)")
        }
    }
    
    func addPrompt(title: String, text: String, folder: String) {
        let newPrompt = Prompt(title: title, text: text, folder: folder)
        prompts.append(newPrompt)
        savePrompts()
    }
    
    func folders() -> [String] {
        Array(Set(prompts.map { $0.folder })).sorted()
    }
}
