import Foundation

@MainActor
final class OpenFileRouter {
    static let shared = OpenFileRouter()

    var handler: (([URL]) -> Void)? {
        didSet { flushPendingURLs() }
    }

    private var pendingURLs: [URL] = []

    private init() {}

    func open(_ urls: [URL]) {
        guard !urls.isEmpty else { return }

        if let handler {
            handler(urls)
        } else {
            pendingURLs.append(contentsOf: urls)
        }
    }

    private func flushPendingURLs() {
        guard let handler, !pendingURLs.isEmpty else { return }

        let urls = pendingURLs
        pendingURLs.removeAll()
        handler(urls)
    }
}
