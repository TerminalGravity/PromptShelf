import Foundation
import Security

class PromptStore: ObservableObject {
    @Published var prompts: [Prompt] = []
    @Published var selectedLLMModel: LLMModel = .gpt4
    
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
    
    func addPrompt(title: String, text: String, folder: String, type: PromptType = .general) {
        let newPrompt = Prompt(title: title, text: text, folder: folder, type: type)
        prompts.append(newPrompt)
        savePrompts()
    }
    
    func updatePromptText(id: UUID, newText: String) {
        if let index = prompts.firstIndex(where: { $0.id == id }) {
            prompts[index].text = newText
            // Also add a new version
            let newVersion = PromptVersion(text: newText)
            prompts[index].versions.append(newVersion)
            savePrompts()
        }
    }
    
    func savePromptVersion(id: UUID, text: String, improvedByLLM: Bool = false, llmModel: String? = nil, notes: String? = nil) {
        if let index = prompts.firstIndex(where: { $0.id == id }) {
            let newVersion = PromptVersion(
                text: text,
                improvedByLLM: improvedByLLM,
                llmModel: llmModel,
                notes: notes
            )
            prompts[index].versions.append(newVersion)
            // Also update the main text to the latest version
            prompts[index].text = text
            savePrompts()
        }
    }
    
    func promptsByType(type: PromptType) -> [Prompt] {
        return prompts.filter { $0.type == type }
    }
    
    func folders() -> [String] {
        Array(Set(prompts.map { $0.folder })).sorted()
    }
    
    // MARK: - API Key Management
    
    func saveAPIKey(service: String, key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "APIKey",
            kSecValueData as String: key.data(using: .utf8)!
        ]
        
        // Delete any existing key before saving
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getAPIKey(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "APIKey",
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let data = item as? Data, let key = String(data: data, encoding: .utf8) {
            return key
        }
        return nil
    }
    
    func deleteAPIKey(service: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "APIKey"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - LLM API Integration
    
    func improvePromptWithLLM(promptID: UUID, completion: @escaping (Result<String, Error>) -> Void) {
        guard let prompt = prompts.first(where: { $0.id == promptID }) else {
            completion(.failure(NSError(domain: "PromptNotFound", code: -1, userInfo: nil)))
            return
        }
        
        let apiKey = getAPIKey(service: selectedLLMModel.rawValue)
        guard let key = apiKey, !key.isEmpty else {
            completion(.failure(NSError(domain: "APIKeyNotFound", code: -2, userInfo: nil)))
            return
        }
        
        let llmRequest = LLMRequest(
            apiKey: key,
            prompt: "Improve this prompt: \(prompt.text)",
            model: selectedLLMModel.rawValue
        )
        
        llmRequest.fetchImprovement { result in
            switch result {
            case .success(let improvedText):
                DispatchQueue.main.async {
                    self.savePromptVersion(
                        id: promptID,
                        text: improvedText,
                        improvedByLLM: true,
                        llmModel: self.selectedLLMModel.rawValue,
                        notes: "Improved by LLM"
                    )
                    completion(.success(improvedText))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - LLM Request Helper

struct LLMRequest {
    let apiKey: String
    let prompt: String
    let model: String
    
    func fetchImprovement(completion: @escaping (Result<String, Error>) -> Void) {
        // This is a placeholder implementation that would need to be replaced
        // with actual API calls to your chosen LLM provider (OpenAI, Anthropic, etc.)
        
        // Determine which API to call based on the model
        if model.contains("gpt") {
            // Call OpenAI API
            callOpenAIAPI(completion: completion)
        } else if model.contains("claude") {
            // Call Anthropic API
            callAnthropicAPI(completion: completion)
        } else {
            // Default placeholder response for demo purposes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                completion(.success("Improved version of prompt by \(model)"))
            }
        }
    }
    
    private func callOpenAIAPI(completion: @escaping (Result<String, Error>) -> Void) {
        // Implementation for OpenAI API would go here
        // This is just a placeholder
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are an expert in crafting effective prompts. Your task is to improve the user's prompt to be clearer, more specific, and more effective."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 1000
        ]
        
        // In a real implementation, you would:
        // 1. Convert body to JSON
        // 2. Make the HTTP request
        // 3. Parse the response
        // 4. Return the improved prompt
        
        // For now, just return a simulated response
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(.success("Improved OpenAI version: Make the prompt more specific by stating exactly what you want the AI to do. Include context, desired format, and constraints."))
        }
    }
    
    private func callAnthropicAPI(completion: @escaping (Result<String, Error>) -> Void) {
        // Implementation for Anthropic API would go here
        // Simulated response for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(.success("Improved Claude version: Consider providing clear instructions with step-by-step guidance. Be explicit about the output format you expect."))
        }
    }
}

enum LLMModel: String, CaseIterable {
    case gpt4 = "gpt-4"
    case gpt35Turbo = "gpt-3.5-turbo"
    case claude3 = "claude-3-opus"
    case claude3Sonnet = "claude-3-sonnet"
}
