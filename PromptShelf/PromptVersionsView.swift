import SwiftUI

struct PromptVersionsView: View {
    @ObservedObject var store: PromptStore
    let promptID: UUID
    @Binding var isShowing: Bool
    
    // Get the prompt and its versions
    private var prompt: Prompt? {
        store.prompts.first(where: { $0.id == promptID })
    }
    
    private var versions: [PromptVersion] {
        prompt?.versions.sorted(by: { $0.timestamp > $1.timestamp }) ?? []
    }
    
    @State private var selectedVersionID: UUID? = nil
    @State private var notesText: String = ""
    
    var body: some View {
        VStack {
            HStack {
                Text("Saved Versions")
                    .font(.title2.bold())
                
                Spacer()
                
                Button("Close") {
                    isShowing = false
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 10)
            
            if versions.isEmpty {
                Text("No versions available yet")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                HStack(spacing: 0) {
                    // Left side: Version list
                    List(versions, selection: $selectedVersionID) { version in
                        VStack(alignment: .leading) {
                            Text(formatDate(version.timestamp))
                                .font(.headline)
                            
                            HStack {
                                if version.improvedByLLM, let model = version.llmModel {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.blue)
                                    Text("Improved by \(model)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                } else {
                                    Text("Manual edit")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .tag(version.id)
                    }
                    .frame(width: 200)
                    .listStyle(.sidebar)
                    
                    // Right side: Version content
                    if let selectedID = selectedVersionID, 
                       let selectedVersion = versions.first(where: { $0.id == selectedID }) {
                        VStack(alignment: .leading, spacing: 15) {
                            ScrollView {
                                Text(selectedVersion.text)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading) {
                                Text("Notes")
                                    .font(.headline)
                                
                                TextEditor(text: $notesText)
                                    .font(.body)
                                    .padding(5)
                                    .frame(height: 80)
                                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.3)))
                            }
                            
                            HStack {
                                Button("Save Notes") {
                                    saveNotes(for: selectedID)
                                }
                                .disabled(notesText == (selectedVersion.notes ?? ""))
                                
                                Spacer()
                                
                                Button("Restore This Version") {
                                    restoreVersion(selectedVersion)
                                    isShowing = false
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                        .onAppear {
                            notesText = selectedVersion.notes ?? ""
                        }
                    } else {
                        Text("Select a version to view details")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                }
            }
        }
        .padding()
        .frame(width: 700, height: 500)
        .onAppear {
            if !versions.isEmpty && selectedVersionID == nil {
                selectedVersionID = versions.first?.id
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func saveNotes(for versionID: UUID) {
        guard let promptIndex = store.prompts.firstIndex(where: { $0.id == promptID }),
              let versionIndex = store.prompts[promptIndex].versions.firstIndex(where: { $0.id == versionID }) else {
            return
        }
        
        store.prompts[promptIndex].versions[versionIndex].notes = notesText
        store.savePrompts()
    }
    
    private func restoreVersion(_ version: PromptVersion) {
        guard let promptIndex = store.prompts.firstIndex(where: { $0.id == promptID }) else {
            return
        }
        
        // Update the main text
        store.prompts[promptIndex].text = version.text
        
        // Also add as a new version to record the restoration
        let restoredVersion = PromptVersion(
            text: version.text,
            notes: "Restored from version created on \(formatDate(version.timestamp))"
        )
        store.prompts[promptIndex].versions.append(restoredVersion)
        
        store.savePrompts()
    }
} 