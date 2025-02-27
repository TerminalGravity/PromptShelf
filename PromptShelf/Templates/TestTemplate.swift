// 
// TestTemplate.swift
// PromptShelf
//
// Created by Template on 2/26/2025.
// Copyright © 2025 PromptShelf. All rights reserved.
//

import Foundation
import SwiftUI

// This is a template file that should not be compiled directly
// It's used as a template for creating new test files

#if DEBUG
// MARK: - TestTemplate

/// Template for creating new test files
/// This is a template file and should not be compiled directly
public struct TestTemplate {
    /// Placeholder for the test class name
    public static let NAME_PLACEHOLDER = "Feature"
    
    /// Generates a new test file from the template
    /// - Parameter name: Name of the test class to create
    /// - Returns: String containing the test implementation
    public static func generate(name: String) -> String {
        let year = Calendar.current.component(.year, from: Date())
        let date = Date().formatted(date: .numeric, time: .omitted)
        
        return """
        //
        // \(name)Tests.swift
        // PromptShelfTests
        //
        // Created by PromptShelf on \(date).
        // Copyright © \(year) PromptShelf. All rights reserved.
        //

        import XCTest
        @testable import PromptShelf

        /// Tests for \(name) functionality
        class \(name)Tests: XCTestCase {
            // MARK: - Properties
            
            private var store: PromptStore!
            
            // MARK: - Setup and Teardown
            
            override func setUp() {
                super.setUp()
                store = PromptStore()
            }
            
            override func tearDown() {
                store = nil
                super.tearDown()
            }
            
            // MARK: - Tests
            
            /// Tests basic functionality
            func test\(name)Basic() {
                // Test implementation goes here
            }
        }
        """
    }
}
#endif 