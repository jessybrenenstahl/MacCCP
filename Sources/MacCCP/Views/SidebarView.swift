import SwiftUI

struct SidebarView: View {
    @ObservedObject var store: PlayerStore

    var body: some View {
        VStack(spacing: 0) {
            List(selection: selectionBinding) {
                Section("Playlist") {
                    ForEach(store.filteredPlaylist) { item in
                        PlaylistRowView(item: item, isSelected: item.id == store.selectedItemID)
                            .tag(item.id)
                            .contextMenu {
                                Button("Play") {
                                    store.play(item)
                                }

                                Button("Reveal in Finder") {
                                    NSWorkspace.shared.activateFileViewerSelecting([item.url])
                                }

                                Divider()

                                Button("Remove from Playlist", role: .destructive) {
                                    store.remove(item)
                                }
                            }
                    }
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $store.searchText, placement: .sidebar, prompt: "Search")

            Divider()

            HStack(spacing: 8) {
                Button {
                    store.presentOpenPanel()
                } label: {
                    Label("Open", systemImage: "folder")
                }

                Button {
                    store.presentAddPanel()
                } label: {
                    Label("Add", systemImage: "plus")
                }

                Spacer()

                Button(role: .destructive) {
                    store.clearPlaylist()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(store.playlist.isEmpty)
            }
            .controlSize(.small)
            .padding(10)
        }
    }

    private var selectionBinding: Binding<PlaylistItem.ID?> {
        Binding {
            store.selectedItemID
        } set: { newValue in
            guard let newValue, newValue != store.selectedItemID else { return }
            store.play(id: newValue)
        }
    }
}

private struct PlaylistRowView: View {
    let item: PlaylistItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "play.rectangle")
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .lineLimit(1)

                Text(item.fileExtension)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}
