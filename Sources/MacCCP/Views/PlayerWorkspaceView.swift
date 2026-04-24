import SwiftUI

struct PlayerWorkspaceView: View {
    @ObservedObject var store: PlayerStore
    let isBorderlessFullscreen: Bool
    @State private var fullscreenControlsVisible = false

    private let fullscreenControlHotZoneHeight = 108.0

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                videoSurface
                    .layoutPriority(1)

                if !isBorderlessFullscreen {
                    Divider()

                    TransportBarView(store: store)
                }
            }

            if isBorderlessFullscreen {
                fullscreenControlLayer
            }
        }
        .onChange(of: isBorderlessFullscreen) { _, fullscreen in
            if !fullscreen {
                fullscreenControlsVisible = false
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

    private var fullscreenControlLayer: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer(minLength: 0)

                Color.clear
                    .frame(height: fullscreenControlHotZoneHeight)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        setFullscreenControlsVisible(hovering)
                    }
            }

            if fullscreenControlsVisible {
                TransportBarView(store: store, isOverlay: true)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onHover { hovering in
                        setFullscreenControlsVisible(hovering)
                    }
            }
        }
    }

    private func setFullscreenControlsVisible(_ visible: Bool) {
        withAnimation(.easeInOut(duration: 0.16)) {
            fullscreenControlsVisible = visible
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
