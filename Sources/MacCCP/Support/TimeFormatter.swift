import Foundation

enum PlayerTimeFormatter {
    static func string(from seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "00:00" }

        let totalSeconds = Int(seconds.rounded(.down))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
