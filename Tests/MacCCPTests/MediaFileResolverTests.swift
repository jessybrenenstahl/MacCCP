import XCTest
@testable import MacCCP

final class MediaFileResolverTests: XCTestCase {
    func testResolveExpandsDirectoriesAndFiltersNonMediaFiles() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let nested = root.appendingPathComponent("Nested", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)

        let movie = root.appendingPathComponent("movie.mp4")
        let subtitle = root.appendingPathComponent("notes.txt")
        let episode = nested.appendingPathComponent("episode.mkv")

        try Data("movie".utf8).write(to: movie)
        try Data("notes".utf8).write(to: subtitle)
        try Data("episode".utf8).write(to: episode)

        let resolved = MediaFileResolver.resolve([root])

        XCTAssertEqual(resolved.map(\.lastPathComponent), ["episode.mkv", "movie.mp4"])
    }

    func testResolveDeduplicatesURLs() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let movie = root.appendingPathComponent("movie.mov")
        try Data("movie".utf8).write(to: movie)

        let resolved = MediaFileResolver.resolve([movie, movie])

        XCTAssertEqual(resolved, [movie.standardizedFileURL])
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("CCCPMacPlayerTests-\(UUID().uuidString)", isDirectory: true)

        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
