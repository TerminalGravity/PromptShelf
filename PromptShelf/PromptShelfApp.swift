import SwiftUI
// No need to import PromptShelf.Models as we're in the same module

// Import the Models module
@main
struct PromptShelfApp: App {
    // Create a single instance of PromptStore to share across the app
    @StateObject private var store = PromptStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
