// 
// TestTemplate.swift
// PromptShelfTests
//
// Created by [Author] on [Date].
// Copyright © 2024 PromptShelf. All rights reserved.
//

import XCTest
@testable import PromptShelf
import PromptShelf.Models
import PromptShelf.Services

// MARK: - [Name]Tests

/// Tests for [Name] functionality
/// - Note: Follow Cursor rules for documentation and organization (see .cursorrules)
final class [Name]Tests: XCTestCase {
    // MARK: - Properties
    
    var store: PromptStore!
    
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
    
    /// Tests [Description of test]
    func test[Name]Creation() {
        // Arrange
        let prompt = Prompt(title: "Test", text: "Test content", folder: "Code")
        
        // Act
        let success = store.savePrompt(prompt)
        
        // Assert
        XCTAssertTrue(success)
        XCTAssertEqual(store.prompts.count, 1)
        XCTAssertEqual(store.prompts[prompt.id]?.title, "Test")
    }
    
    /// Tests [Description of test]
    func test[Name]Deletion() {
        // Arrange
        let prompt = Prompt(title: "Test", text: "Test content", folder: "Code")
        store.savePrompt(prompt)
        
        // Act
        let success = store.deletePrompt(id: prompt.id)
        
        // Assert
        XCTAssertTrue(success)
        XCTAssertNil(store.prompts[prompt.id])
    }
}

// MARK: - Extensions

extension [Name]Tests {
    // Extension methods for test helpers
} 