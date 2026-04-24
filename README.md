# MacCCP

MacCCP is a native macOS media player inspired by Combined Community Codec Pack,
rebuilt around SwiftUI and libmpv instead of Windows DirectShow filters.

It is designed as a complete Mac-native answer to CCCP's original goal:
open the file, pick the right streams, render subtitles correctly, and avoid
codec surprises.

## Download

Production downloads are published on the
[MacCCP releases page](https://github.com/jessybrenenstahl/MacCCP/releases/latest)
after the app is Developer ID signed, notarized, and stapled.

## Features

- libmpv playback backend with FFmpeg codec coverage
- Embedded libmpv render surface inside the MacCCP window
- Matroska/WebM/MP4/MOV/AVI/TS and other common containers
- H.264, HEVC/H.265, VP9, AV1, MPEG-2, ProRes, FFV1, FLAC, Opus, AAC, and more through mpv/FFmpeg
- libass subtitle rendering and automatic external subtitle discovery
- Audio and subtitle track switching
- Seamless current-file looping backed by mpv's native file loop mode
- Borderless fullscreen playback without macOS titlebar chrome
- Classic CCCP/MPC-HC-style player shell with optional playlist pane
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

Public releases require Developer ID distribution credentials. Configure these
repository secrets before pushing a version tag:

- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `KEYCHAIN_PASSWORD`
- `MACCCP_CODESIGN_IDENTITY`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`

The release workflow imports the certificate into a temporary keychain, signs the
app and bundled playback libraries, creates the DMG, submits it to Apple's
notary service, staples the ticket, and uploads the final DMG plus checksum.

## License

MacCCP is GPL software. See `LICENSE` and `NOTICE.md`.
