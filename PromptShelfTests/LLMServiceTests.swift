//
//  LLMServiceTests.swift
//  PromptShelfTests
//
//  Created by Claude on 2/26/25.
//  Copyright © 2025 PromptShelf. All rights reserved.
//

import XCTest
@testable import PromptShelf

/// Tests for LLM API functionality
/// - Note: Tests LLM API integration with mock URL protocol
class LLMServiceTests: XCTestCase {
    // MARK: - Properties
    
    var store: PromptStore!
    var session: URLSession!
    let mockAPIKey = "sk-mock-api-key-for-testing-purposes-only"
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        store = PromptStore()
        
        // Configure mock URL session
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)
    }
    
    override func tearDown() {
        store = nil
        session = nil
        MockURLProtocol.reset()
        super.tearDown()
    }
    
    // MARK: - Test OpenAI API Integration
    
    /// Tests o3 model with reasoning effort parameter
    func testOpenAIO3ModelWithReasoningEffort() async throws {
        // Arrange
        let testPrompt = "Test prompt for improvement with o3"
        let expectedResponse = """
        {
            "id": "chatcmpl-mock-o3",
            "object": "chat.completion",
            "created": 1708967888,
            "model": "o3-mini",
            "choices": [
                {
                    "message": {
                        "role": "assistant", 
                        "content": {
                            "reasoning": "The original prompt lacks specificity and context. It doesn't clearly state the desired outcome or target audience, making it difficult to determine what kind of response is expected.",
                            "improved_prompt": "Design a comprehensive onboarding flow for new users of our mobile banking application. Include key screens, user actions, and how to minimize drop-off. Consider both iOS and Android platforms, and focus on security features without compromising usability."
                        }
                    },
                    "finish_reason": "stop",
                    "index": 0
                }
            ],
            "usage": {
                "prompt_tokens": 15,
                "completion_tokens": 82,
                "total_tokens": 97
            }
        }
        """
        
        // Setup mock response
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        MockURLProtocol.mockResponses[url] = (
            data: expectedResponse.data(using: .utf8),
            response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
            error: nil
        )
        
        // Create request with o3 model
        let request = LLMRequest(
            apiKey: mockAPIKey,
            prompt: testPrompt,
            model: LLMModel.o3Mini.rawValue,
            useReasoning: true
        )
        
        // Act
        let result = try await request.fetchImprovement()
        
        // Assert
        XCTAssertTrue(result.contains("REASONING:"), "Response should include reasoning section")
        XCTAssertTrue(result.contains("IMPROVED PROMPT:"), "Response should include improved prompt section")
    }
    
    /// Tests successful OpenAI API call
    func testOpenAISuccessfulResponse() async throws {
        // Arrange
        let testPrompt = "Test prompt for improvement"
        let expectedResponse = """
        {
            "id": "chatcmpl-mock",
            "object": "chat.completion",
            "created": 1677825464,
            "model": "gpt-4o",
            "choices": [
                {
                    "message": {
                        "role": "assistant", 
                        "content": "REASONING:\\nThis prompt is quite vague and lacks specificity. I will improve it by adding more context, making it clearer, and providing specific instructions.\\n\\nIMPROVED PROMPT:\\nDevelop a comprehensive strategy to implement automated testing for a multi-platform mobile application. Include recommendations for unit, integration, and end-to-end tests, as well as continuous integration practices that would ensure code quality across iOS and Android platforms."
                    },
                    "finish_reason": "stop",
                    "index": 0
                }
            ],
            "usage": {
                "prompt_tokens": 10,
                "completion_tokens": 75,
                "total_tokens": 85
            }
        }
        """
        
        // Setup mock response
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        MockURLProtocol.mockResponses[url] = (
            data: expectedResponse.data(using: .utf8),
            response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
            error: nil
        )
        
        // Create request
        let request = LLMRequest(
            apiKey: mockAPIKey,
            prompt: testPrompt,
            model: LLMModel.gpt4o.rawValue,
            useReasoning: true
        )
        
        // Act
        let result = try await request.fetchImprovement()
        
        // Assert
        XCTAssertTrue(result.contains("REASONING:"), "Response should include reasoning section")
        XCTAssertTrue(result.contains("IMPROVED PROMPT:"), "Response should include improved prompt section")
    }
    
    /// Tests OpenAI error handling for auth errors
    func testOpenAIAuthErrorResponse() async {
        // Arrange
        let testPrompt = "Test prompt for improvement"
        let errorResponse = """
        {
            "error": {
                "message": "Invalid Authentication",
                "type": "invalid_request_error",
                "param": null,
                "code": "invalid_api_key"
            }
        }
        """
        
        // Setup mock response
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        MockURLProtocol.mockResponses[url] = (
            data: errorResponse.data(using: .utf8),
            response: HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil),
            error: nil
        )
        
        // Create request
        let request = LLMRequest(
            apiKey: "invalid-api-key",
            prompt: testPrompt,
            model: LLMModel.gpt4o.rawValue
        )
        
        // Act & Assert
        do {
            _ = try await request.fetchImprovement()
            XCTFail("Should have thrown an authentication error")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "AuthenticationError", "Error domain should be AuthenticationError")
            XCTAssertEqual(error.code, 401, "Error code should be 401")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// Tests OpenAI error handling for rate limit errors
    func testOpenAIRateLimitResponse() async {
        // Arrange
        let testPrompt = "Test prompt for improvement"
        let errorResponse = """
        {
            "error": {
                "message": "Rate limit exceeded",
                "type": "rate_limit_error",
                "param": null,
                "code": "rate_limit_exceeded"
            }
        }
        """
        
        // Setup mock response with Retry-After header
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let headerFields = ["Retry-After": "30"]
        MockURLProtocol.mockResponses[url] = (
            data: errorResponse.data(using: .utf8),
            response: HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: headerFields),
            error: nil
        )
        
        // Create request
        let request = LLMRequest(
            apiKey: mockAPIKey,
            prompt: testPrompt,
            model: LLMModel.gpt4o.rawValue
        )
        
        // Act & Assert
        do {
            _ = try await request.fetchImprovement()
            XCTFail("Should have thrown a rate limit error")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "RateLimitError", "Error domain should be RateLimitError")
            XCTAssertEqual(error.code, 429, "Error code should be 429")
            XCTAssertNotNil(error.userInfo["retryAfter"], "Should include retry-after info")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Test Anthropic API Integration
    
    /// Tests Claude 3.7 with extended thinking parameter
    func testClaude37WithExtendedThinking() async throws {
        // Arrange
        let testPrompt = "Test prompt for Claude 3.7 with extended thinking"
        let expectedResponse = """
        {
            "id": "msg_claude37_mock",
            "type": "message",
            "role": "assistant",
            "content": [
                {
                    "type": "text",
                    "text": "REASONING:\\nThe original prompt lacks detail, context, and specific requirements. To improve it, I'll add clarity about the target audience, purpose, scope, and expected outcomes. I'll also include constraints and format guidelines.\\n\\nAfter thorough analysis, I've identified that effective prompts typically contain:\\n1. Clear audience identification\\n2. Specific purpose or goals\\n3. Context about the subject\\n4. Format requirements\\n5. Length or depth expectations\\n6. Any constraints or limitations\\n\\nIMPROVED PROMPT:\\nCreate a detailed implementation plan for migrating our legacy PostgreSQL database (version 9.6) to a cloud-hosted PostgreSQL 14 environment on AWS RDS. Your plan should include a risk assessment, data migration strategy, application compatibility testing approach, and a rollback procedure. Target this plan for a senior DevOps team with PostgreSQL experience but limited AWS expertise. Include a timeline with specific milestones and success criteria for each phase of the migration."
                }
            ],
            "model": "claude-3-7-sonnet-20250219",
            "stop_reason": "end_turn",
            "usage": {
                "input_tokens": 14,
                "output_tokens": 198,
                "thinking_tokens": 32768
            }
        }
        """
        
        // Setup mock response
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        MockURLProtocol.mockResponses[url] = (
            data: expectedResponse.data(using: .utf8),
            response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
            error: nil
        )
        
        // Create request with Claude 3.7 model
        let request = LLMRequest(
            apiKey: mockAPIKey,
            prompt: testPrompt,
            model: LLMModel.claude3_7Sonnet.rawValue,
            useReasoning: true
        )
        
        // Act
        let result = try await request.fetchImprovement()
        
        // Assert
        XCTAssertTrue(result.contains("REASONING:"), "Response should include reasoning section")
        XCTAssertTrue(result.contains("IMPROVED PROMPT:"), "Response should include improved prompt section")
        // Check for detailed reasoning from extended thinking
        XCTAssertTrue(result.contains("After thorough analysis"), "Response should include detailed reasoning from extended thinking")
    }
    
    /// Tests successful Anthropic API call
    func testAnthropicSuccessfulResponse() async throws {
        // Arrange
        let testPrompt = "Test prompt for improvement"
        let expectedResponse = """
        {
            "id": "msg_mock",
            "type": "message",
            "role": "assistant",
            "content": [
                {
                    "type": "text",
                    "text": "REASONING:\\nThe original prompt is vague and lacks direction. I'll enhance it by adding specificity, context, and clear instructions.\\n\\nIMPROVED PROMPT:\\nAnalyze the performance metrics of our e-commerce platform during the last quarter (Q4 2024), focusing on conversion rates, average order value, and customer retention. Identify key factors contributing to the 15% increase in cart abandonment rate and propose three data-driven strategies to reverse this trend."
                }
            ],
            "model": "claude-3-7-sonnet-20250219",
            "stop_reason": "end_turn",
            "usage": {
                "input_tokens": 12,
                "output_tokens": 90,
                "thinking_tokens": 1024
            }
        }
        """
        
        // Setup mock response
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        MockURLProtocol.mockResponses[url] = (
            data: expectedResponse.data(using: .utf8),
            response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
            error: nil
        )
        
        // Create request
        let request = LLMRequest(
            apiKey: mockAPIKey,
            prompt: testPrompt,
            model: LLMModel.claude3_7Sonnet.rawValue,
            useReasoning: true
        )
        
        // Act
        let result = try await request.fetchImprovement()
        
        // Assert
        XCTAssertTrue(result.contains("REASONING:"), "Response should include reasoning section")
        XCTAssertTrue(result.contains("IMPROVED PROMPT:"), "Response should include improved prompt section")
    }
    
    /// Tests Anthropic error handling for auth errors
    func testAnthropicAuthErrorResponse() async {
        // Arrange
        let testPrompt = "Test prompt for improvement"
        let errorResponse = """
        {
            "type": "error",
            "error": {
                "type": "authentication_error",
                "message": "Invalid API key"
            }
        }
        """
        
        // Setup mock response
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        MockURLProtocol.mockResponses[url] = (
            data: errorResponse.data(using: .utf8),
            response: HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil),
            error: nil
        )
        
        // Create request
        let request = LLMRequest(
            apiKey: "invalid-api-key",
            prompt: testPrompt,
            model: LLMModel.claude3_7Sonnet.rawValue
        )
        
        // Act & Assert
        do {
            _ = try await request.fetchImprovement()
            XCTFail("Should have thrown an authentication error")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "AuthenticationError", "Error domain should be AuthenticationError")
            XCTAssertEqual(error.code, 401, "Error code should be 401")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Test Prompt Store Integration with LLM
    
    /// Tests PromptStore integration with LLM calls
    func testPromptStoreWithLLM() async {
        // Arrange
        let promptID = UUID()
        let testPrompt = Prompt(
            id: promptID,
            title: "Test Prompt",
            text: "Original test prompt",
            folder: "Tests"
        )
        store.prompts[promptID] = testPrompt
        
        // Setup mock response
        let expectedResponse = """
        {
            "id": "chatcmpl-mock",
            "object": "chat.completion",
            "created": 1677825464,
            "model": "gpt-4",
            "choices": [
                {
                    "message": {
                        "role": "assistant", 
                        "content": "Improved test prompt with added details and specifications."
                    },
                    "finish_reason": "stop",
                    "index": 0
                }
            ]
        }
        """
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        MockURLProtocol.mockResponses[url] = (
            data: expectedResponse.data(using: .utf8),
            response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
            error: nil
        )
        
        // Mock API key retrieval
        store.saveAPIKey(service: ModelProvider.openAI.rawValue, key: mockAPIKey)
        store.selectedLLMModel = .gpt4
        
        // Create expectation
        let expectation = self.expectation(description: "Prompt improvement completion")
        
        // Act
        store.improvePromptWithLLM(promptID: promptID) { result in
            switch result {
            case .success(let improved):
                // Assert
                XCTAssertNotEqual(improved, testPrompt.text, "Improved text should be different")
                XCTAssertTrue(improved.contains("Improved test prompt"), "Response should contain improvement")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Improvement failed: \(error.localizedDescription)")
            }
        }
        
        // Wait for expectation
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    /// Tests retry mechanism
    func testRetryMechanism() async {
        // Arrange
        let promptID = UUID()
        let testPrompt = Prompt(
            id: promptID,
            title: "Test Retry",
            text: "Retry test prompt",
            folder: "Tests"
        )
        store.prompts[promptID] = testPrompt
        
        // First response is a rate limit error
        let errorResponse = """
        {
            "error": {
                "message": "Rate limit exceeded",
                "type": "rate_limit_error",
                "code": "rate_limit_exceeded"
            }
        }
        """
        
        // Second response is successful
        let successResponse = """
        {
            "id": "chatcmpl-retry-success",
            "object": "chat.completion",
            "created": 1677825464,
            "model": "gpt-4",
            "choices": [
                {
                    "message": {
                        "role": "assistant", 
                        "content": "Successfully retried response"
                    },
                    "finish_reason": "stop",
                    "index": 0
                }
            ]
        }
        """
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let headerFields = ["Retry-After": "1"] // Short retry for tests
        
        // Setup mock URLProtocol with sequence of responses
        MockURLProtocol.responseSequence[url] = [
            (
                data: errorResponse.data(using: .utf8),
                response: HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: headerFields),
                error: nil
            ),
            (
                data: successResponse.data(using: .utf8),
                response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
                error: nil
            )
        ]
        
        // Mock API key retrieval
        store.saveAPIKey(service: ModelProvider.openAI.rawValue, key: mockAPIKey)
        store.selectedLLMModel = .gpt4
        
        // Create expectation
        let expectation = self.expectation(description: "Retry mechanism completion")
        
        // Act
        store.improvePromptWithLLM(promptID: promptID) { result in
            switch result {
            case .success(let improved):
                // Assert
                XCTAssertTrue(improved.contains("Successfully retried"), "Should receive the success response after retry")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Retry mechanism failed: \(error.localizedDescription)")
            }
        }
        
        // Wait for expectation - longer timeout to allow for retry delay
        await fulfillment(of: [expectation], timeout: 10.0)
    }
}

// MARK: - Mock URL Protocol

/// Mock URLProtocol for testing network requests without actual API calls
class MockURLProtocol: URLProtocol {
    // Mock responses dictionary [URL: (data, response, error)]
    static var mockResponses: [URL: (data: Data?, response: URLResponse?, error: Error?)] = [:]
    
    // Mock response sequence for testing retries
    static var responseSequence: [URL: [(data: Data?, response: URLResponse?, error: Error?)]] = [:]
    static var requestCount: [URL: Int] = [:]
    
    /// Reset all mock configurations
    static func reset() {
        mockResponses = [:]
        responseSequence = [:]
        requestCount = [:]
    }
    
    /// Determines if the protocol can handle the given request
    override class func canInit(with request: URLRequest) -> Bool {
        // Handle all requests
        return true
    }
    
    /// Returns a canonical version of the request
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    /// Starts loading the request
    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        
        // Check if we have a sequence of responses for this URL
        if var responses = MockURLProtocol.responseSequence[url], !responses.isEmpty {
            // Keep track of how many times this URL has been requested
            let count = MockURLProtocol.requestCount[url] ?? 0
            MockURLProtocol.requestCount[url] = count + 1
            
            // Get the appropriate response for this request count
            let responseIndex = min(count, responses.count - 1)
            let (data, response, error) = responses[responseIndex]
            
            if let error = error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            if let response = response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        
        // Check if we have a mock response for this URL
        guard let (data, response, error) = MockURLProtocol.mockResponses[url] else {
            let error = NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorUnknown,
                userInfo: [NSLocalizedDescriptionKey: "No mock response found for \(url)"]
            )
            client?.urlProtocol(self, didFailWithError: error)
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        
        // Return the mocked components
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        if let response = response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let data = data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    /// Stops loading the request
    override func stopLoading() {
        // No-op, but required by the protocol
    }
}