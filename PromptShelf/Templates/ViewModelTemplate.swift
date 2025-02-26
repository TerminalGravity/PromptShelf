// 
// ViewModelTemplate.swift
// PromptShelf
//
// Created by [Author] on [Date].
// Copyright © 2024 PromptShelf. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import PromptShelf.Services
import PromptShelf.Models

// MARK: - [Name]ViewModel

/// ViewModel for [Name]View
/// - Note: Follow Cursor rules for documentation, organization, linting, and async/await usage (see .cursorrules)
@ObservableObject
class [Name]ViewModel {
    // MARK: - Published Properties
    
    /// [Description of property]
    @Published var property: String = ""
    
    /// Indicates whether an operation is in progress
    @Published var isLoading: Bool = false
    
    /// Toast message to display
    @Published var toastMessage: String = ""
    
    /// Whether to show the toast
    @Published var showToast: Bool = false
    
    /// Type of toast to show
    @Published var toastType: ToastType = .info
    
    // MARK: - Private Properties
    
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Reference to PromptStore for data management
    private let store: PromptStore
    
    /// Active task for cancellation support
    private var activeTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    /// Initializes a new instance of the view model
    init(store: PromptStore = PromptStore()) {
        self.store = store
        setupBindings()
    }
    
    // MARK: - Setup
    
    /// Sets up data bindings
    /// - Note: Use @Published properties and Combine for reactive updates, per .cursorrules
    private func setupBindings() {
        $property
            .sink { [weak self] value in
                self?.store.savePrompt(Prompt(title: value, text: value, folder: "General"))
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// [Description of method]
    /// - Parameter input: [Description of parameter]
    /// - Throws: An error if the operation fails
    func performAction(input: String) async throws {
        // Cancel any existing task
        cancelActiveTask()
        
        // Create a new task for this operation
        activeTask = Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                let improvedPrompt = try await store.improvePromptWithLLM(
                    prompt: Prompt(title: input, text: input, folder: "General"),
                    model: .openAI
                )
                
                // Check for cancellation
                if Task.isCancelled { return }
                
                await MainActor.run {
                    property = improvedPrompt.text
                    showSuccessToast("Action completed successfully")
                    isLoading = false
                }
            } catch is CancellationError {
                await MainActor.run {
                    showInfoToast("Operation was cancelled")
                    isLoading = false
                }
            } catch {
                // Check for cancellation
                if Task.isCancelled { return }
                
                await MainActor.run {
                    showErrorToast("Failed to improve prompt: \(error.localizedDescription)")
                    isLoading = false
                }
            }
        }
        
        // Wait for the task to complete
        await activeTask?.value
    }
    
    /// Cancels any ongoing operations
    func cancelTasks() {
        cancelActiveTask()
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Private Methods
    
    /// Cancels the active task if one exists
    private func cancelActiveTask() {
        activeTask?.cancel()
        activeTask = nil
    }
    
    /// Shows a success toast with the given message
    /// - Parameter message: The message to display
    @MainActor
    private func showSuccessToast(_ message: String) {
        toastMessage = message
        toastType = .success
        showToast = true
        Task { 
            try? await Task.sleep(nanoseconds: UInt64(3 * 1_000_000_000)) // 3 seconds
            if !Task.isCancelled {
                showToast = false
            }
        }
    }
    
    /// Shows an error toast with the given message
    /// - Parameter message: The error message to display
    @MainActor
    private func showErrorToast(_ message: String) {
        toastMessage = message
        toastType = .error
        showToast = true
        Task { 
            try? await Task.sleep(nanoseconds: UInt64(3 * 1_000_000_000)) // 3 seconds
            if !Task.isCancelled {
                showToast = false
            }
        }
    }
    
    /// Shows an info toast with the given message
    /// - Parameter message: The info message to display
    @MainActor
    private func showInfoToast(_ message: String) {
        toastMessage = message
        toastType = .info
        showToast = true
        Task { 
            try? await Task.sleep(nanoseconds: UInt64(3 * 1_000_000_000)) // 3 seconds
            if !Task.isCancelled {
                showToast = false
            }
        }
    }
    
    /// Cleanup resources when the view model is deallocated
    deinit {
        cancelTasks()
    }
}

// MARK: - Extensions

extension [Name]ViewModel {
    // Extension methods and properties
} 