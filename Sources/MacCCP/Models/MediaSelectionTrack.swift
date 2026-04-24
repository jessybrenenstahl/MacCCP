import Foundation

struct MediaSelectionTrack: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let isOffOption: Bool

    static let subtitlesOff = MediaSelectionTrack(
        id: "subtitles.off",
        title: "Off",
        detail: "No subtitle track",
        isOffOption: true
    )

    static let audioAuto = MediaSelectionTrack(
        id: "auto",
        title: "Auto",
        detail: "Use the preferred audio track",
        isOffOption: false
    )
}
