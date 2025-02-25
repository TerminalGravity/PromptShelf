import Foundation
import SwiftUI

// MARK: - Settings View Enums

/// Settings section categories
public enum SettingsSection: String, CaseIterable, Identifiable {
    case apiKeys
    case apiUsage
    case appearance
    case advanced
    case about
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .apiKeys: return "API Keys"
        case .apiUsage: return "API Usage"
        case .appearance: return "Appearance"
        case .advanced: return "Advanced"
        case .about: return "About"
        }
    }
    
    public var iconName: String {
        switch self {
        case .apiKeys: return "key.fill"
        case .apiUsage: return "chart.bar.fill"
        case .appearance: return "paintbrush.fill"
        case .advanced: return "gearshape.2.fill"
        case .about: return "info.circle.fill"
        }
    }
}

/// App theme options
public enum AppTheme: String, CaseIterable, Identifiable {
    case classic
    case dark
    case light
    case system
    
    public var id: String { rawValue }
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Toast notification types
public enum ToastType {
    case success
    case error
    case info
    
    public var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        }
    }
}

// MARK: - Cache Settings

public struct CacheSettings {
    public var enabled: Bool = true
    public var duration: CacheDuration = .week
    
    public enum CacheDuration: Int, CaseIterable {
        case day = 1
        case week = 7
        case month = 30
        case forever = 0
        
        public var displayName: String {
            switch self {
            case .day: return "1 Day"
            case .week: return "1 Week"
            case .month: return "1 Month"
            case .forever: return "Forever"
            }
        }
    }
} 