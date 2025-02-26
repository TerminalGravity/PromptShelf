// 
// ViewTemplate.swift
// PromptShelf
//
// Created by [Author] on [Date].
// Copyright © 2024 PromptShelf. All rights reserved.
//

import SwiftUI
import Foundation
import Combine
import PromptShelf.Services
import PromptShelf.Models

// MARK: - [Name]View

/// [Description of the view]
/// - Note: Follow Cursor rules for documentation, organization, linting, and async/await usage (see .cursorrules)
struct [Name]View: View {
    // MARK: - Properties
    
    /// The view model
    @ObservedObject var viewModel: [Name]ViewModel
    
    /// Environment presentation mode for dismissing the view
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Initialization
    
    /// Initializes a new instance of the view
    init() {
        self.viewModel = [Name]ViewModel()
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("[Name]")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            Task {
                                do {
                                    try await viewModel.performAction("New Item")
                                } catch {
                                    print("Action failed: \(error.localizedDescription)")
                                }
                            }
                        }) {
                            Image(systemName: "plus")
                        }
                        .disabled(viewModel.isLoading)
                    }
                    
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            viewModel.cancelTasks()
                        }
                        .disabled(!viewModel.isLoading)
                    }
                }
        }
        .overlay(
            ToastView(
                message: viewModel.toastMessage,
                type: viewModel.toastType,
                isShowing: $viewModel.showToast
            )
        )
        .preferredColorScheme(.dark) // Match dark theme per .cursorrules
    }
    
    // MARK: - Content View
    
    /// The main content view
    var contentView: some View {
        VStack {
            // Main content here, using PromptStore
            Text("Content goes here")
                .padding()
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                
                Button("Cancel Operation") {
                    viewModel.cancelTasks()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .padding(.top, 8)
            }
            
            Button("Perform Action") {
                Task {
                    do {
                        try await viewModel.performAction("Test")
                    } catch {
                        print("Action failed: \(error.localizedDescription)")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .disabled(viewModel.isLoading)
        }
        .padding()
        .background(Color.black) // Dark theme background
        .foregroundColor(.white) // Ensure text visibility in dark theme
    }
    
    // MARK: - Helper Views
    
    /// A helper view for [purpose]
    private func helperView() -> some View {
        VStack {
            // Helper view content
            Text("Helper view")
        }
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
    }
}

// MARK: - Preview

#if DEBUG
struct [Name]View_Previews: PreviewProvider {
    static var previews: some View {
        [Name]View()
            .preferredColorScheme(.dark) // Dark theme for previews
    }
}
#endif 