import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var store = PromptStore()
    @State private var selectedFolder: String? = nil
    @State private var selectedPrompt: Prompt.ID? = nil
    @State private var selectedPromptType: PromptType = .general
    @State private var newPromptTitle = ""
    @State private var newPromptText = ""
    @State private var newPromptFolder = "General"
    @State private var isEditing = false
    @State private var editedPromptText = ""
    @State private var showFolderPicker = false
    @State private var showVersionsView = false
    @State private var showImproveView = false
    @State private var showPromptFixView = false
    @State private var showPlannerView = false
    @State private var showSettingsView = false
    @State private var isShowingSettings = false
    @State private var isImproving = false
    @State private var useReasoningMode = false
    @State private var showsReasoningToast = false
    @State private var showImportExportView = false
    
    var body: some View {
        NavigationSplitView {
            sidebarView
        } content: {
            promptListView
        } detail: {
            detailView
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showFolderPicker = true }) {
                    Image(systemName: "plus")
                }
                .help("Add new prompt")
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showImportExportView = true }) {
                    Image(systemName: "square.and.arrow.up.on.square")
                }
                .help("Import/Export")
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showSettingsView = true }) {
                    Image(systemName: "gear")
                }
                .help("Settings")
            }
        }
        .sheet(isPresented: $showFolderPicker) {
            AddPromptView(store: store, onDismiss: { showFolderPicker = false })
        }
        .sheet(isPresented: $showImportExportView) {
            ImportExportView(store: store)
        }
        .sheet(isPresented: $showSettingsView) {
            ZStack {
                Text("Settings")
                    .font(.title)
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showSettingsView = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                        .padding()
                    }
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showVersionsView) {
            if let promptID = selectedPrompt {
                PromptVersionsView(store: store, promptID: promptID, isShowing: $showVersionsView)
            }
        }
        .sheet(isPresented: $showImproveView) {
            if let promptID = selectedPrompt {
                PromptImproveView(store: store, promptID: promptID, isShowing: $showImproveView)
            }
        }
        .sheet(isPresented: $showPromptFixView) {
            if let promptID = selectedPrompt {
                PromptFixView(store: store, promptID: promptID, isShowing: $showPromptFixView)
            }
        }
        .sheet(isPresented: $showPlannerView) {
            if let promptID = selectedPrompt {
                PromptPlannerView(store: store, promptID: promptID, isShowing: $showPlannerView)
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .overlay(
            Group {
                if showsReasoningToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "brain.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 18))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reasoning Mode Enabled")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("The model will explain its thought process when improving your prompt")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: { showsReasoningToast = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.windowBackgroundColor))
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showsReasoningToast)
                }
            }
        )
    }
    
    // MARK: - Sidebar View
    private var sidebarView: some View {
        VStack {
            // Types section
            Section {
                List(PromptType.allCases, id: \.self, selection: $selectedPromptType) { type in
                    HStack {
                        TypeIcon(type: type)
                        Text(type.rawValue)
                            .font(.system(.body, design: .rounded))
                    }
                    .tag(type)
                }
            } header: {
                Text("Categories")
                    .font(.headline)
                    .padding(.leading, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Divider()
            
            // Folders section
            Section {
                List(store.folders(), id: \.self, selection: $selectedFolder) { folder in
                    Text(folder)
                        .font(.system(.body, design: .rounded))
                }
            } header: {
                Text("Folders")
                    .font(.headline)
                    .padding(.leading, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 180)
    }
    
    // MARK: - Prompt List View
    private var promptListView: some View {
        VStack {
            if selectedFolder != nil {
                folderPromptsView
            } else {
                typePromptsView
            }
        }
        .frame(minWidth: 200)
    }
    
    private var folderPromptsView: some View {
        let folderPrompts = store.prompts.values.filter { $0.folder == selectedFolder }
        
        return Group {
            if !folderPrompts.isEmpty {
                List(folderPrompts, selection: $selectedPrompt) { prompt in
                    Text(prompt.title)
                        .font(.system(.body, design: .rounded))
                        .tag(prompt.id)
                }
                .navigationTitle(selectedFolder ?? "")
            } else {
                Text("No prompts in this folder")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var typePromptsView: some View {
        let typePrompts = Array(store.prompts.values.filter { $0.type == selectedPromptType })
        
        return Group {
            if !typePrompts.isEmpty {
                List(typePrompts, selection: $selectedPrompt) { prompt in
                    Text(prompt.title)
                        .font(.system(.body, design: .rounded))
                        .tag(prompt.id)
                }
                .navigationTitle(selectedPromptType.rawValue)
            } else {
                Text("No \(selectedPromptType.rawValue) prompts")
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Detail View
    private var detailView: some View {
        Group {
            if let promptID = selectedPrompt, 
               let prompt = store.prompts[promptID] {
                if isEditing {
                    promptEditView(prompt: prompt, promptID: promptID)
                } else {
                    promptViewMode(prompt: prompt, promptID: promptID)
                }
            }
        }
        .frame(minWidth: 200)
    }
    
    private func promptEditView(prompt: Prompt, promptID: UUID) -> some View {
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
                    if var prompt = store.prompts[promptID] {
                        prompt.text = editedPromptText
                        store.prompts[promptID] = prompt
                    }
                    isEditing = false
                }
                .disabled(editedPromptText.isEmpty)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func promptViewMode(prompt: Prompt, promptID: UUID) -> some View {
        VStack {
            promptHeader(prompt: prompt)
            
            promptContent(prompt: prompt)
            
            promptActionButtons(prompt: prompt)
            
            LLMActionButtons(promptID: promptID)
        }
    }
    
    private func promptHeader(prompt: Prompt) -> some View {
        HStack {
            Text(prompt.title)
                .font(.title2.bold())
            
            Spacer()
            
            TypeTag(type: prompt.type)
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private func promptContent(prompt: Prompt) -> some View {
        ScrollView {
            Text(prompt.text)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
        }
        .padding(.horizontal)
    }
    
    private func promptActionButtons(prompt: Prompt) -> some View {
        HStack {
            Group {
                // Show specialized improvement options based on prompt type
                switch prompt.type {
                case .cursorFix:
                    Button(action: {
                        showPromptFixView = true
                    }) {
                        Label("Cursor Fix", systemImage: "cursorarrow.rays")
                    }
                    .help("Use Cursor Fix workflow to improve this prompt")
                    
                case .plannerMode:
                    Button(action: {
                        showPlannerView = true
                    }) {
                        Label("Planner Mode", systemImage: "chart.bar.doc.horizontal")
                    }
                    .help("Use Planner Mode workflow to improve this prompt")
                    
                default:
                    Button(action: {
                        showImproveView = true
                    }) {
                        Label("Improve", systemImage: "sparkles")
                    }
                    .help("Improve with LLM")
                }
            }
            
            Button(action: {
                showVersionsView = true
            }) {
                Label("Versions", systemImage: "clock.arrow.circlepath")
            }
            .help("View saved versions")
            
            Spacer()
            
            Button(action: {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(prompt.text, forType: .string)
            }) {
                Image(systemName: "doc.on.doc")
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.bordered)
            .help("Copy prompt to clipboard")
            
            Button(action: {
                isEditing = true
                editedPromptText = prompt.text
            }) {
                Image(systemName: "pencil")
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.bordered)
            .help("Edit prompt")
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private func LLMActionButtons(promptID: UUID) -> some View {
        HStack {
            if store.selectedLLMModel.hasReasoningCapability {
                Toggle("Use reasoning", isOn: $useReasoningMode)
                    .toggleStyle(SwitchToggleStyle())
                    .help("When enabled, the AI will explain its reasoning process when improving the prompt")
                    .onChange(of: useReasoningMode) { _, newValue in
                        if newValue {
                            showsReasoningToast = true
                            // Display toast for 4 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                showsReasoningToast = false
                            }
                        }
                    }
            }
            
            Button(action: {
                improveWithLLM(promptId: promptID)
            }) {
                HStack {
                    Group {
                        if isImproving {
                            ProgressView()
                                .scaleEffect(0.7)
                                .padding(.trailing, 2)
                        }
                    }
                    Text("Improve with \(store.selectedLLMModel.displayName)")
                        .fontWeight(.medium)
                }
                .frame(height: 24)
            }
            .disabled(isImproving || store.getAPIKey(service: store.selectedLLMModel.rawValue) == nil)
            .help(store.getAPIKey(service: store.selectedLLMModel.rawValue) == nil ? "Please set an API key in settings" : "Improve this prompt using AI")
        }
        .padding(.horizontal)
        .padding(.bottom, 5)
    }
    
    private func improveWithLLM(promptId: UUID) {
        isImproving = true
        
        // Setup notification observers for processing events
        let notificationCenter = NotificationCenter.default
        
        // Observer for processing started
        let startObserver = notificationCenter.addObserver(
            forName: NSNotification.Name("LLMProcessingStarted"),
            object: nil,
            queue: .main
        ) { _ in
            // Already set isImproving = true above
        }
        
        // Observer for processing failed
        let failObserver = notificationCenter.addObserver(
            forName: NSNotification.Name("LLMProcessingFailed"),
            object: nil,
            queue: .main
        ) { notification in
            let errorMessage = (notification.userInfo?["error"] as? String) ?? "Unknown error"
            
            // Display error notification using UserNotifications framework
            let content = UNMutableNotificationContent()
            content.title = "Prompt Improvement Failed"
            content.body = errorMessage
            content.sound = UNNotificationSound.default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
            
            isImproving = false
        }
        
        // Call improve function with reasoning mode parameter
        store.improvePromptWithLLM(promptID: promptId, useReasoning: useReasoningMode) { result in
            isImproving = false
            
            // Remove notification observers
            notificationCenter.removeObserver(startObserver)
            notificationCenter.removeObserver(failObserver)
            
            if case let .failure(error) = result {
                let errorMessage = error.localizedDescription
                // Create and show an error alert using UserNotifications framework
                let content = UNMutableNotificationContent()
                content.title = "Prompt Improvement Failed"
                content.body = errorMessage
                content.sound = UNNotificationSound.default
                
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
}

// Helper Views
struct TypeIcon: View {
    let type: PromptType
    
    var body: some View {
        Image(systemName: iconName)
            .foregroundColor(iconColor)
    }
    
    private var iconName: String {
        switch type {
        case .general:
            return "doc.text"
        case .cursorFix:
            return "cursorarrow.rays"
        case .plannerMode:
            return "chart.bar.doc.horizontal"
        case .chatbot:
            return "bubble.left.and.bubble.right"
        case .creative:
            return "paintbrush"
        case .technical:
            return "terminal"
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .general:
            return .blue
        case .cursorFix:
            return .green
        case .plannerMode:
            return .purple
        case .chatbot:
            return .orange
        case .creative:
            return .pink
        case .technical:
            return .gray
        }
    }
}

struct TypeTag: View {
    let type: PromptType
    
    var body: some View {
        Text(type.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tagColor.opacity(0.2))
            .foregroundColor(tagColor)
            .cornerRadius(4)
    }
    
    private var tagColor: Color {
        switch type {
        case .general:
            return .blue
        case .cursorFix:
            return .green
        case .plannerMode:
            return .purple
        case .chatbot:
            return .orange
        case .creative:
            return .pink
        case .technical:
            return .gray
        }
    }
}


// Keep the existing AddPromptView with a minor update to add PromptType
struct AddPromptView: View {
    @ObservedObject var store: PromptStore
    @State private var title = ""
    @State private var text = ""
    @State private var folder = "General"
    @State private var promptType: PromptType = .general
    @State private var newFolderName = ""
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
            
            // Prompt Type picker
            Picker("Prompt Type", selection: $promptType) {
                ForEach(PromptType.allCases, id: \.self) { type in
                    HStack {
                        TypeIcon(type: type)
                        Text(type.rawValue)
                    }.tag(type)
                }
            }
            .pickerStyle(.menu)
            
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
                    // Ensure "General" is always in the list
                    if !store.folders().contains("General") {
                        Text("General").tag("General")
                    }
                    ForEach(store.folders(), id: \.self) { folderName in
                        Text(folderName).tag(folderName)
                    }
                    Text("Create New Folder...").tag("new")
                }
                .pickerStyle(.menu)
                .onChange(of: folder) { _, newValue in
                    if newValue == "new" {
                        isCreatingNewFolder = true
                        newFolderName = ""
                    }
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel") { onDismiss() }
                Button("Save") {
                    if !title.isEmpty && !text.isEmpty {
                        store.addPrompt(title: title, text: text, folder: folder, type: promptType)
                        title = ""
                        text = ""
                        onDismiss()
                    }
                }
                .disabled(title.isEmpty || text.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 400)
    }
}

