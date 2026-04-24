import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: PlayerStore

    @AppStorage(PreferenceKeys.autoplay) private var autoplay = true
    @AppStorage(PreferenceKeys.loopPlaylist) private var loopPlaylist = false
    @AppStorage(PreferenceKeys.rememberPosition) private var rememberPosition = true
    @AppStorage(PreferenceKeys.defaultVolume) private var defaultVolume = 0.85
    @AppStorage(PreferenceKeys.skipInterval) private var skipInterval = 10.0

    var body: some View {
        Form {
            Section("Playback") {
                Toggle("Start playback when media opens", isOn: $autoplay)
                Toggle("Loop current file", isOn: $store.isLoopingFile)
                Toggle("Loop playlist", isOn: $loopPlaylist)
                Toggle("Resume previous position", isOn: $rememberPosition)
            }

            Section("Controls") {
                HStack {
                    Text("Skip interval")
                    Slider(value: $skipInterval, in: 5...60, step: 5)
                    Text("\(Int(skipInterval))s")
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)
                }

                HStack {
                    Text("Default volume")
                    Slider(value: $defaultVolume, in: 0...1)
                    Text("\(Int(defaultVolume * 100))%")
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
    }
}
