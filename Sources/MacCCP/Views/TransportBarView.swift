import SwiftUI

struct TransportBarView: View {
    @ObservedObject var store: PlayerStore
    @State private var scrubValue: Double?

    private let playbackRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    var body: some View {
        VStack(spacing: 5) {
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
            .controlSize(.small)
            .disabled(store.selectedItem == nil)

            HStack(spacing: 7) {
                Text(PlayerTimeFormatter.string(from: scrubValue ?? store.currentTime))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 58, alignment: .leading)

                ClassicTransportButton("Previous", systemImage: "backward.end.fill", action: store.playPrevious)
                    .disabled(store.selectedItem == nil)
                ClassicTransportButton("Back", systemImage: "gobackward", action: store.skipBackward)
                    .disabled(store.selectedItem == nil)
                ClassicTransportButton(store.isPlaying ? "Pause" : "Play", systemImage: store.isPlaying ? "pause.fill" : "play.fill", action: store.togglePlayback)
                    .keyboardShortcut(.space, modifiers: [])
                    .disabled(store.playlist.isEmpty)
                ClassicTransportButton("Stop", systemImage: "stop.fill", action: store.stop)
                    .disabled(store.selectedItem == nil)
                ClassicTransportButton("Forward", systemImage: "goforward", action: store.skipForward)
                    .disabled(store.selectedItem == nil)
                ClassicTransportButton("Next", systemImage: "forward.end.fill", action: store.playNext)
                    .disabled(!store.hasNextItem)

                Spacer(minLength: 8)

                Menu {
                    ForEach(playbackRates, id: \.self) { rate in
                        Button("\(rate.formatted())x") {
                            store.setPlaybackRate(rate)
                        }
                    }
                } label: {
                    Label("\(store.playbackRate.formatted())x", systemImage: "speedometer")
                }
                .labelStyle(.titleAndIcon)
                .menuStyle(.button)
                .fixedSize()

                Button {
                    store.isMuted.toggle()
                } label: {
                    Image(systemName: store.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .frame(width: 22)
                }
                .buttonStyle(.borderless)
                .help(store.isMuted ? "Unmute" : "Mute")

                Slider(value: $store.volume, in: 0...1)
                    .controlSize(.small)
                    .frame(width: 96)

                ClassicTransportButton("Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right") {
                    NSApp.keyWindow?.toggleFullScreen(nil)
                }
                .disabled(store.selectedItem == nil)

                Text(PlayerTimeFormatter.string(from: store.duration))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 58, alignment: .trailing)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

private struct ClassicTransportButton: View {
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
                .font(.system(size: 12, weight: .medium))
                .frame(width: 24, height: 20)
        }
        .buttonStyle(.borderless)
        .help(title)
    }
}
