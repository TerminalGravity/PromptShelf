import SwiftUI
import Foundation
import Combine

struct PromptVersionsView: View {
    @ObservedObject var store: PromptStore
    let promptID: UUID
    @Binding var isShowing: Bool
    
    // Get the prompt and its versions
    private var prompt: Prompt? {
        store.prompts[promptID]
    }
    
    private var versions: [PromptVersion] {
        prompt?.versions.sorted(by: { $0.timestamp > $1.timestamp }) ?? []
    }
    
    @State private var selectedVersionID: UUID? = nil
    @State private var notesText: String = ""
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var showConfirmDelete: Bool = false
    @State private var compareMode: Bool = false
    @State private var compareVersionID: UUID? = nil
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .info
    
    // Environment support for dark mode
    @Environment(\.colorScheme) private var colorScheme
    
    // Computed properties for theme-aware colors
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.white
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.6) : Color.gray.opacity(0.1)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
    
    // Filtered versions based on search
    private var filteredVersions: [PromptVersion] {
        if searchText.isEmpty {
            return versions
        } else {
            return versions.filter { version in
                let hasTextMatch = version.text.localizedCaseInsensitiveContains(searchText)
                let hasNotesMatch = version.notes?.localizedCaseInsensitiveContains(searchText) ?? false
                let hasModelMatch = version.llmModel?.localizedCaseInsensitiveContains(searchText) ?? false
                
                return hasTextMatch || hasNotesMatch || hasModelMatch
            }
        }
    }
    
    // Selected version
    private var selectedVersion: PromptVersion? {
        if let id = selectedVersionID {
            return versions.first(where: { $0.id == id })
        }
        return nil
    }
    
    // Compare version
    private var compareVersion: PromptVersion? {
        if let id = compareVersionID {
            return versions.first(where: { $0.id == id })
        }
        return nil
    }
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Prompt Version History")
                    .font(.title2.bold())
                    .foregroundColor(textColor)
                
                Spacer()
                
                Button("Close") {
                    isShowing = false
                }
                .buttonStyle(.bordered)
            }
            .padding(.bottom, 10)
            
            // Search and Compare toggles
            HStack {
                if !versions.isEmpty {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(secondaryTextColor)
                        
                        TextField("Search in versions", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                            .foregroundColor(textColor)
                    }
                    
                    Spacer()
                    
                    if versions.count > 1 {
                        Toggle("Compare Mode", isOn: $compareMode)
                            .toggleStyle(SwitchToggleStyle())
                            .foregroundColor(textColor)
                            .onChange(of: compareMode) { newValue in
                                if !newValue {
                                    compareVersionID = nil
                                }
                            }
                    }
                }
            }
            .padding(.bottom, 5)
            
            if versions.isEmpty {
                // Empty state
                Text("No versions available yet")
                    .foregroundColor(secondaryTextColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                HStack(spacing: 0) {
                    // Left side: Version list
                    VStack {
                        List(filteredVersions, selection: compareMode ? $compareVersionID : $selectedVersionID) { version in
                            VersionListRow(
                                version: version, 
                                isSelected: (compareMode ? compareVersionID : selectedVersionID) == version.id,
                                formatDate: formatDate,
                                colorScheme: colorScheme
                            )
                            .tag(version.id)
                            .contextMenu {
                                Button(action: {
                                    Task {
                                        await restoreVersion(version)
                                        isShowing = false
                                    }
                                }) {
                                    Label("Restore", systemImage: "arrow.clockwise")
                                }
                                
                                Button(action: {
                                    copyToClipboard(version.text)
                                    displayToast(message: "Copied to clipboard", type: .success)
                                }) {
                                    Label("Copy to Clipboard", systemImage: "doc.on.doc")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive, action: {
                                    selectedVersionID = version.id
                                    showConfirmDelete = true
                                }) {
                                    Label("Delete Version", systemImage: "trash")
                                }
                            }
                        }
                        .listStyle(.sidebar)
                        .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.clear)
                        
                        // Comparison selector (only shown in compare mode)
                        if compareMode {
                            HStack {
                                Text("Select version to compare with")
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor)
                                    .padding(5)
                            }
                            .frame(maxWidth: .infinity)
                            .background(colorScheme == .dark ? Color.black.opacity(0.4) : Color.secondary.opacity(0.1))
                            .cornerRadius(5)
                            .padding(.horizontal, 5)
                            .padding(.bottom, 5)
                        }
                    }
                    .frame(width: 220)
                    
                    // Right side: Version content
                    if compareMode && compareVersionID != nil && selectedVersionID != nil && compareVersionID != selectedVersionID {
                        // Comparison view
                        ComparisonView(
                            version1: selectedVersion!,
                            version2: compareVersion!,
                            formatDate: formatDate,
                            colorScheme: colorScheme,
                            onRestore: { version in
                                Task {
                                    await restoreVersion(version)
                                    isShowing = false
                                }
                            }
                        )
                    } else if let selectedVersion = selectedVersion {
                        // Standard view
                        VStack(alignment: .leading, spacing: 15) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(formatDate(selectedVersion.timestamp))
                                    .font(.headline)
                                    .foregroundColor(textColor)
                                
                                HStack {
                                    if selectedVersion.improvedByLLM, let model = selectedVersion.llmModel {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(.blue)
                                        Text("Improved by \(model)")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    } else {
                                        Text("Manual edit")
                                            .font(.caption)
                                            .foregroundColor(secondaryTextColor)
                                    }
                                }
                            }
                            .padding(.bottom, 5)
                            
                            // Prompt content
                            ScrollView {
                                Text(selectedVersion.text)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(cardBackgroundColor)
                                    .cornerRadius(8)
                                    .foregroundColor(textColor)
                            }
                            
                            Divider()
                            
                            // Notes section
                            VStack(alignment: .leading) {
                                Text("Notes")
                                    .font(.headline)
                                    .foregroundColor(textColor)
                                
                                TextEditor(text: $notesText)
                                    .font(.body)
                                    .padding(5)
                                    .frame(height: 80)
                                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray.opacity(0.3)))
                                    .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.clear)
                                    .foregroundColor(textColor)
                            }
                            
                            // Action buttons
                            HStack {
                                Button("Save Notes") {
                                    Task {
                                        await saveNotes(for: selectedVersion.id)
                                    }
                                }
                                .disabled(notesText == (selectedVersion.notes ?? ""))
                                
                                Spacer()
                                
                                Button("Copy to Clipboard") {
                                    copyToClipboard(selectedVersion.text)
                                    displayToast(message: "Copied to clipboard", type: .success)
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Restore This Version") {
                                    Task {
                                        await restoreVersion(selectedVersion)
                                        isShowing = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                        .onAppear {
                            notesText = selectedVersion.notes ?? ""
                        }
                        .onChange(of: selectedVersionID) { newValue in
                            if let id = newValue, let version = versions.first(where: { $0.id == id }) {
                                notesText = version.notes ?? ""
                            }
                        }
                    } else {
                        Text("Select a version to view details")
                            .foregroundColor(secondaryTextColor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                }
            }
        }
        .padding()
        .frame(width: 800, height: 550)
        .background(backgroundColor)
        .onAppear {
            if !versions.isEmpty && selectedVersionID == nil {
                selectedVersionID = versions.first?.id
            }
        }
        .alert("Delete Version", isPresented: $showConfirmDelete) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let versionID = selectedVersionID {
                    Task {
                        await deleteVersion(versionID)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this version? This action cannot be undone.")
        }
        .overlay(
            Group {
                if showToast {
                    ToastView(
                        message: toastMessage,
                        type: toastType,
                        isShowing: $showToast
                    )
                }
            }
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func saveNotes(for versionID: UUID) async {
        guard let prompt = prompt,
              let versionIndex = prompt.versions.firstIndex(where: { $0.id == versionID }) else {
            await MainActor.run {
                displayToast(message: "Cannot save notes", type: .error)
            }
            return
        }
        
        // Use Task to handle async operations
        await Task {
            // Create a mutable copy of the prompt
            var updatedPrompt = prompt
            updatedPrompt.versions[versionIndex].notes = notesText
            
            // Save the updated prompt
            let success = store.savePrompt(updatedPrompt)
            
            if success {
                store.savePrompts()
                await MainActor.run {
                    displayToast(message: "Notes saved successfully", type: .success)
                }
            } else {
                await MainActor.run {
                    displayToast(message: "Failed to save notes", type: .error)
                }
            }
        }.value
    }
    
    private func restoreVersion(_ version: PromptVersion) async {
        let success = await Task<Bool, Never> {
            return store.savePromptVersion(
                id: promptID,
                text: version.text,
                notes: "Restored from version created on \(formatDate(version.timestamp))"
            )
        }.value
        
        await MainActor.run {
            if success {
                displayToast(message: "Version restored successfully", type: .success)
            } else {
                displayToast(message: "Failed to restore version", type: .error)
            }
        }
    }
    
    private func deleteVersion(_ versionID: UUID) async {
        guard let prompt = prompt,
              prompt.versions.count > 1, // Don't allow deleting the last version
              let versionIndex = prompt.versions.firstIndex(where: { $0.id == versionID }) else {
            await MainActor.run {
                displayToast(message: "Cannot delete version", type: .error)
            }
            return
        }
        
        await Task {
            // Create a mutable copy of the prompt
            var updatedPrompt = prompt
            updatedPrompt.versions.remove(at: versionIndex)
            
            // Save the updated prompt
            let success = store.savePrompt(updatedPrompt)
            
            await MainActor.run {
                if success {
                    // Update selectedVersionID if needed
                    if selectedVersionID == versionID {
                        selectedVersionID = updatedPrompt.versions.first?.id
                    }
                    
                    store.savePrompts()
                    displayToast(message: "Version deleted", type: .success)
                } else {
                    displayToast(message: "Failed to delete version", type: .error)
                }
            }
        }.value
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    /// Displays a toast notification and posts a notification for app-wide toast system
    private func displayToast(message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        showToast = true
        
        // Automatically hide toast after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                showToast = false
            }
        }
        
        // Also post notification for app-wide toast system
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowToast"),
            object: nil,
            userInfo: ["message": message, "type": type.rawValue]
        )
    }
}

// MARK: - Helper Views

struct VersionListRow: View {
    let version: PromptVersion
    let isSelected: Bool
    let formatDate: (Date) -> String
    let colorScheme: ColorScheme
    
    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
    
    private var highlightColor: Color {
        colorScheme == .dark ? Color.blue.opacity(0.3) : Color.accentColor.opacity(0.1)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(formatDate(version.timestamp))
                .font(.headline)
                .foregroundColor(isSelected ? .accentColor : textColor)
            
            HStack {
                if version.improvedByLLM, let model = version.llmModel {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                    
                    Text(model.contains("-") ? model.split(separator: "-").last.map(String.init) ?? model : model)
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Text("Manual edit")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                }
            }
            
            if let notes = version.notes, !notes.isEmpty {
                Text(notes.prefix(30) + (notes.count > 30 ? "..." : ""))
                    .font(.caption2)
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 5)
        .background(isSelected ? highlightColor : Color.clear)
        .cornerRadius(4)
    }
}

struct ComparisonView: View {
    let version1: PromptVersion
    let version2: PromptVersion
    let formatDate: (Date) -> String
    let colorScheme: ColorScheme
    var onRestore: (PromptVersion) -> Void
    
    @State private var showDiff: Bool = true
    @State private var syncScrolling: Bool = true
    @State private var scrollOffset: CGFloat = 0
    
    // Computed properties for theme colors
    private var textColor: Color {
        colorScheme == .dark ? Color.white : Color.primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.secondary
    }
    
    private var olderBackgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.6) : Color.gray.opacity(0.1)
    }
    
    private var newerBackgroundColor: Color {
        colorScheme == .dark ? Color.blue.opacity(0.15) : Color.blue.opacity(0.05)
    }
    
    private var addedTextColor: Color {
        colorScheme == .dark ? Color.green : Color.green.opacity(0.8)
    }
    
    private var removedTextColor: Color {
        colorScheme == .dark ? Color.red : Color.red.opacity(0.8)
    }
    
    private var addedBackgroundColor: Color {
        colorScheme == .dark ? Color.green.opacity(0.15) : Color.green.opacity(0.1)
    }
    
    private var removedBackgroundColor: Color {
        colorScheme == .dark ? Color.red.opacity(0.15) : Color.red.opacity(0.1)
    }
    
    // Which version is newer
    private var newerVersion: PromptVersion {
        version1.timestamp > version2.timestamp ? version1 : version2
    }
    
    private var olderVersion: PromptVersion {
        version1.timestamp > version2.timestamp ? version2 : version1
    }
    
    // Diff calculation
    private var diff: [(String, DiffType)] {
        calculateDiff(oldText: olderVersion.text, newText: newerVersion.text)
    }
    
    // Diff types
    private enum DiffType {
        case same
        case added
        case removed
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Comparing Versions")
                    .font(.headline)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Toggle("Show Differences", isOn: $showDiff)
                    .toggleStyle(SwitchToggleStyle())
                    .foregroundColor(textColor)
                    .help("Highlight added and removed content")
                
                Toggle("Sync Scrolling", isOn: $syncScrolling)
                    .toggleStyle(SwitchToggleStyle())
                    .foregroundColor(textColor)
                    .help("Scroll both versions together")
                    .disabled(!showDiff)
            }
            .padding(.bottom, 5)
            
            // Version info headers
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("Earlier: " + formatDate(olderVersion.timestamp))
                        .font(.subheadline)
                        .foregroundColor(textColor)
                    
                    if olderVersion.improvedByLLM, let model = olderVersion.llmModel {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                                .font(.caption)
                            
                            Text("Improved by " + model)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Later: " + formatDate(newerVersion.timestamp))
                        .font(.subheadline)
                        .foregroundColor(textColor)
                    
                    if newerVersion.improvedByLLM, let model = newerVersion.llmModel {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                                .font(.caption)
                            
                            Text("Improved by " + model)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(.bottom, 5)
            
            // Legend for diff coloring (only show when diff is enabled)
            if showDiff {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(removedBackgroundColor)
                            .frame(width: 12, height: 12)
                            .overlay(Rectangle().stroke(removedTextColor, lineWidth: 1))
                        
                        Text("Removed")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(addedBackgroundColor)
                            .frame(width: 12, height: 12)
                            .overlay(Rectangle().stroke(addedTextColor, lineWidth: 1))
                        
                        Text("Added")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 5)
            }
            
            // Split view for comparison
            HStack(spacing: 10) {
                // Left side (older version)
                if showDiff {
                    // Diff view for older version
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(diff.enumerated()), id: \.offset) { index, item in
                                if item.1 != .added {
                                    Text(item.0)
                                        .font(.body)
                                        .foregroundColor(item.1 == .removed ? removedTextColor : textColor)
                                        .padding(4)
                                        .background(item.1 == .removed ? removedBackgroundColor : Color.clear)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(olderBackgroundColor)
                        .cornerRadius(8)
                    }
                    .onChange(of: scrollOffset) { newValue in
                        if syncScrolling {
                            // This would be implemented with a ScrollViewReader in a real app
                        }
                    }
                } else {
                    // Regular view for older version
                    ScrollView {
                        Text(olderVersion.text)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(olderBackgroundColor)
                            .cornerRadius(8)
                            .foregroundColor(textColor)
                    }
                }
                
                // Divider
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(secondaryTextColor.opacity(0.5))
                
                // Right side (newer version)
                if showDiff {
                    // Diff view for newer version
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(diff.enumerated()), id: \.offset) { index, item in
                                if item.1 != .removed {
                                    Text(item.0)
                                        .font(.body)
                                        .foregroundColor(item.1 == .added ? addedTextColor : textColor)
                                        .padding(4)
                                        .background(item.1 == .added ? addedBackgroundColor : Color.clear)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(newerBackgroundColor)
                        .cornerRadius(8)
                    }
                    .onChange(of: scrollOffset) { newValue in
                        if syncScrolling {
                            // This would be implemented with a ScrollViewReader in a real app
                        }
                    }
                } else {
                    // Regular view for newer version
                    ScrollView {
                        Text(newerVersion.text)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(newerBackgroundColor)
                            .cornerRadius(8)
                            .foregroundColor(textColor)
                    }
                }
            }
            
            // Action buttons
            HStack {
                Button("Restore Earlier Version") {
                    onRestore(olderVersion)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Copy Differences") {
                    let diffText = generateDiffSummary(oldText: olderVersion.text, newText: newerVersion.text)
                    copyToClipboard(diffText)
                    
                    // Use NotificationCenter to show toast
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowToast"),
                        object: nil,
                        userInfo: ["message": "Differences copied to clipboard", "type": ToastType.success.rawValue]
                    )
                }
                .buttonStyle(.bordered)
                .disabled(!showDiff)
                
                Button("Restore Later Version") {
                    onRestore(newerVersion)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top)
        }
        .padding()
        .animation(.easeInOut(duration: 0.3), value: showDiff)
    }
    
    // Copy text to clipboard
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    // Calculate a character-by-character diff between two strings
    private func calculateDiff(oldText: String, newText: String) -> [(String, DiffType)] {
        // Split by lines first to maintain readability
        let oldLines = oldText.components(separatedBy: .newlines)
        let newLines = newText.components(separatedBy: .newlines)
        
        var result: [(String, DiffType)] = []
        
        // Basic line comparison (could be improved with a more sophisticated diff algorithm)
        var i = 0
        var j = 0
        
        while i < oldLines.count || j < newLines.count {
            if i < oldLines.count && j < newLines.count && oldLines[i] == newLines[j] {
                // Lines are identical
                result.append((oldLines[i], .same))
                i += 1
                j += 1
            } else {
                // Try to find the next matching line
                var foundMatch = false
                
                // Look ahead in the new lines
                for k in 0..<3 {
                    if i < oldLines.count && j + k < newLines.count && oldLines[i] == newLines[j + k] {
                        // Added lines before the match
                        for m in 0..<k {
                            result.append((newLines[j + m], .added))
                        }
                        result.append((oldLines[i], .same))
                        i += 1
                        j += k + 1
                        foundMatch = true
                        break
                    }
                }
                
                if !foundMatch {
                    // Look ahead in the old lines
                    for k in 0..<3 {
                        if i + k < oldLines.count && j < newLines.count && oldLines[i + k] == newLines[j] {
                            // Removed lines before the match
                            for m in 0..<k {
                                result.append((oldLines[i + m], .removed))
                            }
                            result.append((newLines[j], .same))
                            i += k + 1
                            j += 1
                            foundMatch = true
                            break
                        }
                    }
                }
                
                if !foundMatch {
                    // No match found nearby, assume one line was modified
                    if i < oldLines.count {
                        result.append((oldLines[i], .removed))
                        i += 1
                    }
                    if j < newLines.count {
                        result.append((newLines[j], .added))
                        j += 1
                    }
                }
            }
        }
        
        return result
    }
    
    // Generate a human-readable summary of differences
    private func generateDiffSummary(oldText: String, newText: String) -> String {
        let diff = calculateDiff(oldText: oldText, newText: newerVersion.text)
        var summary = "Differences between versions:\n\n"
        
        for (text, type) in diff {
            switch type {
            case .same:
                continue // Skip unchanged content in the summary
            case .added:
                summary += "+ \(text)\n"
            case .removed:
                summary += "- \(text)\n"
            }
        }
        
        return summary
    }
}

// MARK: - ToastView
/// A view that displays toast notifications with different styles based on type
extension PromptVersionsView {
    struct ToastView: View {
        let message: String
        let type: ToastType
        @Binding var isShowing: Bool
        
        @Environment(\.colorScheme) private var colorScheme
        
        private var backgroundColor: Color {
            colorScheme == .dark ? Color(.windowBackgroundColor).opacity(0.95) : Color(.windowBackgroundColor)
        }
        
        private var textColor: Color {
            colorScheme == .dark ? Color.white : Color.primary
        }
        
        var body: some View {
            VStack {
                Spacer()
                
                HStack {
                    Image(systemName: type.iconName)
                        .foregroundColor(type.color)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(message)
                        .foregroundColor(textColor)
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isShowing = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(backgroundColor)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(type.color, lineWidth: 1)
                )
                .padding()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: isShowing)
        }
    }
}

// No duplicate structs needed - they've been properly implemented above 