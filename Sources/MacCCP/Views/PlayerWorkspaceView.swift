import SwiftUI

struct PlayerWorkspaceView: View {
    @ObservedObject var store: PlayerStore
    @Binding var inspectorVisible: Bool

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Color.black

                if store.selectedItem == nil {
                    EmptyPlayerView {
                        store.presentOpenPanel()
                    }
                } else {
                    MPVPlayerContainerView(store: store)
                }

                VStack {
                    Spacer()
                    TransportBarView(store: store)
                        .padding(14)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if inspectorVisible {
                Divider()
                InspectorView(store: store)
                    .frame(width: 280)
            }
        }
    }
}

private struct EmptyPlayerView: View {
    let open: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "play.rectangle.on.rectangle")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(.secondary)

            Button {
                open()
            } label: {
                Label("Open Media", systemImage: "folder")
            }
            .controlSize(.large)
        }
        .foregroundStyle(.white)
    }
}
