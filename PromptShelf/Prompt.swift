import Foundation

struct Prompt: Identifiable, Codable {
    let id: UUID
    var title: String
    var text: String
    var folder: String // Name of the folder it belongs to
    
    init(id: UUID = UUID(), title: String, text: String, folder: String) {
        self.id = id
        self.title = title
        self.text = text
        self.folder = folder
    }
}
