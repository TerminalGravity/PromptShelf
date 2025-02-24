import SwiftUI

struct ContentView: View {
    @StateObject private var store = PromptStore()
    @State private var selectedFolder: String? = nil
    @State private var selectedPrompt: Prompt.ID? = nil
    @State private var newPromptTitle = ""
    @State private var newPromptText = ""
    @State private var newPromptFolder = "General"
    @State private var isEditing = false
    @State private var editedPromptText = ""
    @State private var showFolderPicker = false // For selecting/creating folders
    
    var body: some View {
        NavigationSplitView {
            // Sidebar: Folders
            List(store.folders(), id: \.self, selection: $selectedFolder) { folder in
                Text(folder)
                    .font(.system(.body, design: .rounded))
            }
            .navigationTitle("Folders")
            .frame(minWidth: 150)
        } content: {
            // Middle: Prompt List
            if let folder = selectedFolder {
                List(store.prompts.filter { $0.folder == folder }, selection: $selectedPrompt) { prompt in
                    Text(prompt.title)
                        .font(.system(.body, design: .rounded))
                        .tag(prompt.id)
                }
                .navigationTitle(folder)
                .frame(minWidth: 200)
            } else {
                Text("Select a folder")
                    .foregroundColor(.gray)
            }
        } detail: {
            // Right: Prompt Preview or Edit View
            if let promptID = selectedPrompt,
               let prompt = store.prompts.first(where: { $0.id == promptID }) {
                if isEditing {
                    // Edit Mode
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Title", text: .constant(prompt.title))
                            .textFieldStyle(.roundedBorder)
                            .disabled(true)
                        
                        TextEditor(text: $editedPromptText)
                            .frame(height: 200)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
                        
                        HStack {
                            Spacer()
                            Button("Cancel") {
                                isEditing = false
                                editedPromptText = prompt.text
                            }
                            Button("Save") {
                                if let index = store.prompts.firstIndex(where: { $0.id == promptID }) {
                                    var updatedPrompt = prompt
                                    updatedPrompt.text = editedPromptText
                                    store.prompts[index] = updatedPrompt
                                    store.savePrompts()
                                }
                                isEditing = false
                            }
                            .disabled(editedPromptText.isEmpty)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    // View Mode
                    VStack(alignment: .leading, spacing: 10) {
                        Text(prompt.title)
                            .font(.title2.bold())
                        Text(prompt.text)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(prompt.text, forType: .string)
                            }) {
                                Image(systemName: "doc.on.doc") // Copy icon
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.bordered)
                            .help("Copy prompt to clipboard")
                            
                            Button(action: {
                                isEditing = true
                                editedPromptText = prompt.text
                            }) {
                                Image(systemName: "pencil") // Edit icon
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.bordered)
                            .help("Edit prompt")
                        }
                        .padding(.top, 10)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.windowBackgroundColor)) // Subtle native background
                    .cornerRadius(8)
                    .shadow(radius: 2) // Slight shadow for depth
                }
            } else {
                Text("Select a prompt")
                    .foregroundColor(.gray)
            }
        }
        .toolbar {
            // Add Prompt Button
            ToolbarItem {
                Button(action: { showFolderPicker = true }) { // Changed to open folder picker
                    Image(systemName: "plus")
                }
                .help("Add new prompt")
            }
        }
        .sheet(isPresented: $showFolderPicker) {
            AddPromptView(store: store, onDismiss: { showFolderPicker = false })
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

// New View for Adding Prompts with Folder Selection
struct AddPromptView: View {
    @ObservedObject var store: PromptStore
    @State private var title = ""
    @State private var text = ""
    @State private var folder = "General"
    @State private var newFolderName = "" // For creating a new folder
    @State private var isCreatingNewFolder = false
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Add New Prompt")
                .font(.headline)
            
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            
            TextEditor(text: $text)
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
            
            if isCreatingNewFolder {
                // Create New Folder Input
                TextField("New Folder Name", text: $newFolderName)
                    .textFieldStyle(.roundedBorder)
                
                Button("Create Folder") {
                    if !newFolderName.isEmpty {
                        folder = newFolderName
                        isCreatingNewFolder = false
                    }
                }
                .buttonStyle(.bordered)
            } else {
                // Select Existing Folder or Create New
                Picker("Folder", selection: $folder) {
                    ForEach(store.folders(), id: \.self) { folderName in
                        Text(folderName).tag(folderName)
                    }
                    Text("Create New Folder...").tag("new")
                }
                .pickerStyle(.menu)
                
                Button("Create New Folder") {
                    isCreatingNewFolder = true
                }
                .buttonStyle(.bordered)
            }
            
            HStack {
                Spacer()
                Button("Cancel") { onDismiss() }
                Button("Save") {
                    if !title.isEmpty && !text.isEmpty {
                        store.addPrompt(title: title, text: text, folder: folder)
                        title = ""
                        text = ""
                        onDismiss()
                    }
                }
                .disabled(title.isEmpty || text.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}
