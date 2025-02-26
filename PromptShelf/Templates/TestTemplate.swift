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
/// - Note: Follow Cursor rules for documentation, organization, linting, and async/await usage (see .cursorrules)
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
    /// - Note: Tests prompt creation and storage
    func test[Name]Creation() {
        // Arrange
        let prompt = Prompt(title: "Test", text: "Test content", folder: "Code")
        
        // Act
        let success = store.savePrompt(prompt)
        
        // Assert
        XCTAssertTrue(success, "Prompt should save successfully")
        XCTAssertEqual(store.prompts.count, 1, "There should be one prompt")
        XCTAssertEqual(store.prompts[prompt.id]?.title, "Test", "Prompt title should match")
    }
    
    /// Tests [Description of test]
    /// - Note: Tests prompt deletion
    func test[Name]Deletion() {
        // Arrange
        let prompt = Prompt(title: "Test", text: "Test content", folder: "Code")
        store.savePrompt(prompt)
        
        // Act
        let success = store.deletePrompt(id: prompt.id)
        
        // Assert
        XCTAssertTrue(success, "Prompt should delete successfully")
        XCTAssertNil(store.prompts[prompt.id], "Prompt should no longer exist")
    }
    
    /// Tests [Description of test]
    /// - Note: Tests LLM improvement
    func testPromptImprovement() async {
        // Arrange
        let prompt = Prompt(title: "Test", text: "Improve this prompt", folder: "Code")
        store.savePrompt(prompt)
        
        // Act
        do {
            let improvedPrompt = try await store.improvePromptWithLLM(prompt: prompt, model: .openAI)
            // Assert
            XCTAssertNotEqual(improvedPrompt.text, prompt.text, "Prompt should be improved")
            XCTAssertTrue(improvedPrompt.versions.count > 0, "Should have a new version")
            XCTAssertTrue(improvedPrompt.versions.last?.improvedByLLM ?? false, "Version should be improved by LLM")
            
            // Additional assertions
            XCTAssertGreaterThan(improvedPrompt.text.count, prompt.text.count, "Improved prompt should be more detailed")
            XCTAssertEqual(improvedPrompt.title, prompt.title, "Title should remain unchanged")
            XCTAssertEqual(improvedPrompt.folder, prompt.folder, "Folder should remain unchanged")
        } catch {
            XCTFail("Improvement failed with error: \(error)")
        }
    }
    
    /// Tests [Description of test] for async operations
    /// - Note: Tests error handling in async methods
    func testAsyncOperationFailure() async {
        // Arrange
        let invalidPrompt = Prompt(title: "", text: "", folder: "") // Invalid prompt to simulate failure
        
        // Act & Assert
        do {
            _ = try await store.improvePromptWithLLM(prompt: invalidPrompt, model: .openAI)
            XCTFail("Should throw an error for invalid prompt")
        } catch {
            XCTAssertNotNil(error, "Should catch an error for invalid prompt")
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "PromptShelf", "Error should be from PromptShelf domain")
        }
    }
    
    /// Tests task cancellation handling
    /// - Note: Tests proper cancellation of async operations
    func testTaskCancellation() async {
        // Arrange
        let prompt = Prompt(title: "Test", text: "Cancel this operation", folder: "Code")
        store.savePrompt(prompt)
        
        // Act
        let expectation = XCTestExpectation(description: "Task should be cancelled")
        
        let task = Task {
            do {
                _ = try await store.improvePromptWithLLM(prompt: prompt, model: .openAI)
                XCTFail("Task should have been cancelled")
            } catch is CancellationError {
                // Success: Task was cancelled as expected
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        
        // Cancel after a short delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        task.cancel()
        
        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    /// Tests concurrent operations
    /// - Note: Tests handling multiple concurrent operations
    func testConcurrentOperations() async {
        // Arrange
        let prompt1 = Prompt(title: "Test 1", text: "First prompt", folder: "Code")
        let prompt2 = Prompt(title: "Test 2", text: "Second prompt", folder: "Code")
        store.savePrompt(prompt1)
        store.savePrompt(prompt2)
        
        // Act
        async let result1 = store.improvePromptWithLLM(prompt: prompt1, model: .openAI)
        async let result2 = store.improvePromptWithLLM(prompt: prompt2, model: .openAI)
        
        // Assert
        do {
            let (improved1, improved2) = try await (result1, result2)
            XCTAssertNotEqual(improved1.text, prompt1.text, "First prompt should be improved")
            XCTAssertNotEqual(improved2.text, prompt2.text, "Second prompt should be improved")
        } catch {
            XCTFail("Concurrent operations failed: \(error)")
        }
    }
}

// MARK: - Extensions

extension [Name]Tests {
    // Extension methods for test helpers
} 