import SwiftUI

struct PlayerWorkspaceView: View {
    @ObservedObject var store: PlayerStore

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.black

                if store.selectedItem == nil {
                    EmptyPlayerView {
                        store.presentOpenPanel()
                    }
                } else {
                    MPVPlayerContainerView(store: store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            TransportBarView(store: store)
        }
    }
}

private struct EmptyPlayerView: View {
    let open: () -> Void

    var body: some View {
        Button {
            open()
        } label: {
            Label("Open Media", systemImage: "folder")
                .font(.system(size: 13))
        }
        .controlSize(.regular)
        .buttonStyle(.bordered)
        .tint(.secondary)
    }
}
