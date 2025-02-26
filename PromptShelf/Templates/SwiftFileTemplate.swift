// 
// SwiftFileTemplate.swift
// PromptShelf
//
// Created by [Author] on [Date].
// Copyright © 2024 PromptShelf. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
// Add other imports as needed per .cursorrules guidelines

// MARK: - [TypeName]

/// [Description of the type]
/// - Note: Follow Cursor rules for documentation and organization (see .cursorrules)
struct [TypeName] {
    // MARK: - Properties
    
    /// [Description of property]
    private let property: String
    
    // MARK: - Initialization
    
    /// Initializes a new instance
    /// - Parameter property: [Description of parameter]
    init(property: String) {
        self.property = property
    }
    
    // MARK: - Methods
    
    /// [Description of method]
    /// - Parameter input: [Description of parameter]
    /// - Returns: [Description of return value]
    func method(input: String) -> String {
        // Implementation
        return input
    }
}

// MARK: - Extensions

extension [TypeName] {
    // Extension methods and properties
}

// MARK: - Preview

#if DEBUG
struct [TypeName]_Previews: PreviewProvider {
    static var previews: some View {
        // Preview content with dark theme per .cursorrules
        [TypeName](property: "Preview")
            .preferredColorScheme(.dark)
    }
}
#endif 