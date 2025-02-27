// 
// ServiceTemplate.swift
// PromptShelf
//
// Created by Template on 2/26/2025.
// Copyright © 2025 PromptShelf. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// MARK: - ServiceTemplate

#if DEBUG && !ENABLE_TESTING
/// Template for creating new services
/// This is a template file and should not be compiled directly
public struct ServiceTemplate {
    /// Placeholder for the service name
    public static let NAME_PLACEHOLDER = "ServiceName"
    
    /// Generates a new service from the template
    /// - Parameter name: Name of the service to create
    /// - Returns: String containing the service implementation
    public static func generate(name: String) -> String {
        return """
        // 
        // \(name)Service.swift
        // PromptShelf
        //
        // Created by PromptShelf on \(Date().formatted(date: .numeric, time: .omitted)).
        // Copyright © \(Calendar.current.component(.year, from: Date())) PromptShelf. All rights reserved.
        //

        import Foundation
        import SwiftUI
        import Combine

        // MARK: - \(name)Service

        /// Service for handling \(name) operations
        @MainActor
        class \(name)Service: ObservableObject {
            // MARK: - Published Properties
            
            /// Loading state
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
                        print("Failed to load initial data: \\(error.localizedDescription)")
                    }
                }
            }
            
            // Your implementation goes here
        }
        """
    }
}
#else
// Empty implementation for non-DEBUG builds
// This prevents compilation issues in the main target
struct ServiceTemplate {
    // Empty placeholder
}
#endif 