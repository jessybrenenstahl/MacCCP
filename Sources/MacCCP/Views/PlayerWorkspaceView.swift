import SwiftUI

struct PlayerWorkspaceView: View {
    @ObservedObject var store: PlayerStore
    let isBorderlessFullscreen: Bool

    var body: some View {
        if isBorderlessFullscreen {
            ZStack(alignment: .bottom) {
                videoSurface

                TransportBarView(store: store)
                    .background(.black.opacity(0.72))
            }
        } else {
            VStack(spacing: 0) {
                videoSurface

                Divider()

                TransportBarView(store: store)
            }
        }
    }

    private var videoSurface: some View {
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
