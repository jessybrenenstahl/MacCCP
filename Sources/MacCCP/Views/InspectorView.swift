import SwiftUI

struct InspectorView: View {
    @ObservedObject var store: PlayerStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let item = store.selectedItem {
                    fileSection(item)
                    playbackSection
                    tracksSection
                } else {
                    Text("No media selected")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .background(.regularMaterial)
    }

    private func fileSection(_ item: PlaylistItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("File", systemImage: "doc")
                .font(.headline)

            Text(item.filename)
                .font(.callout.weight(.medium))
                .lineLimit(3)
                .textSelection(.enabled)

            Text(item.url.deletingLastPathComponent().path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .textSelection(.enabled)

            HStack {
                Text(item.fileExtension)
                Spacer()
                Text(fileSize(for: item.url))
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Button {
                store.revealSelectedInFinder()
            } label: {
                Label("Reveal in Finder", systemImage: "magnifyingglass")
            }
            .controlSize(.small)
        }
    }

    private var playbackSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Playback", systemImage: "timeline.selection")
                .font(.headline)

            HStack {
                Text("Position")
                Spacer()
                Text("\(PlayerTimeFormatter.string(from: store.currentTime)) / \(PlayerTimeFormatter.string(from: store.duration))")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Speed")
                Spacer()
                Text("\(store.playbackRate.formatted())x")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Queue")
                Spacer()
                Text("\((store.selectedIndex ?? 0) + 1) of \(store.playlist.count)")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.callout)
    }

    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tracks", systemImage: "captions.bubble")
                .font(.headline)

            Picker("Audio", selection: audioSelectionBinding) {
                if store.audioTracks.isEmpty {
                    Text("Default").tag(String?.none)
                } else {
                    ForEach(store.audioTracks) { track in
                        Text(track.title).tag(Optional(track.id))
                    }
                }
            }

            Picker("Subtitles", selection: subtitleSelectionBinding) {
                ForEach(store.subtitleTracks) { track in
                    Text(track.title).tag(track.id)
                }
            }
        }
    }

    private var audioSelectionBinding: Binding<String?> {
        Binding {
            store.selectedAudioTrackID
        } set: { newValue in
            if let newValue {
                store.selectAudioTrack(id: newValue)
            }
        }
    }

    private var subtitleSelectionBinding: Binding<String> {
        Binding {
            store.selectedSubtitleTrackID
        } set: { newValue in
            store.selectSubtitleTrack(id: newValue)
        }
    }

    private func fileSize(for url: URL) -> String {
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let fileSize = values.fileSize else {
            return "Unknown size"
        }

        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }
}
