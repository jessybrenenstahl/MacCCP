import AppKit
import SwiftUI

struct MPVPlayerContainerView: NSViewRepresentable {
    @ObservedObject var store: PlayerStore

    func makeNSView(context: Context) -> NSView {
        let view = MPVHostView()
        store.attachVideo(to: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        store.attachVideo(to: nsView)
    }
}

private final class MPVHostView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }
}
