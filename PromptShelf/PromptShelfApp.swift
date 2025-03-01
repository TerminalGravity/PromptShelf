import SwiftUI

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
