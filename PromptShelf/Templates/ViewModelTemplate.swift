// 
// ViewModelTemplate.swift
// PromptShelf
//
// Created by Template on 2/26/2025.
// Copyright © 2025 PromptShelf. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// This is a template file that should not be compiled directly
// It's used as a template for creating new view model classes

#if DEBUG
// MARK: - ViewModelTemplate

/// Template for creating new view models
/// This is a template file and should not be compiled directly
public struct ViewModelTemplate {
    /// Placeholder for the view model name
    public static let NAME_PLACEHOLDER = "ViewModelName"
    
    /// Generates a new view model from the template
    /// - Parameter name: Name of the view model to create
    /// - Returns: String containing the view model implementation
    public static func generate(name: String) -> String {
        return """
        // 
        // \(name)ViewModel.swift
        // PromptShelf
        //
        // Created by PromptShelf on \(Date().formatted(date: .numeric, time: .omitted)).
        // Copyright © \(Calendar.current.component(.year, from: Date())) PromptShelf. All rights reserved.
        //

        import Foundation
        import SwiftUI
        import Combine

        // MARK: - \(name)ViewModel

        /// ViewModel for \(name)View
        @MainActor
        class \(name)ViewModel: ObservableObject {
            // MARK: - Published Properties
            
            /// Main property
            @Published var property: String = ""
            
            /// Indicates whether an operation is in progress
            @Published var isLoading: Bool = false
            
            /// Toast message to display
            @Published var toastMessage: String = ""
            
            /// Whether to show the toast
            @Published var showToast: Bool = false
            
            // MARK: - Private Properties
            
            /// Cancellables for managing subscriptions
            private var cancellables = Set<AnyCancellable>()
            
            /// Reference to PromptStore for data management
            private let store: PromptStore
            
            // MARK: - Initialization
            
            /// Initializes a new instance of the view model
            init(store: PromptStore = PromptStore()) {
                self.store = store
                setupBindings()
            }
            
            // Your implementation goes here
        }
        """
    }
}
#endif 