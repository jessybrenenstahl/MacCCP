import Foundation

final class PlaybackHistoryStore {
    private struct Snapshot: Codable {
        var positions: [String: Double]
    }

    private let fileURL: URL
    private var positions: [String: Double]

    init(fileManager: FileManager = .default) {
        let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("CCCP Mac Player", isDirectory: true)

        let directory = supportURL ?? URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("CCCP Mac Player", isDirectory: true)

        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("playback-history.json")

        if let data = try? Data(contentsOf: fileURL),
           let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) {
            positions = snapshot.positions
        } else {
            positions = [:]
        }
    }

    func position(for url: URL) -> Double {
        positions[key(for: url)] ?? 0
    }

    func setPosition(_ seconds: Double, for url: URL) {
        guard seconds.isFinite, seconds > 0 else { return }
        positions[key(for: url)] = seconds
        persist()
    }

    func clearPosition(for url: URL) {
        positions.removeValue(forKey: key(for: url))
        persist()
    }

    private func key(for url: URL) -> String {
        url.standardizedFileURL.path
    }

    private func persist() {
        let snapshot = Snapshot(positions: positions)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
