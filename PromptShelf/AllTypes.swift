import Foundation
import SwiftUI
import Combine

// This file re-exports common types to simplify imports throughout the app
// No need for typealiases or module references

// Re-export Foundation types
@_exported import struct Foundation.UUID
@_exported import struct Foundation.Date
@_exported import class Foundation.NSObject
@_exported import class Foundation.JSONEncoder
@_exported import class Foundation.JSONDecoder

// All core types are directly available from the main module
// No need for typealiases or re-exports as they're already in the module scope 