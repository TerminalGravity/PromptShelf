import Foundation
import Combine
import Security

/// Concrete implementation of the PromptManaging protocol
public class PromptStore: PromptManaging {
    // MARK: - Published Properties
    
    @Published public var prompts: [UUID: Prompt] = [:]
    @Published public var selectedLLMModel: LLMModel = .gpt4
    @Published public var apiUsageStats: APIUsageStats = APIUsageStats()
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let promptsKey = "StoredPrompts"
    private let apiUsageStatsKey = "APIUsageStats"
    private let keychainServicePrefix = "com.promptshelf.apikey."
    
    // MARK: - Initialization
    
    public init() {
        loadFromUserDefaults()
        print("PromptStore initialized with \(prompts.count) prompts")
    }
    
    // MARK: - API Key Management
    
    public func getAPIKey(service: String) -> String? {
        let service = keychainServicePrefix + service
        
        var itemCopy: CFTypeRef?
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, &itemCopy)
        
        guard status == errSecSuccess,
              let passwordData = itemCopy as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            return nil
        }
        
        return password
    }
    
    public func saveAPIKey(service: String, key: String) -> Bool {
        let service = keychainServicePrefix + service
        
        // Check if item exists
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let searchResult = SecItemCopyMatching(query as CFDictionary, nil)
        
        if searchResult == errSecSuccess {
            // Update existing item
            let updateAttributes: [String: Any] = [
                kSecValueData as String: key.data(using: .utf8)!
            ]
            
            let status = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
            return status == errSecSuccess
        } else {
            // Create new item
            let newItem: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecValueData as String: key.data(using: .utf8)!
            ]
            
            let status = SecItemAdd(newItem as CFDictionary, nil)
            return status == errSecSuccess
        }
    }
    
    public func deleteAPIKey(service: String) -> Bool {
        let service = keychainServicePrefix + service
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Prompt Management
    
    public func savePrompt(_ prompt: Prompt) -> Bool {
        prompts[prompt.id] = prompt
        return saveToUserDefaults()
    }
    
    public func deletePrompt(id: UUID) -> Bool {
        prompts.removeValue(forKey: id)
        return saveToUserDefaults()
    }
    
    // MARK: - API Usage Stats
    
    public func saveAPIUsageStats() -> Bool {
        do {
            let data = try JSONEncoder().encode(apiUsageStats)
            userDefaults.set(data, forKey: apiUsageStatsKey)
            return true
        } catch {
            print("Error saving API usage stats: \(error)")
            return false
        }
    }
    
    // MARK: - Persistence
    
    private func saveToUserDefaults() -> Bool {
        do {
            let promptsArray = Array(prompts.values)
            let data = try JSONEncoder().encode(promptsArray)
            userDefaults.set(data, forKey: promptsKey)
            return true
        } catch {
            print("Error saving prompts: \(error)")
            return false
        }
    }
    
    private func loadFromUserDefaults() {
        // Load prompts
        if let data = userDefaults.data(forKey: promptsKey) {
            do {
                let promptsArray = try JSONDecoder().decode([Prompt].self, from: data)
                for prompt in promptsArray {
                    prompts[prompt.id] = prompt
                }
            } catch {
                print("Error loading prompts: \(error)")
            }
        }
        
        // Load API usage stats
        if let data = userDefaults.data(forKey: apiUsageStatsKey) {
            do {
                apiUsageStats = try JSONDecoder().decode(APIUsageStats.self, from: data)
            } catch {
                print("Error loading API usage stats: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Track API usage stats
    public func trackAPIUsage(model: String, tokens: Int) {
        apiUsageStats.totalCalls += 1
        apiUsageStats.totalTokensUsed += tokens
        
        // Update the counts by model
        apiUsageStats.callsByModel[model] = (apiUsageStats.callsByModel[model] ?? 0) + 1
        apiUsageStats.tokensByModel[model] = (apiUsageStats.tokensByModel[model] ?? 0) + tokens
        
        // Update last updated timestamp
        apiUsageStats.lastUpdated = Date()
        
        // Save the updated stats
        _ = saveAPIUsageStats()
    }
    
    /// Reset API usage stats
    public func resetAPIUsageStats() {
        apiUsageStats = APIUsageStats()
        _ = saveAPIUsageStats()
    }
} 