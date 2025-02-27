import Foundation
import SwiftUI
import Combine

// MARK: - Models

/// This file re-exports all types from the Models/Types.swift
/// so that other files can import a single file for all models
/// All actual type definitions are in Models/Types.swift

// Re-export Foundation types used throughout the app
@_exported import struct Foundation.UUID
@_exported import struct Foundation.Date

// Import the Types.swift file directly
// Since we can't use relative imports in Swift modules,
// we need to ensure the Types.swift file is properly included in the module
// through the module.modulemap file

// This file serves as a facade for the Models module
// The actual types are defined in Models/Types.swift and are made available
// through the module system defined in module.modulemap

// Note: We're not using typealias declarations here as they would be self-referential
// The types are made available through the module system instead 