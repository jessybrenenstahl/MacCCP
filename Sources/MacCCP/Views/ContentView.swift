import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var store: PlayerStore
    @AppStorage(PreferenceKeys.playlistVisible) private var playlistVisible = false
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            ClassicTopBar(store: store, playlistVisible: $playlistVisible)

            Divider()

            HStack(spacing: 0) {
                PlayerWorkspaceView(store: store)

                if playlistVisible {
                    Divider()
                    SidebarView(store: store)
                        .frame(width: 292)
                        .background(Color(nsColor: .controlBackgroundColor))
                }
            }

            Divider()

            ClassicStatusBar(store: store)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle(store.selectedItem?.title ?? "CCCP Player")
        .dropDestination(for: URL.self) { urls, _ in
            store.open(urls: urls)
            return true
        } isTargeted: { isTargeted in
            isDropTargeted = isTargeted
        }
        .overlay {
            if isDropTargeted {
                DropOverlayView()
            }
        }
    }
}

private struct ClassicTopBar: View {
    @ObservedObject var store: PlayerStore
    @Binding var playlistVisible: Bool

    var body: some View {
        HStack(spacing: 6) {
            ClassicIconButton("Open", systemImage: "folder", action: store.presentOpenPanel)
            ClassicIconButton("Add", systemImage: "plus", action: store.presentAddPanel)

            Divider()
                .frame(height: 18)

            ClassicIconButton("Previous", systemImage: "backward.end.fill", action: store.playPrevious)
                .disabled(store.selectedItem == nil)
            ClassicIconButton(store.isPlaying ? "Pause" : "Play", systemImage: store.isPlaying ? "pause.fill" : "play.fill", action: store.togglePlayback)
                .disabled(store.playlist.isEmpty)
            ClassicIconButton("Stop", systemImage: "stop.fill", action: store.stop)
                .disabled(store.selectedItem == nil)
            ClassicIconButton("Next", systemImage: "forward.end.fill", action: store.playNext)
                .disabled(!store.hasNextItem)

            Divider()
                .frame(height: 18)

            ClassicIconButton("Subtitle", systemImage: "captions.bubble", action: store.cycleSubtitleTrack)
                .disabled(store.selectedItem == nil)
            ClassicIconButton("Audio", systemImage: "speaker.wave.2", action: store.cycleAudioTrack)
                .disabled(store.selectedItem == nil)

            Spacer(minLength: 8)

            Text(store.selectedItem?.filename ?? "CCCP Player")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 8)

            ClassicIconButton("Playlist", systemImage: "list.bullet.rectangle") {
                playlistVisible.toggle()
            }
            .symbolVariant(playlistVisible ? .fill : .none)
        }
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
        .controlSize(.small)
        .padding(.horizontal, 8)
        .frame(height: 34)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

private struct ClassicIconButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 24, height: 22)
        }
        .help(title)
    }
}

private struct ClassicStatusBar: View {
    @ObservedObject var store: PlayerStore

    var body: some View {
        HStack(spacing: 10) {
            Text(store.statusMessage)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            if !store.playlist.isEmpty {
                Text("\((store.selectedIndex ?? 0) + 1)/\(store.playlist.count)")
            }

            Text("\(PlayerTimeFormatter.string(from: store.currentTime)) / \(PlayerTimeFormatter.string(from: store.duration))")
                .font(.system(.caption, design: .monospaced))
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

private struct DropOverlayView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.45))
                .ignoresSafeArea()

            VStack(spacing: 10) {
                Image(systemName: "plus.rectangle.on.folder")
                    .font(.system(size: 34, weight: .regular))
                Text("Add to playlist")
                    .font(.callout.weight(.medium))
            }
            .foregroundStyle(.white)
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}
