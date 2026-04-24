# MacCCP

MacCCP is a native macOS media player inspired by Combined Community Codec Pack,
rebuilt around SwiftUI and libmpv instead of Windows DirectShow filters.

It is designed as a complete Mac-native answer to CCCP's original goal:
open the file, pick the right streams, render subtitles correctly, and avoid
codec surprises.

## Download

Download the latest DMG from the
[MacCCP releases page](https://github.com/jessybrenenstahl/MacCCP/releases/latest).

## Features

- libmpv playback backend with FFmpeg codec coverage
- Matroska/WebM/MP4/MOV/AVI/TS and other common containers
- H.264, HEVC/H.265, VP9, AV1, MPEG-2, ProRes, FFV1, FLAC, Opus, AAC, and more through mpv/FFmpeg
- libass subtitle rendering and automatic external subtitle discovery
- Audio and subtitle track switching
- Playlist sidebar with drag-and-drop opening
- Resume position, configurable skip interval, volume, mute, and speed controls
- Native macOS menus, toolbar, settings window, fullscreen, recent documents, and Finder reveal
- DMG packaging with bundled native playback libraries

## Build

Install Xcode and Homebrew, then:

```sh
brew install mpv
swift test
scripts/package_dmg.sh
```

The DMG is written to `dist/`.

## Release

The GitHub Actions release workflow builds and uploads a DMG when a version tag
such as `v1.0.0` is pushed.

For unsigned public builds, the workflow produces an ad-hoc signed app bundle.
For Developer ID distribution, configure these repository secrets before
running a release:

- `MACCCP_CODESIGN_IDENTITY`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`

The build scripts already support hardened-runtime signing and notarization when
those credentials are available.

## License

MacCCP is GPL software. See `LICENSE` and `NOTICE.md`.
