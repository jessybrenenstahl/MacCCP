import AppKit

@MainActor
final class BorderlessFullscreenController {
    static let shared = BorderlessFullscreenController()

    private struct WindowState {
        weak var window: NSWindow?
        let frame: NSRect
        let styleMask: NSWindow.StyleMask
        let level: NSWindow.Level
        let collectionBehavior: NSWindow.CollectionBehavior
        let titleVisibility: NSWindow.TitleVisibility
        let titlebarAppearsTransparent: Bool
        let hasShadow: Bool
        let isOpaque: Bool
        let backgroundColor: NSColor?
        let isMovableByWindowBackground: Bool
        let presentationOptions: NSApplication.PresentationOptions
    }

    private var state: WindowState?
    private var keyMonitor: Any?

    var onExit: (() -> Void)?

    var isActive: Bool {
        state != nil
    }

    func toggle() -> Bool {
        if isActive {
            exit()
            return false
        }

        guard let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: \.isVisible) else {
            return false
        }

        enter(window)
        return isActive
    }

    func exit() {
        guard let state else { return }
        self.state = nil
        removeKeyMonitor()

        guard let window = state.window else {
            NSApp.presentationOptions = state.presentationOptions
            onExit?()
            return
        }

        NSApp.presentationOptions = state.presentationOptions
        window.styleMask = state.styleMask
        window.titleVisibility = state.titleVisibility
        window.titlebarAppearsTransparent = state.titlebarAppearsTransparent
        window.level = state.level
        window.collectionBehavior = state.collectionBehavior
        window.hasShadow = state.hasShadow
        window.isOpaque = state.isOpaque
        window.backgroundColor = state.backgroundColor
        window.isMovableByWindowBackground = state.isMovableByWindowBackground
        window.setFrame(state.frame, display: true, animate: false)
        window.makeKeyAndOrderFront(nil)
        onExit?()
    }

    private func enter(_ window: NSWindow) {
        guard state == nil, let screen = window.screen ?? NSScreen.main else { return }

        state = WindowState(
            window: window,
            frame: window.frame,
            styleMask: window.styleMask,
            level: window.level,
            collectionBehavior: window.collectionBehavior,
            titleVisibility: window.titleVisibility,
            titlebarAppearsTransparent: window.titlebarAppearsTransparent,
            hasShadow: window.hasShadow,
            isOpaque: window.isOpaque,
            backgroundColor: window.backgroundColor,
            isMovableByWindowBackground: window.isMovableByWindowBackground,
            presentationOptions: NSApp.presentationOptions
        )

        NSApp.presentationOptions = [.autoHideDock, .autoHideMenuBar]
        window.styleMask = [.borderless]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.level = .normal
        window.collectionBehavior.insert([.fullScreenAuxiliary, .canJoinAllSpaces])
        window.hasShadow = false
        window.isOpaque = true
        window.backgroundColor = .black
        window.isMovableByWindowBackground = false
        window.setFrame(screen.frame, display: true, animate: false)
        window.makeKeyAndOrderFront(nil)
        installKeyMonitor()
    }

    private func installKeyMonitor() {
        removeKeyMonitor()

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }

            Task { @MainActor in
                self?.exit()
            }
            return nil
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }
}
