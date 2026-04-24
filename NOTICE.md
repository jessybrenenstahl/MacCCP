# Notices

MacCCP is a new native macOS application. It does not redistribute the original
Windows MPC-HC executable, DirectShow filters, or installer payloads from the
Combined Community Codec Pack distribution.

The app links against libmpv and bundles the native libraries needed by the
release build. libmpv includes FFmpeg-backed playback and libass subtitle
rendering functionality. Distribution of release builds must preserve the
applicable GPL/LGPL/BSD/ISC notices from those dependencies.

The application icon is derived from the CCCP icon asset present in the source
distribution used for this port. Replace it before public distribution if that
asset is not licensed for the intended release channel.

Primary upstream projects used by the playback backend:

- mpv: https://mpv.io/
- FFmpeg: https://ffmpeg.org/
- libass: https://github.com/libass/libass
- libbluray: https://www.videolan.org/developers/libbluray.html
