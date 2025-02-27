// 
// ViewTemplate.swift
// PromptShelf
//
// Created by Template on 2/26/2025.
// Copyright © 2025 PromptShelf. All rights reserved.
//

import SwiftUI
import Foundation
import Combine

// This is a template file that should not be compiled directly
// It's used as a template for creating new view files

#if DEBUG
// MARK: - ViewTemplate

/// Template for creating new views
/// This is a template file and should not be compiled directly
public struct ViewTemplate {
    /// Placeholder for the view name
    public static let NAME_PLACEHOLDER = "ViewName"
    
    /// Generates a new view from the template
    /// - Parameter name: Name of the view to create
    /// - Returns: String containing the view implementation
    public static func generate(name: String) -> String {
        return """
        // 
        // \(name)View.swift
        // PromptShelf
        //
        // Created by PromptShelf on \(Date().formatted(date: .numeric, time: .omitted)).
        // Copyright © \(Calendar.current.component(.year, from: Date())) PromptShelf. All rights reserved.
        //

        import SwiftUI
        import Foundation
        import Combine

        // MARK: - \(name)View

        /// View for \(name) functionality
        struct \(name)View: View {
            // MARK: - Properties
            
            /// The view model
            @StateObject private var viewModel = \(name)ViewModel()
            
            // MARK: - Body
            
            var body: some View {
                NavigationView {
                    VStack {
                        // Your implementation goes here
                        Text("\(name) View")
                            .font(.title)
                    }
                    .navigationTitle("\(name)")
                }
            }
        }

        // MARK: - Preview

        #if DEBUG
        struct \(name)View_Previews: PreviewProvider {
            static var previews: some View {
                \(name)View()
            }
        }
        #endif
        """
    }
}
#endif 