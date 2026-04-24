import AppKit
import CMpv
import Darwin
import OpenGL.GL3
import SwiftUI

private let openGLFrameworkHandle = dlopen("/System/Library/Frameworks/OpenGL.framework/OpenGL", RTLD_LAZY | RTLD_LOCAL)

private func macCCPGetOpenGLProcAddress(
    _ context: UnsafeMutableRawPointer?,
    _ name: UnsafePointer<CChar>?
) -> UnsafeMutableRawPointer? {
    guard let name else { return nil }

    guard let openGLFrameworkHandle else { return nil }
    return dlsym(openGLFrameworkHandle, name)
}

struct MPVPlayerContainerView: NSViewRepresentable {
    @ObservedObject var store: PlayerStore

    func makeNSView(context: Context) -> MPVOpenGLHostView {
        let view = MPVOpenGLHostView()
        store.attachVideo(to: view)
        return view
    }

    func updateNSView(_ nsView: MPVOpenGLHostView, context: Context) {
        store.attachVideo(to: nsView)
    }
}

final class MPVOpenGLHostView: NSOpenGLView, MPVVideoRenderer {
    private var renderContext: OpaquePointer?

    init() {
        super.init(frame: .zero, pixelFormat: Self.makePixelFormat())!
        wantsBestResolutionOpenGLSurface = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        pixelFormat = Self.makePixelFormat()
        wantsBestResolutionOpenGLSurface = true
    }

    deinit {
        if let renderContext {
            openGLContext?.makeCurrentContext()
            mpv_render_context_set_update_callback(renderContext, nil, nil)
            mpv_render_context_free(renderContext)
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func prepareOpenGL() {
        super.prepareOpenGL()

        openGLContext?.makeCurrentContext()
        var swapInterval: GLint = 1
        openGLContext?.setValues(&swapInterval, for: .swapInterval)
        glClearColor(0, 0, 0, 1)
    }

    override func reshape() {
        super.reshape()
        needsDisplay = true
    }

    func attachMPV(handle: OpaquePointer) -> Bool {
        openGLContext?.makeCurrentContext()

        var context: OpaquePointer?
        var initParams = mpv_opengl_init_params(
            get_proc_address: macCCPGetOpenGLProcAddress,
            get_proc_address_ctx: nil
        )

        let result = "opengl".withCString { apiType in
            withUnsafeMutablePointer(to: &initParams) { initParamsPointer in
                var params = [
                    mpv_render_param(
                        type: MPV_RENDER_PARAM_API_TYPE,
                        data: UnsafeMutableRawPointer(mutating: apiType)
                    ),
                    mpv_render_param(
                        type: MPV_RENDER_PARAM_OPENGL_INIT_PARAMS,
                        data: UnsafeMutableRawPointer(initParamsPointer)
                    ),
                    mpv_render_param(type: MPV_RENDER_PARAM_INVALID, data: nil)
                ]

                return mpv_render_context_create(&context, handle, &params)
            }
        }

        guard result >= 0, let context else { return false }

        renderContext = context
        let viewPointer = Unmanaged.passUnretained(self).toOpaque()
        mpv_render_context_set_update_callback(context, { pointer in
            guard let pointer else { return }
            let view = Unmanaged<MPVOpenGLHostView>.fromOpaque(pointer).takeUnretainedValue()
            DispatchQueue.main.async { [weak view] in
                view?.needsDisplay = true
            }
        }, viewPointer)

        needsDisplay = true
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        openGLContext?.makeCurrentContext()

        guard let renderContext else {
            clearToBlack()
            openGLContext?.flushBuffer()
            return
        }

        let backingSize = convertToBacking(bounds).size
        var fbo = mpv_opengl_fbo(
            fbo: 0,
            w: max(1, Int32(backingSize.width.rounded(.down))),
            h: max(1, Int32(backingSize.height.rounded(.down))),
            internal_format: 0
        )
        var flipY: CInt = 1

        withUnsafeMutablePointer(to: &fbo) { fboPointer in
            withUnsafeMutablePointer(to: &flipY) { flipYPointer in
                var params = [
                    mpv_render_param(
                        type: MPV_RENDER_PARAM_OPENGL_FBO,
                        data: UnsafeMutableRawPointer(fboPointer)
                    ),
                    mpv_render_param(
                        type: MPV_RENDER_PARAM_FLIP_Y,
                        data: UnsafeMutableRawPointer(flipYPointer)
                    ),
                    mpv_render_param(type: MPV_RENDER_PARAM_INVALID, data: nil)
                ]

                _ = mpv_render_context_render(renderContext, &params)
            }
        }

        openGLContext?.flushBuffer()
    }

    private func clearToBlack() {
        glClearColor(0, 0, 0, 1)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    }

    private static func makePixelFormat() -> NSOpenGLPixelFormat {
        let attributes: [NSOpenGLPixelFormatAttribute] = [
            UInt32(NSOpenGLPFAOpenGLProfile),
            UInt32(NSOpenGLProfileVersion3_2Core),
            UInt32(NSOpenGLPFAColorSize),
            24,
            UInt32(NSOpenGLPFAAlphaSize),
            8,
            UInt32(NSOpenGLPFADoubleBuffer),
            UInt32(NSOpenGLPFAAccelerated),
            UInt32(NSOpenGLPFANoRecovery),
            UInt32(NSOpenGLPFAAllowOfflineRenderers),
            0
        ]

        guard let pixelFormat = NSOpenGLPixelFormat(attributes: attributes) else {
            fatalError("Unable to create an OpenGL pixel format for mpv rendering")
        }

        return pixelFormat
    }
}
