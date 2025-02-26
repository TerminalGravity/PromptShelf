// 
// ServiceTemplate.swift
// PromptShelf
//
// Created by [Author] on [Date].
// Copyright © 2024 PromptShelf. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import PromptShelf.Models
import PromptShelf.Services

// MARK: - [Name]Service

/// Service for handling [Name] operations
/// - Note: Follow Cursor rules for documentation, organization, linting, and async/await usage (see .cursorrules)
@ObservableObject
class [Name]Service {
    // MARK: - Published Properties
    
    /// [Description of property]
    @Published var isLoading: Bool = false
    
    /// Data managed by this service
    @Published var data: [Prompt] = []
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var activeTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    /// Initializes a new instance of the service
    init() {
        Task { 
            do {
                try await loadData() 
            } catch {
                print("Failed to load initial data: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads data from storage or API
    /// - Returns: Boolean indicating success
    /// - Throws: An error if the operation fails
    /// - Note: Integrates with PromptStore for prompt management, per .cursorrules
    func loadData() async throws -> Bool {
        await MainActor.run {
            isLoading = true
            cancelActiveTask()
        }
        
        do {
            let prompts = try await fetchPrompts()
            
            // Check for cancellation
            try Task.checkCancellation()
            
            await MainActor.run {
                self.data = prompts
                self.isLoading = false
            }
            return true
        } catch is CancellationError {
            await MainActor.run {
                self.isLoading = false
            }
            throw CancellationError()
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            throw error
        }
    }
    
    /// Saves data to storage
    /// - Parameter data: The data to save
    /// - Returns: Boolean indicating success
    /// - Throws: An error if the operation fails
    /// - Note: Uses PromptStore for persistence, per .cursorrules
    func saveData(_ data: [Prompt]) async throws -> Bool {
        await MainActor.run {
            isLoading = true
            cancelActiveTask()
        }
        
        do {
            try await persistPrompts(data)
            
            // Check for cancellation
            try Task.checkCancellation()
            
            await MainActor.run {
                self.data = data
                self.isLoading = false
            }
            return true
        } catch is CancellationError {
            await MainActor.run {
                self.isLoading = false
            }
            throw CancellationError()
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            throw error
        }
    }
    
    /// Cancels any ongoing operations
    func cancelOperations() {
        cancelActiveTask()
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Private Methods
    
    /// Fetches prompts from storage or API
    /// - Throws: An error if the fetch operation fails
    /// - Returns: Array of prompts
    private func fetchPrompts() async throws -> [Prompt] {
        // Simulate fetching, using PromptStore
        try await Task.checkCancellation()
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1-second delay
        
        // Use PromptStore to get actual prompts in a real implementation
        let store = PromptStore()
        return Array(store.prompts.values)
    }
    
    /// Persists prompts to storage
    /// - Parameter prompts: The prompts to persist
    /// - Throws: An error if the persistence operation fails
    private func persistPrompts(_ prompts: [Prompt]) async throws {
        // Simulate saving, using PromptStore
        try await Task.checkCancellation()
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1-second delay
        
        let store = PromptStore()
        for prompt in prompts {
            if !store.savePrompt(prompt) {
                throw NSError(domain: "PromptShelf", code: 1001, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to save prompt: \(prompt.title)"
                ])
            }
        }
    }
    
    /// Cancels the active task if one exists
    private func cancelActiveTask() {
        activeTask?.cancel()
        activeTask = nil
    }
    
    /// Cleanup resources when the service is deallocated
    deinit {
        cancelOperations()
    }
}

// MARK: - Extensions

extension [Name]Service {
    // Extension methods and properties
} 