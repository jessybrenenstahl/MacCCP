import Foundation

struct PlaylistItem: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let addedAt: Date

    init(url: URL, addedAt: Date = Date()) {
        self.id = UUID()
        self.url = url.standardizedFileURL
        self.addedAt = addedAt
    }

    var title: String {
        url.deletingPathExtension().lastPathComponent
    }

    var filename: String {
        url.lastPathComponent
    }

    var fileExtension: String {
        let ext = url.pathExtension
        return ext.isEmpty ? "file" : ext.uppercased()
    }
}
