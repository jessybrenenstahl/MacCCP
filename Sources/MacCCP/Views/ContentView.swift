import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var store: PlayerStore
    @AppStorage(PreferenceKeys.inspectorVisible) private var inspectorVisible = true
    @State private var isDropTargeted = false

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store)
                .navigationSplitViewColumnWidth(min: 240, ideal: 300, max: 420)
        } detail: {
            PlayerWorkspaceView(store: store, inspectorVisible: $inspectorVisible)
        }
        .navigationTitle(store.selectedItem?.title ?? "CCCP Player")
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    store.presentOpenPanel()
                } label: {
                    Label("Open", systemImage: "folder")
                }
                .help("Open media")
            }

            ToolbarItemGroup(placement: .principal) {
                Button {
                    store.playPrevious()
                } label: {
                    Label("Previous", systemImage: "backward.end.fill")
                }
                .disabled(store.selectedItem == nil)
                .help("Previous")

                Button {
                    store.togglePlayback()
                } label: {
                    Label(store.isPlaying ? "Pause" : "Play", systemImage: store.isPlaying ? "pause.fill" : "play.fill")
                }
                .disabled(store.playlist.isEmpty)
                .help(store.isPlaying ? "Pause" : "Play")

                Button {
                    store.playNext()
                } label: {
                    Label("Next", systemImage: "forward.end.fill")
                }
                .disabled(!store.hasNextItem)
                .help("Next")
            }

            ToolbarItemGroup(placement: .automatic) {
                Button {
                    inspectorVisible.toggle()
                } label: {
                    Label("Inspector", systemImage: "sidebar.trailing")
                }
                .help("Inspector")
            }
        }
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

private struct DropOverlayView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.35))
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "plus.rectangle.on.folder")
                    .font(.system(size: 42, weight: .regular))
                Text("Add to playlist")
                    .font(.title3.weight(.medium))
            }
            .foregroundStyle(.white)
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}
