import Foundation

enum PreferenceKeys {
    static let autoplay = "player.autoplay"
    static let loopPlaylist = "player.loopPlaylist"
    static let rememberPosition = "player.rememberPosition"
    static let defaultVolume = "player.defaultVolume"
    static let muted = "player.muted"
    static let skipInterval = "player.skipInterval"
    static let inspectorVisible = "ui.inspectorVisible"
    static let playlistVisible = "ui.playlistVisible"
}

extension UserDefaults {
    func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        guard object(forKey: key) != nil else { return defaultValue }
        return bool(forKey: key)
    }

    func double(forKey key: String, default defaultValue: Double) -> Double {
        guard object(forKey: key) != nil else { return defaultValue }
        return double(forKey: key)
    }
}
