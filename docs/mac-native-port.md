# MacCCP

This workspace contains an unpacked Windows Combined Community Codec Pack distribution:

- `MPC/mpc-hc.exe` is a 32-bit Windows PE executable.
- `Filters/LAVFilters/*.dll` and `*.ax` are Windows DirectShow filters.
- There is no MPC-HC or LAV source tree in this checkout.

The native macOS implementation is therefore a replacement player built on SwiftUI,
AppKit, libmpv's render API, FFmpeg, and libass. It keeps the original CCCP goal
of broad playback compatibility while replacing Windows DirectShow registration
with a bundled native playback engine.

The Mac release does not install global codecs or register system filters. macOS
does not have a DirectShow-equivalent system codec model. Instead, MacCCP provides
the codec-complete behavior inside the app bundle.
