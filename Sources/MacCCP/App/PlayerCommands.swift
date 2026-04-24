import SwiftUI

struct PlayerCommands: Commands {
    @ObservedObject var store: PlayerStore

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open Media...") {
                store.presentOpenPanel()
            }
            .keyboardShortcut("o", modifiers: .command)

            Button("Add to Playlist...") {
                store.presentAddPanel()
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])
        }

        CommandMenu("Playback") {
            Button(store.isPlaying ? "Pause" : "Play") {
                store.togglePlayback()
            }
            .keyboardShortcut(.space, modifiers: [])
            .disabled(store.playlist.isEmpty)

            Divider()

            Button("Skip Backward") {
                store.skipBackward()
            }
            .keyboardShortcut(.leftArrow, modifiers: .command)
            .disabled(store.selectedItem == nil)

            Button("Skip Forward") {
                store.skipForward()
            }
            .keyboardShortcut(.rightArrow, modifiers: .command)
            .disabled(store.selectedItem == nil)

            Divider()

            Button("Previous") {
                store.playPrevious()
            }
            .keyboardShortcut(.leftArrow, modifiers: [.command, .shift])
            .disabled(store.selectedItem == nil)

            Button("Next") {
                store.playNext()
            }
            .keyboardShortcut(.rightArrow, modifiers: [.command, .shift])
            .disabled(!store.hasNextItem)

            Divider()

            Button("Next Audio Track") {
                store.cycleAudioTrack()
            }
            .keyboardShortcut("a", modifiers: [])
            .disabled(store.selectedItem == nil)

            Button("Next Subtitle Track") {
                store.cycleSubtitleTrack()
            }
            .keyboardShortcut("s", modifiers: [])
            .disabled(store.selectedItem == nil)

            Button("Add Subtitle File...") {
                store.presentSubtitlePanel()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(store.selectedItem == nil)

            Divider()

            ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
                Button("\(rate.formatted())x") {
                    store.setPlaybackRate(Float(rate))
                }
            }

            Divider()

            Button("Save Screenshot") {
                store.saveScreenshot()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(store.selectedItem == nil)
        }

        CommandMenu("Playlist") {
            Button("Reveal in Finder") {
                store.revealSelectedInFinder()
            }
            .disabled(store.selectedItem == nil)

            Button("Clear Playlist") {
                store.clearPlaylist()
            }
            .disabled(store.playlist.isEmpty)
        }
    }
}
