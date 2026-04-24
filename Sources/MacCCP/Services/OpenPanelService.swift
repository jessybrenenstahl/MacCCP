import AppKit
import UniformTypeIdentifiers

@MainActor
enum OpenPanelService {
    static func chooseMediaURLs() -> [URL] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.resolvesAliases = true
        panel.title = "Open Media"
        panel.prompt = "Open"

        return panel.runModal() == .OK ? panel.urls : []
    }

    static func chooseSubtitleURLs() -> [URL] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.resolvesAliases = true
        panel.allowedContentTypes = ["srt", "ass", "ssa", "vtt", "sub", "idx"].compactMap {
            UTType(filenameExtension: $0)
        }
        panel.title = "Open Subtitle"
        panel.prompt = "Open"

        return panel.runModal() == .OK ? panel.urls : []
    }
}
