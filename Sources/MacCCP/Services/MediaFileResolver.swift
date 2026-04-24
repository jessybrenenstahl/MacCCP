import Foundation

enum MediaFileResolver {
    private static let supportedExtensions: Set<String> = [
        "3g2", "3gp", "aac", "aif", "aiff", "alac", "amr", "avi", "caf",
        "flac", "flv", "m2ts", "m4a", "m4v", "mka", "mkv", "mov", "mp3",
        "mp4", "mpeg", "mpg", "mts", "ogg", "ogv", "opus", "ts", "wav",
        "webm", "wmv"
    ]

    static func resolve(_ urls: [URL]) -> [URL] {
        var resolved: [URL] = []
        var seenPaths = Set<String>()

        for url in urls {
            for mediaURL in expand(url.standardizedFileURL) {
                let key = mediaURL.path
                guard seenPaths.insert(key).inserted else { continue }
                resolved.append(mediaURL)
            }
        }

        return resolved.sorted { lhs, rhs in
            lhs.lastPathComponent.localizedStandardCompare(rhs.lastPathComponent) == .orderedAscending
        }
    }

    static func isPlayableCandidate(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    private static func expand(_ url: URL) -> [URL] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return []
        }

        if isDirectory.boolValue {
            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                return []
            }

            return enumerator.compactMap { item in
                guard let fileURL = item as? URL else { return nil }
                return isPlayableCandidate(fileURL) ? fileURL.standardizedFileURL : nil
            }
        }

        return isPlayableCandidate(url) ? [url.standardizedFileURL] : []
    }
}
