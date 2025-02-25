import Foundation
import SwiftUI
import Combine

/// ViewModel for the Settings view
public class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // API Keys
    @Published public var apiKey: String = ""
    @Published public var selectedProvider: ModelProvider? = .openAI
    @Published public var selectedModel: LLMModel = .gpt4
    @Published public var showAPIKey: Bool = false
    @Published public var showReasoningModelsOnly: Bool = false
    @Published public var isValidating: Bool = false
    @Published public var showValidationSuccess: Bool = false
    @Published public var showGuide: Bool = true
    
    // Navigation
    @Published public var selectedSection: SettingsSection = .apiKeys
    
    // Appearance
    @Published public var selectedTheme: AppTheme = .classic
    
    // Advanced
    @Published public var rateLimitValue: Double = 5
    @Published public var enableCaching: Bool = true
    @Published public var cacheDuration: CacheSettings.CacheDuration = .week
    @Published public var enableLogging: Bool = false
    
    // API Usage
    @Published public var showResetConfirmation: Bool = false
    
    // Toast
    @Published public var showToast: Bool = false
    @Published public var toastMessage: String = ""
    @Published public var toastType: ToastType = .success
    
    // MARK: - Dependencies
    
    // Using the protocol instead of the concrete implementation
    private let promptStore: PromptManaging
    
    // Computed property to expose promptStore to views
    public var store: PromptManaging {
        return promptStore
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(store: PromptManaging) {
        self.promptStore = store
        
        // Load initial values
        if let provider = ModelProvider.allCases.first {
            selectedProvider = provider
            if let model = provider.models.first {
                selectedModel = model
                if let apiKey = store.getAPIKey(service: model.rawValue) {
                    self.apiKey = apiKey
                }
            }
        }
        
        // Load user preferences
        loadSettings()
        
        // Set up observation of any properties that need it
        setupObservation()
    }
    
    // MARK: - API Key Management
    
    public func validateAPIKey() {
        guard !apiKey.isEmpty else {
            showToast(message: "Please enter an API key", type: .error)
            return
        }
        
        isValidating = true
        showToast(message: "Validating API key...", type: .info)
        
        // Create a test request
        let testRequest = LLMRequest(
            apiKey: apiKey,
            prompt: "Test prompt for validation",
            model: selectedModel.rawValue
        )
        
        // Test the API key
        testRequest.fetchImprovement { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isValidating = false
                
                switch result {
                case .success(_):
                    self.showToast(message: "API key is valid", type: .success)
                    self.showValidationSuccess = true
                case .failure(let error):
                    var errorMessage = "API key validation failed"
                    
                    if let nsError = error as NSError? {
                        if nsError.domain == "APIError" && nsError.code == 401 {
                            errorMessage = "Invalid API key. Please check and try again."
                        } else if nsError.domain == "APIError" && nsError.code == 429 {
                            errorMessage = "Rate limit exceeded. Please try again later."
                        } else if nsError.domain == "URLError" {
                            errorMessage = "Network error. Please check your internet connection."
                        } else {
                            errorMessage = "Error: \(nsError.localizedDescription)"
                        }
                    }
                    
                    self.showToast(message: errorMessage, type: .error)
                }
            }
        }
    }
    
    public func saveAPIKey() {
        let success = promptStore.saveAPIKey(service: selectedModel.rawValue, key: apiKey)
        
        if success {
            showToast(message: "API key saved successfully", type: .success)
        } else {
            showToast(message: "Failed to save API key", type: .error)
        }
    }
    
    public func deleteAPIKey() {
        let success = promptStore.deleteAPIKey(service: selectedModel.rawValue)
        
        if success {
            apiKey = ""
            showToast(message: "API key deleted successfully", type: .success)
        } else {
            showToast(message: "Failed to delete API key", type: .error)
        }
    }
    
    // MARK: - API Usage
    
    public func resetAPIUsageData() {
        // Use our promptStore extension method
        if let store = promptStore as? PromptStore {
            store.resetAPIUsageStats()
            showToast(message: "API usage data has been reset", type: .success)
        } else {
            // Create new empty stats directly
            promptStore.apiUsageStats = APIUsageStats()
            _ = promptStore.saveAPIUsageStats()
            showToast(message: "API usage data has been reset", type: .success)
        }
    }
    
    // MARK: - Model Selection
    
    public func modelSelected(_ model: LLMModel) {
        selectedModel = model
        if let savedKey = promptStore.getAPIKey(service: model.rawValue) {
            apiKey = savedKey
        } else {
            apiKey = ""
        }
    }
    
    public func getDisplayName(for modelId: String) -> String {
        if let model = LLMModel.allCases.first(where: { $0.rawValue == modelId }) {
            return model.displayName
        }
        return modelId
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        let userDefaults = UserDefaults.standard
        
        // Load theme
        if let themeName = userDefaults.string(forKey: "AppTheme"),
           let theme = AppTheme(rawValue: themeName) {
            selectedTheme = theme
        }
        
        // Load rate limit
        rateLimitValue = userDefaults.double(forKey: "RateLimit")
        if rateLimitValue == 0 {
            rateLimitValue = 5 // Default value
        }
        
        // Load caching settings
        enableCaching = userDefaults.bool(forKey: "EnableCaching")
        if let cacheDurationValue = userDefaults.object(forKey: "CacheDuration") as? Int,
           let duration = CacheSettings.CacheDuration(rawValue: cacheDurationValue) {
            cacheDuration = duration
        }
        
        // Load logging settings
        enableLogging = userDefaults.bool(forKey: "EnableLogging")
    }
    
    private func saveSettings() {
        let userDefaults = UserDefaults.standard
        
        userDefaults.set(selectedTheme.rawValue, forKey: "AppTheme")
        userDefaults.set(rateLimitValue, forKey: "RateLimit")
        userDefaults.set(enableCaching, forKey: "EnableCaching")
        userDefaults.set(cacheDuration.rawValue, forKey: "CacheDuration")
        userDefaults.set(enableLogging, forKey: "EnableLogging")
    }
    
    private func setupObservation() {
        // Watch for changes to settings and save them
        $selectedTheme
            .dropFirst() // Skip initial value
            .debounce(for: .seconds(1), scheduler: RunLoop.main) // Wait a second to avoid multiple saves
            .sink { [weak self] _ in
                self?.saveSettings()
            }
            .store(in: &cancellables)
        
        $rateLimitValue
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveSettings()
            }
            .store(in: &cancellables)
        
        $enableCaching
            .dropFirst()
            .sink { [weak self] _ in
                self?.saveSettings()
            }
            .store(in: &cancellables)
        
        $cacheDuration
            .dropFirst()
            .sink { [weak self] _ in
                self?.saveSettings()
            }
            .store(in: &cancellables)
        
        $enableLogging
            .dropFirst()
            .sink { [weak self] _ in
                self?.saveSettings()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Toast
    
    public func showToast(message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        showToast = true
        
        // Automatically hide the toast after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showToast = false
        }
    }
    
    // MARK: - Deinitializer
    
    deinit {
        cancellables.removeAll()
    }
} 