import SwiftUI
import UniformTypeIdentifiers

struct ImportExportView: View {
    @ObservedObject var store: PromptStore
    @Environment(\.dismiss) var dismiss
    @State private var exportSelection: ExportSelection = .all
    @State private var selectedFolder: String? = nil
    @State private var showExportSuccessAlert = false
    @State private var showExportErrorAlert = false
    @State private var showImportSuccessAlert = false
    @State private var showImportErrorAlert = false
    @State private var importedPromptCount = 0
    @State private var errorMessage = ""
    
    enum ExportSelection: String, CaseIterable, Identifiable {
        case all = "All Prompts"
        case folder = "Selected Folder"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Prompts")) {
                    Picker("Export", selection: $exportSelection) {
                        ForEach(ExportSelection.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 5)
                    
                    if exportSelection == .folder {
                        Picker("Select Folder", selection: $selectedFolder) {
                            ForEach(store.folders(), id: \.self) { folder in
                                Text(folder).tag(folder as String?)
                            }
                        }
                        .disabled(store.folders().isEmpty)
                    }
                    
                    Button("Export to JSON File") {
                        exportPrompts()
                    }
                    .disabled(exportSelection == .folder && selectedFolder == nil)
                }
                
                Section(header: Text("Import Prompts")) {
                    Button("Import from JSON File") {
                        importPrompts()
                    }
                    
                    Text("Importing will add new prompts without overwriting existing ones")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Backup and Restore")) {
                    Button("Create Full Backup") {
                        exportAllData()
                    }
                    
                    Button("Restore from Backup") {
                        importAllData()
                    }
                    .foregroundColor(.orange)
                    
                    Text("Restoring from backup will replace all your current data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Import & Export")
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
            .alert("Export Successful", isPresented: $showExportSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your prompts have been exported successfully.")
            }
            .alert("Export Failed", isPresented: $showExportErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Import Successful", isPresented: $showImportSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Successfully imported \(importedPromptCount) prompts.")
            }
            .alert("Import Failed", isPresented: $showImportErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func exportPrompts() {
        do {
            // Filter prompts based on selection
            let promptsToExport: [UUID: Prompt]
            
            if exportSelection == .all {
                promptsToExport = store.prompts
            } else if let folder = selectedFolder {
                promptsToExport = store.prompts.filter { $0.value.folder == folder }
            } else {
                throw NSError(domain: "ExportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No folder selected for export"])
            }
            
            // Create JSON data
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(promptsToExport)
            
            // Create a save panel
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [UTType.json]
            savePanel.nameFieldStringValue = "PromptShelf_Export_\(Date().formatted(.dateTime.year().month().day()))"
            savePanel.canCreateDirectories = true
            savePanel.isExtensionHidden = false
            
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try data.write(to: url)
                        showExportSuccessAlert = true
                    } catch {
                        errorMessage = "Failed to write to file: \(error.localizedDescription)"
                        showExportErrorAlert = true
                    }
                }
            }
        } catch {
            errorMessage = "Failed to export prompts: \(error.localizedDescription)"
            showExportErrorAlert = true
        }
    }
    
    private func importPrompts() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                do {
                    // Read the data from file
                    let data = try Data(contentsOf: url)
                    
                    // Decode JSON
                    let decoder = JSONDecoder()
                    let importedPrompts = try decoder.decode([UUID: Prompt].self, from: data)
                    
                    // Add to store
                    var addedCount = 0
                    for (id, prompt) in importedPrompts {
                        if store.prompts[id] == nil {
                            store.prompts[id] = prompt
                            addedCount += 1
                        }
                    }
                    
                    // Save changes
                    _ = store.savePrompts()
                    
                    importedPromptCount = addedCount
                    showImportSuccessAlert = true
                } catch {
                    errorMessage = "Failed to import prompts: \(error.localizedDescription)"
                    showImportErrorAlert = true
                }
            }
        }
    }
    
    private func exportAllData() {
        do {
            // Create export data structure with all app data
            struct AppBackup: Codable {
                let prompts: [UUID: Prompt]
                let apiUsageStats: APIUsageStats
                let appVersion: String
                let exportDate: Date
            }
            
            let backup = AppBackup(
                prompts: store.prompts,
                apiUsageStats: store.apiUsageStats,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                exportDate: Date()
            )
            
            // Create JSON data
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(backup)
            
            // Create a save panel
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [UTType.json]
            savePanel.nameFieldStringValue = "PromptShelf_Backup_\(Date().formatted(.dateTime.year().month().day()))"
            savePanel.canCreateDirectories = true
            savePanel.isExtensionHidden = false
            
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try data.write(to: url)
                        showExportSuccessAlert = true
                    } catch {
                        errorMessage = "Failed to write to file: \(error.localizedDescription)"
                        showExportErrorAlert = true
                    }
                }
            }
        } catch {
            errorMessage = "Failed to create backup: \(error.localizedDescription)"
            showExportErrorAlert = true
        }
    }
    
    private func importAllData() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                do {
                    // Read the data from file
                    let data = try Data(contentsOf: url)
                    
                    // Define the backup structure
                    struct AppBackup: Codable {
                        let prompts: [UUID: Prompt]
                        let apiUsageStats: APIUsageStats
                        let appVersion: String
                        let exportDate: Date
                    }
                    
                    // Decode JSON
                    let decoder = JSONDecoder()
                    let backup = try decoder.decode(AppBackup.self, from: data)
                    
                    // Replace all data in the store
                    store.prompts = backup.prompts
                    store.apiUsageStats = backup.apiUsageStats
                    
                    // Save changes
                    _ = store.savePrompts()
                    
                    importedPromptCount = backup.prompts.count
                    showImportSuccessAlert = true
                } catch {
                    errorMessage = "Failed to restore backup: \(error.localizedDescription)"
                    showImportErrorAlert = true
                }
            }
        }
    }
}

// Preview
struct ImportExportView_Previews: PreviewProvider {
    static var previews: some View {
        ImportExportView(store: PromptStore())
    }
} 