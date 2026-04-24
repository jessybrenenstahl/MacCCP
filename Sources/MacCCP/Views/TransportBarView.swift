import SwiftUI

struct TransportBarView: View {
    @ObservedObject var store: PlayerStore
    @State private var scrubValue: Double?

    private let playbackRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { scrubValue ?? store.currentTime },
                    set: { scrubValue = $0 }
                ),
                in: 0...max(store.duration, 1),
                onEditingChanged: { editing in
                    guard !editing, let scrubValue else { return }
                    store.seek(to: scrubValue)
                    self.scrubValue = nil
                }
            )
            .disabled(store.selectedItem == nil)

            HStack(spacing: 12) {
                Text(PlayerTimeFormatter.string(from: scrubValue ?? store.currentTime))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 58, alignment: .leading)

                Spacer(minLength: 4)

                Button {
                    store.playPrevious()
                } label: {
                    Label("Previous", systemImage: "backward.end.fill")
                }
                .disabled(store.selectedItem == nil)

                Button {
                    store.skipBackward()
                } label: {
                    Label("Back", systemImage: "gobackward")
                }
                .disabled(store.selectedItem == nil)

                Button {
                    store.togglePlayback()
                } label: {
                    Label(store.isPlaying ? "Pause" : "Play", systemImage: store.isPlaying ? "pause.fill" : "play.fill")
                }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(store.playlist.isEmpty)

                Button {
                    store.skipForward()
                } label: {
                    Label("Forward", systemImage: "goforward")
                }
                .disabled(store.selectedItem == nil)

                Button {
                    store.playNext()
                } label: {
                    Label("Next", systemImage: "forward.end.fill")
                }
                .disabled(!store.hasNextItem)

                Spacer(minLength: 4)

                Menu {
                    ForEach(playbackRates, id: \.self) { rate in
                        Button("\(rate.formatted())x") {
                            store.setPlaybackRate(rate)
                        }
                    }
                } label: {
                    Label("\(store.playbackRate.formatted())x", systemImage: "speedometer")
                }
                .frame(width: 74)

                Button {
                    store.isMuted.toggle()
                } label: {
                    Label(store.isMuted ? "Unmute" : "Mute", systemImage: store.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                }

                Slider(value: $store.volume, in: 0...1)
                    .frame(width: 92)

                Button {
                    NSApp.keyWindow?.toggleFullScreen(nil)
                } label: {
                    Label("Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .disabled(store.selectedItem == nil)

                Text(PlayerTimeFormatter.string(from: store.duration))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 58, alignment: .trailing)
            }
            .buttonStyle(.borderless)
            .labelStyle(.iconOnly)
            .controlSize(.large)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
