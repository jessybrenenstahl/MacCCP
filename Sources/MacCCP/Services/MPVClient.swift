import AppKit
import CMpv
import Foundation

@MainActor
protocol MPVVideoRenderer: AnyObject {
    func attachMPV(handle: OpaquePointer) -> Bool
}

@MainActor
final class MPVClient {
    var onPlaybackStateChanged: ((PlaybackState) -> Void)?
    var onTracksChanged: (([MediaSelectionTrack], [MediaSelectionTrack], String?, String) -> Void)?
    var onStatusChanged: ((String) -> Void)?
    var onFileLoaded: (() -> Void)?
    var onFileEnded: (() -> Void)?

    private var handle: OpaquePointer?
    private var isInitialized = false
    private var pendingURL: URL?
    private var playbackState = PlaybackState(
        currentTime: 0,
        duration: 0,
        isPaused: true,
        volume: 1,
        isMuted: false,
        speed: 1
    )

    func attach(to renderer: MPVVideoRenderer) {
        guard !isInitialized else { return }

        guard let handle = mpv_create() else {
            onStatusChanged?("Unable to initialize the mpv playback engine")
            return
        }

        self.handle = handle
        configure(handle: handle)

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        mpv_set_wakeup_callback(handle, { context in
            guard let context else { return }
            let client = Unmanaged<MPVClient>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in
                client.drainEvents()
            }
        }, selfPointer)

        guard mpv_initialize(handle) >= 0 else {
            onStatusChanged?("Unable to start the mpv playback engine")
            destroy()
            return
        }

        isInitialized = true
        observeProperties(on: handle)

        guard renderer.attachMPV(handle: handle) else {
            onStatusChanged?("Unable to attach the native video renderer")
            return
        }

        if let pendingURL {
            self.pendingURL = nil
            loadFile(pendingURL)
        }
    }

    func loadFile(_ url: URL) {
        guard isInitialized else {
            pendingURL = url
            return
        }

        command(["loadfile", url.path, "replace"])
        onStatusChanged?(url.lastPathComponent)
    }

    func play() {
        setFlagProperty("pause", false)
    }

    func pause() {
        setFlagProperty("pause", true)
    }

    func stop() {
        command(["stop"])
    }

    func seek(to seconds: Double) {
        setDoubleProperty("time-pos", seconds)
    }

    func seek(relative seconds: Double) {
        command(["seek", String(seconds), "relative+exact"])
    }

    func setVolume(_ volume: Double) {
        setDoubleProperty("volume", max(0, min(volume, 1)) * 100)
    }

    func setMuted(_ muted: Bool) {
        setFlagProperty("mute", muted)
    }

    func setSpeed(_ speed: Double) {
        setDoubleProperty("speed", speed)
    }

    func selectAudioTrack(id: String) {
        command(["set", "aid", id])
    }

    func selectSubtitleTrack(id: String) {
        let mpvID = id == MediaSelectionTrack.subtitlesOff.id ? "no" : id
        command(["set", "sid", mpvID])
    }

    func cycleAudioTrack() {
        command(["cycle", "aid"])
    }

    func cycleSubtitleTrack() {
        command(["cycle", "sid"])
    }

    func addSubtitle(url: URL) {
        command(["sub-add", url.path, "select"])
    }

    func screenshot() {
        command(["screenshot"])
    }

    func refreshTrackList() {
        guard let handle else { return }

        var node = mpv_node()
        guard mpv_get_property(handle, "track-list", MPV_FORMAT_NODE, &node) >= 0 else { return }
        defer { mpv_free_node_contents(&node) }

        let parsedTracks = parseTrackList(node)
        var audioTracks = [MediaSelectionTrack.audioAuto]
        audioTracks.append(contentsOf: parsedTracks.audio)

        let subtitleTracks = [MediaSelectionTrack.subtitlesOff] + parsedTracks.subtitles
        let selectedSubtitle = parsedTracks.selectedSubtitleID ?? MediaSelectionTrack.subtitlesOff.id
        onTracksChanged?(audioTracks, subtitleTracks, parsedTracks.selectedAudioID ?? "auto", selectedSubtitle)
    }

    private func configure(handle: OpaquePointer) {
        setOption("vo", "libmpv", on: handle)
        setOption("terminal", "no", on: handle)
        setOption("config", "no", on: handle)
        setOption("osc", "no", on: handle)
        setOption("input-default-bindings", "no", on: handle)
        setOption("input-vo-keyboard", "no", on: handle)
        setOption("keep-open", "yes", on: handle)
        setOption("hwdec", "auto-safe", on: handle)
        setOption("sub-auto", "fuzzy", on: handle)
        setOption("audio-file-auto", "fuzzy", on: handle)
        setOption("screenshot-template", "CCCP Player-%F-%P", on: handle)
        setOption("msg-level", "all=warn", on: handle)
    }

    private func observeProperties(on handle: OpaquePointer) {
        mpv_observe_property(handle, 0, "time-pos", MPV_FORMAT_DOUBLE)
        mpv_observe_property(handle, 0, "duration", MPV_FORMAT_DOUBLE)
        mpv_observe_property(handle, 0, "pause", MPV_FORMAT_FLAG)
        mpv_observe_property(handle, 0, "volume", MPV_FORMAT_DOUBLE)
        mpv_observe_property(handle, 0, "mute", MPV_FORMAT_FLAG)
        mpv_observe_property(handle, 0, "speed", MPV_FORMAT_DOUBLE)
        mpv_observe_property(handle, 0, "track-list", MPV_FORMAT_NODE)
    }

    private func drainEvents() {
        guard let handle else { return }

        while true {
            guard let eventPointer = mpv_wait_event(handle, 0) else { return }
            let event = eventPointer.pointee

            switch event.event_id {
            case MPV_EVENT_NONE:
                return
            case MPV_EVENT_FILE_LOADED:
                enqueueMainCallback { $0.onFileLoaded?() }
            case MPV_EVENT_END_FILE:
                enqueueMainCallback { $0.onFileEnded?() }
            case MPV_EVENT_PROPERTY_CHANGE:
                handlePropertyChange(event)
            case MPV_EVENT_SHUTDOWN:
                return
            default:
                break
            }
        }
    }

    private func handlePropertyChange(_ event: mpv_event) {
        guard let data = event.data else { return }

        let property = data.assumingMemoryBound(to: mpv_event_property.self).pointee
        let name = String(cString: property.name)

        switch name {
        case "time-pos":
            updateDoubleProperty(property, keyPath: \.currentTime)
        case "duration":
            updateDoubleProperty(property, keyPath: \.duration)
        case "volume":
            updateDoubleProperty(property, keyPath: \.volume, transform: { $0 / 100 })
        case "speed":
            updateDoubleProperty(property, keyPath: \.speed)
        case "pause":
            updateFlagProperty(property, keyPath: \.isPaused)
        case "mute":
            updateFlagProperty(property, keyPath: \.isMuted)
        case "track-list":
            updateTrackList(property)
        default:
            break
        }
    }

    private func command(_ args: [String]) {
        guard let handle else { return }

        args.withCStringArray { cArguments in
            _ = mpv_command(handle, cArguments)
        }
    }

    private func setOption(_ name: String, _ value: String, on handle: OpaquePointer) {
        name.withCString { cName in
            value.withCString { cValue in
                _ = mpv_set_option_string(handle, cName, cValue)
            }
        }
    }

    private func setDoubleProperty(_ name: String, _ value: Double) {
        guard let handle else { return }

        var value = value
        name.withCString { cName in
            _ = mpv_set_property(handle, cName, MPV_FORMAT_DOUBLE, &value)
        }
    }

    private func setFlagProperty(_ name: String, _ value: Bool) {
        guard let handle else { return }

        var flag: Int32 = value ? 1 : 0
        name.withCString { cName in
            _ = mpv_set_property(handle, cName, MPV_FORMAT_FLAG, &flag)
        }
    }

    private func doubleProperty(_ name: String) -> Double {
        guard let handle else { return 0 }

        var value = 0.0
        name.withCString { cName in
            _ = mpv_get_property(handle, cName, MPV_FORMAT_DOUBLE, &value)
        }
        return value.isFinite ? value : 0
    }

    private func flagProperty(_ name: String) -> Bool {
        guard let handle else { return false }

        var flag: Int32 = 0
        name.withCString { cName in
            _ = mpv_get_property(handle, cName, MPV_FORMAT_FLAG, &flag)
        }
        return flag != 0
    }

    private func enqueueMainCallback(_ callback: @escaping @MainActor (MPVClient) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            callback(self)
        }
    }

    private func updateDoubleProperty(
        _ property: mpv_event_property,
        keyPath: WritableKeyPath<PlaybackState, Double>,
        transform: (Double) -> Double = { $0 }
    ) {
        guard property.format == MPV_FORMAT_DOUBLE, let data = property.data else { return }

        let rawValue = data.assumingMemoryBound(to: Double.self).pointee
        playbackState[keyPath: keyPath] = rawValue.isFinite ? transform(rawValue) : 0
        onPlaybackStateChanged?(playbackState)
    }

    private func updateFlagProperty(_ property: mpv_event_property, keyPath: WritableKeyPath<PlaybackState, Bool>) {
        guard property.format == MPV_FORMAT_FLAG, let data = property.data else { return }

        playbackState[keyPath: keyPath] = data.assumingMemoryBound(to: Int32.self).pointee != 0
        onPlaybackStateChanged?(playbackState)
    }

    private func updateTrackList(_ property: mpv_event_property) {
        guard property.format == MPV_FORMAT_NODE, let data = property.data else { return }

        let parsedTracks = parseTrackList(data.assumingMemoryBound(to: mpv_node.self).pointee)
        var audioTracks = [MediaSelectionTrack.audioAuto]
        audioTracks.append(contentsOf: parsedTracks.audio)

        let subtitleTracks = [MediaSelectionTrack.subtitlesOff] + parsedTracks.subtitles
        let selectedSubtitle = parsedTracks.selectedSubtitleID ?? MediaSelectionTrack.subtitlesOff.id
        onTracksChanged?(audioTracks, subtitleTracks, parsedTracks.selectedAudioID ?? "auto", selectedSubtitle)
    }

    private func parseTrackList(_ node: mpv_node) -> (audio: [MediaSelectionTrack], subtitles: [MediaSelectionTrack], selectedAudioID: String?, selectedSubtitleID: String?) {
        guard node.format == MPV_FORMAT_NODE_ARRAY,
              let listPointer = node.u.list else {
            return ([], [], nil, nil)
        }

        let list = listPointer.pointee
        var audioTracks: [MediaSelectionTrack] = []
        var subtitleTracks: [MediaSelectionTrack] = []
        var selectedAudioID: String?
        var selectedSubtitleID: String?

        for index in 0..<Int(list.num) {
            let trackNode = list.values[index]
            guard let track = parseTrack(trackNode) else { continue }

            switch track.kind {
            case "audio":
                audioTracks.append(track.selection)
                if track.selected { selectedAudioID = track.selection.id }
            case "sub":
                subtitleTracks.append(track.selection)
                if track.selected { selectedSubtitleID = track.selection.id }
            default:
                break
            }
        }

        return (audioTracks, subtitleTracks, selectedAudioID, selectedSubtitleID)
    }

    private func parseTrack(_ node: mpv_node) -> MPVTrack? {
        guard node.format == MPV_FORMAT_NODE_MAP,
              let listPointer = node.u.list else {
            return nil
        }

        let list = listPointer.pointee
        var values: [String: mpv_node] = [:]

        for index in 0..<Int(list.num) {
            guard let keyPointer = list.keys[index] else { continue }
            values[String(cString: keyPointer)] = list.values[index]
        }

        guard let id = values["id"]?.int64Value,
              let kind = values["type"]?.stringValue else {
            return nil
        }

        let title = values["title"]?.stringValue
            ?? values["lang"]?.stringValue
            ?? "\(kind.capitalized) \(id)"

        let detailParts = [
            values["codec"]?.stringValue,
            values["lang"]?.stringValue,
            values["external"]?.flagValue == true ? "External" : nil
        ].compactMap { $0 }

        let selection = MediaSelectionTrack(
            id: String(id),
            title: title,
            detail: detailParts.isEmpty ? kind.capitalized : detailParts.joined(separator: " / "),
            isOffOption: false
        )

        return MPVTrack(kind: kind, selection: selection, selected: values["selected"]?.flagValue == true)
    }

    private func destroy() {
        guard let handle else { return }

        mpv_terminate_destroy(handle)
        self.handle = nil
        isInitialized = false
    }
}

struct PlaybackState {
    var currentTime: Double
    var duration: Double
    var isPaused: Bool
    var volume: Double
    var isMuted: Bool
    var speed: Double
}

private struct MPVTrack {
    let kind: String
    let selection: MediaSelectionTrack
    let selected: Bool
}

private extension mpv_node {
    var stringValue: String? {
        guard format == MPV_FORMAT_STRING, let string = u.string else { return nil }
        return String(cString: string)
    }

    var int64Value: Int64? {
        guard format == MPV_FORMAT_INT64 else { return nil }
        return u.int64
    }

    var flagValue: Bool? {
        guard format == MPV_FORMAT_FLAG else { return nil }
        return u.flag != 0
    }
}

private extension Array where Element == String {
    func withCStringArray<Result>(_ body: (UnsafeMutablePointer<UnsafePointer<CChar>?>) -> Result) -> Result {
        let cStrings = map { strdup($0) }
        defer { cStrings.forEach { free($0) } }

        let arguments: [UnsafePointer<CChar>?] = cStrings.map { pointer in
            guard let pointer else { return nil }
            return UnsafePointer(pointer)
        } + [nil]
        return arguments.withUnsafeBufferPointer { buffer in
            let pointer = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: buffer.count)
            defer { pointer.deallocate() }

            pointer.initialize(from: buffer.baseAddress!, count: buffer.count)
            return body(pointer)
        }
    }
}
