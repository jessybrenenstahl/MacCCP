import AppKit
import Combine
import Foundation

@MainActor
final class PlayerStore: ObservableObject {
    @Published var playlist: [PlaylistItem] = []
    @Published var selectedItemID: PlaylistItem.ID?
    @Published var searchText = ""
    @Published var isPlaying = false
    @Published var currentTime = 0.0
    @Published var duration = 0.0
    @Published var statusMessage = "Ready"
    @Published var playbackRate: Float = 1.0
    @Published var isLoopingFile: Bool {
        didSet {
            defaults.set(isLoopingFile, forKey: PreferenceKeys.loopFile)
            mpvClient.setFileLooping(isLoopingFile)
        }
    }
    @Published var volume: Double {
        didSet {
            defaults.set(volume, forKey: PreferenceKeys.defaultVolume)
            guard !isApplyingRemoteState else { return }
            mpvClient.setVolume(volume)
        }
    }
    @Published var isMuted: Bool {
        didSet {
            defaults.set(isMuted, forKey: PreferenceKeys.muted)
            guard !isApplyingRemoteState else { return }
            mpvClient.setMuted(isMuted)
        }
    }
    @Published var audioTracks: [MediaSelectionTrack] = [MediaSelectionTrack.audioAuto]
    @Published var subtitleTracks: [MediaSelectionTrack] = [MediaSelectionTrack.subtitlesOff]
    @Published var selectedAudioTrackID: String? = MediaSelectionTrack.audioAuto.id
    @Published var selectedSubtitleTrackID = MediaSelectionTrack.subtitlesOff.id

    private let defaults: UserDefaults
    private let historyStore: PlaybackHistoryStore
    private let mpvClient = MPVClient()
    private var isApplyingRemoteState = false
    private var lastPersistedTime = 0.0
    private var hasAttachedVideo = false

    init(defaults: UserDefaults = .standard, historyStore: PlaybackHistoryStore = PlaybackHistoryStore()) {
        self.defaults = defaults
        self.historyStore = historyStore
        self.volume = defaults.double(forKey: PreferenceKeys.defaultVolume, default: 0.85)
        self.isMuted = defaults.bool(forKey: PreferenceKeys.muted, default: false)
        self.isLoopingFile = defaults.bool(forKey: PreferenceKeys.loopFile, default: false)

        configureMPVCallbacks()
    }

    var selectedItem: PlaylistItem? {
        guard let selectedItemID else { return nil }
        return playlist.first { $0.id == selectedItemID }
    }

    var filteredPlaylist: [PlaylistItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return playlist }

        return playlist.filter { item in
            item.filename.localizedCaseInsensitiveContains(query)
                || item.url.path.localizedCaseInsensitiveContains(query)
        }
    }

    var hasPreviousItem: Bool {
        guard let index = selectedIndex else { return false }
        return index > 0
    }

    var hasNextItem: Bool {
        guard let index = selectedIndex else { return false }
        return index < playlist.count - 1 || defaults.bool(forKey: PreferenceKeys.loopPlaylist, default: false)
    }

    var selectedIndex: Int? {
        guard let selectedItemID else { return nil }
        return playlist.firstIndex { $0.id == selectedItemID }
    }

    func attachVideo(to renderer: MPVVideoRenderer) {
        guard !hasAttachedVideo else { return }

        hasAttachedVideo = true
        mpvClient.attach(to: renderer)
        mpvClient.setVolume(volume)
        mpvClient.setMuted(isMuted)
        mpvClient.setSpeed(Double(playbackRate))
        mpvClient.setFileLooping(isLoopingFile)
    }

    func presentOpenPanel() {
        open(urls: OpenPanelService.chooseMediaURLs())
    }

    func presentAddPanel() {
        enqueue(urls: OpenPanelService.chooseMediaURLs())
    }

    func presentSubtitlePanel() {
        let urls = OpenPanelService.chooseSubtitleURLs()
        guard let url = urls.first else { return }
        mpvClient.addSubtitle(url: url)
    }

    func open(urls: [URL]) {
        add(urls: urls, startPlayback: true)
    }

    func enqueue(urls: [URL]) {
        add(urls: urls, startPlayback: selectedItem == nil)
    }

    func play(id: PlaylistItem.ID) {
        guard let item = playlist.first(where: { $0.id == id }) else { return }
        play(item)
    }

    func play(_ item: PlaylistItem) {
        persistCurrentPosition()

        selectedItemID = item.id
        currentTime = 0
        duration = 0
        lastPersistedTime = 0
        statusMessage = item.filename
        mpvClient.loadFile(item.url)
        NSDocumentController.shared.noteNewRecentDocumentURL(item.url)

        if defaults.bool(forKey: PreferenceKeys.autoplay, default: true) {
            play()
        }
    }

    func togglePlayback() {
        isPlaying ? pause() : play()
    }

    func play() {
        if selectedItem == nil, let first = playlist.first {
            play(first)
            return
        }

        mpvClient.play()
        isPlaying = true
    }

    func pause() {
        mpvClient.pause()
        isPlaying = false
        persistCurrentPosition()
    }

    func stop() {
        mpvClient.stop()
        isPlaying = false
        currentTime = 0
        persistCurrentPosition()
    }

    func seek(to seconds: Double) {
        currentTime = max(0, seconds)
        mpvClient.seek(to: currentTime)
    }

    func skipForward() {
        mpvClient.seek(relative: defaults.double(forKey: PreferenceKeys.skipInterval, default: 10))
    }

    func skipBackward() {
        mpvClient.seek(relative: -defaults.double(forKey: PreferenceKeys.skipInterval, default: 10))
    }

    func skip(by seconds: Double) {
        mpvClient.seek(relative: seconds)
    }

    func playPrevious() {
        guard let index = selectedIndex else { return }

        if currentTime > 3 {
            seek(to: 0)
            return
        }

        guard index > 0 else {
            seek(to: 0)
            return
        }

        play(playlist[index - 1])
    }

    func playNext() {
        guard let index = selectedIndex else { return }

        if index < playlist.count - 1 {
            play(playlist[index + 1])
            return
        }

        if defaults.bool(forKey: PreferenceKeys.loopPlaylist, default: false), let first = playlist.first {
            play(first)
            return
        }

        pause()
        seek(to: 0)
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        mpvClient.setSpeed(Double(rate))
    }

    func toggleFileLooping() {
        isLoopingFile.toggle()
        statusMessage = isLoopingFile ? "Loop current file" : "Loop off"
    }

    func selectAudioTrack(id: String) {
        mpvClient.selectAudioTrack(id: id)
        selectedAudioTrackID = id
    }

    func selectSubtitleTrack(id: String) {
        mpvClient.selectSubtitleTrack(id: id)
        selectedSubtitleTrackID = id
    }

    func cycleAudioTrack() {
        mpvClient.cycleAudioTrack()
    }

    func cycleSubtitleTrack() {
        mpvClient.cycleSubtitleTrack()
    }

    func saveScreenshot() {
        mpvClient.screenshot()
        statusMessage = "Screenshot saved"
    }

    func remove(_ item: PlaylistItem) {
        guard let index = playlist.firstIndex(of: item) else { return }
        let wasSelected = item.id == selectedItemID
        playlist.remove(at: index)

        if wasSelected {
            selectedItemID = nil
            mpvClient.stop()

            if !playlist.isEmpty {
                let nextIndex = min(index, playlist.count - 1)
                play(playlist[nextIndex])
            }
        }
    }

    func clearPlaylist() {
        persistCurrentPosition()
        mpvClient.stop()
        playlist.removeAll()
        selectedItemID = nil
        currentTime = 0
        duration = 0
        isPlaying = false
        statusMessage = "Ready"
        audioTracks = [MediaSelectionTrack.audioAuto]
        subtitleTracks = [MediaSelectionTrack.subtitlesOff]
        selectedAudioTrackID = MediaSelectionTrack.audioAuto.id
        selectedSubtitleTrackID = MediaSelectionTrack.subtitlesOff.id
    }

    func revealSelectedInFinder() {
        guard let selectedItem else { return }
        NSWorkspace.shared.activateFileViewerSelecting([selectedItem.url])
    }

    private func configureMPVCallbacks() {
        mpvClient.onPlaybackStateChanged = { [weak self] state in
            guard let self else { return }
            self.apply(state)
        }

        mpvClient.onTracksChanged = { [weak self] audio, subtitles, selectedAudio, selectedSubtitle in
            guard let self else { return }
            self.audioTracks = audio
            self.subtitleTracks = subtitles
            self.selectedAudioTrackID = selectedAudio
            self.selectedSubtitleTrackID = selectedSubtitle
        }

        mpvClient.onStatusChanged = { [weak self] status in
            self?.statusMessage = status
        }

        mpvClient.onFileLoaded = { [weak self] in
            self?.restorePositionIfNeeded()
        }

        mpvClient.onFileEnded = { [weak self] in
            self?.handleItemEnded()
        }
    }

    private func apply(_ state: PlaybackState) {
        isApplyingRemoteState = true
        currentTime = state.currentTime
        duration = state.duration
        isPlaying = !state.isPaused
        volume = state.volume
        isMuted = state.isMuted
        playbackRate = Float(state.speed)
        isApplyingRemoteState = false

        if defaults.bool(forKey: PreferenceKeys.rememberPosition, default: true),
           abs(currentTime - lastPersistedTime) >= 5 {
            persistCurrentPosition()
        }
    }

    private func add(urls: [URL], startPlayback: Bool) {
        let mediaURLs = MediaFileResolver.resolve(urls)
        guard !mediaURLs.isEmpty else {
            statusMessage = "No playable media files found"
            return
        }

        let existingPaths = Set(playlist.map(\.url.path))
        let newItems = mediaURLs
            .filter { !existingPaths.contains($0.path) }
            .map { PlaylistItem(url: $0) }

        guard !newItems.isEmpty else {
            statusMessage = "Those files are already in the playlist"
            return
        }

        playlist.append(contentsOf: newItems)
        statusMessage = "\(newItems.count) item\(newItems.count == 1 ? "" : "s") added"

        if startPlayback, let first = newItems.first {
            play(first)
        }
    }

    private func handleItemEnded() {
        if let selectedItem {
            historyStore.clearPosition(for: selectedItem.url)
        }

        playNext()
    }

    private func restorePositionIfNeeded() {
        guard defaults.bool(forKey: PreferenceKeys.rememberPosition, default: true),
              let selectedItem else { return }

        let seconds = historyStore.position(for: selectedItem.url)
        guard seconds > 3 else { return }

        seek(to: seconds)
    }

    private func persistCurrentPosition() {
        guard defaults.bool(forKey: PreferenceKeys.rememberPosition, default: true),
              let selectedItem,
              currentTime > 3 else { return }

        historyStore.setPosition(currentTime, for: selectedItem.url)
        lastPersistedTime = currentTime
    }
}
