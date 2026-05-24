import AppKit
import Foundation
import GhosttyKit
import SwiftUI

@MainActor
final class PenggieGhosttySession: ObservableObject {
    let terminalView: PenggieGhosttyHostView

    private let readingViewportSize = CGSize(width: 960, height: 640)
    private var config: ghostty_config_t?
    private var app: ghostty_app_t?
    private var surface: ghostty_surface_t?
    private var isClosed = false

    var onExit: (() -> Void)?

    init(codexPath: String, workingDirectory: String) throws {
        try PenggieGhosttyRuntime.initialize()

        guard let config = ghostty_config_new() else {
            throw PenggieGhosttySessionError.initializationFailed
        }
        ghostty_config_finalize(config)
        self.config = config

        self.terminalView = PenggieGhosttyHostView()

        var runtimeConfig = ghostty_runtime_config_s(
            userdata: nil,
            supports_selection_clipboard: true,
            wakeup_cb: { userdata in
                guard let userdata else { return }
                let session = Unmanaged<PenggieGhosttySession>.fromOpaque(userdata).takeUnretainedValue()
                DispatchQueue.main.async {
                    session.tick()
                }
            },
            action_cb: { _, _, _ in
                false
            },
            read_clipboard_cb: { userdata, _, state in
                guard let userdata else { return false }
                let session = Unmanaged<PenggieGhosttySession>.fromOpaque(userdata).takeUnretainedValue()
                return session.readClipboard(state: state)
            },
            confirm_read_clipboard_cb: { userdata, _, state, _ in
                guard let userdata else { return }
                let session = Unmanaged<PenggieGhosttySession>.fromOpaque(userdata).takeUnretainedValue()
                _ = session.readClipboard(state: state)
            },
            write_clipboard_cb: { _, _, content, len, _ in
                guard let content, len > 0 else { return }
                let first = content[0]
                guard let data = first.data else { return }
                let value = String(cString: data)
                DispatchQueue.main.async {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                }
            },
            close_surface_cb: { userdata, _ in
                guard let userdata else { return }
                let session = Unmanaged<PenggieGhosttySession>.fromOpaque(userdata).takeUnretainedValue()
                DispatchQueue.main.async {
                    session.handleProcessExit()
                }
            }
        )
        runtimeConfig.userdata = Unmanaged.passUnretained(self).toOpaque()

        guard let app = ghostty_app_new(&runtimeConfig, config) else {
            ghostty_config_free(config)
            throw PenggieGhosttySessionError.initializationFailed
        }
        self.app = app

        terminalView.session = self

        var surfaceConfig = ghostty_surface_config_new()
        surfaceConfig.userdata = Unmanaged.passUnretained(self).toOpaque()
        surfaceConfig.platform_tag = GHOSTTY_PLATFORM_MACOS
        surfaceConfig.platform = ghostty_platform_u(macos: ghostty_platform_macos_s(
            nsview: Unmanaged.passUnretained(terminalView).toOpaque()
        ))
        surfaceConfig.scale_factor = Double(NSScreen.main?.backingScaleFactor ?? CGFloat(2))
        surfaceConfig.font_size = 14
        surfaceConfig.wait_after_command = false
        surfaceConfig.context = GHOSTTY_SURFACE_CONTEXT_WINDOW

        let createdSurface = workingDirectory.withCString { workingDirectoryPointer in
            codexPath.withCString { commandPointer in
                surfaceConfig.working_directory = workingDirectoryPointer
                surfaceConfig.command = commandPointer
                return ghostty_surface_new(app, &surfaceConfig)
            }
        }

        guard let createdSurface else {
            ghostty_app_free(app)
            ghostty_config_free(config)
            throw PenggieGhosttySessionError.launchFailed
        }

        self.surface = createdSurface
        resizeSurface(to: readingViewportSize)
    }

    deinit {
        let surface = surface
        let app = app
        let config = config
        Task { @MainActor in
            if let surface {
                ghostty_surface_free(surface)
            }
            if let app {
                ghostty_app_free(app)
            }
            if let config {
                ghostty_config_free(config)
            }
        }
    }

    func close() {
        guard !isClosed else { return }
        isClosed = true
        if let surface {
            ghostty_surface_free(surface)
            self.surface = nil
        }
        onExit = nil
    }

    func sendPrompt(_ prompt: String) {
        sendText(prompt + "\n")
    }

    func sendText(_ text: String) {
        guard let surface, !text.isEmpty else { return }
        let count = text.lengthOfBytes(using: .utf8)
        text.withCString { pointer in
            ghostty_surface_text(surface, pointer, UInt(count))
        }
    }

    @discardableResult
    func sendKeyCode(_ keyCode: UInt16) -> Bool {
        guard let surface else { return false }

        var keyEvent = ghostty_input_key_s()
        keyEvent.action = GHOSTTY_ACTION_PRESS
        keyEvent.mods = GHOSTTY_MODS_NONE
        keyEvent.consumed_mods = GHOSTTY_MODS_NONE
        keyEvent.keycode = UInt32(keyCode)
        keyEvent.text = nil
        keyEvent.unshifted_codepoint = 0
        keyEvent.composing = false

        return ghostty_surface_key(surface, keyEvent)
    }

    func readVisibleText() -> String {
        guard let surface else { return "" }

        var text = ghostty_text_s()
        let selection = ghostty_selection_s(
            top_left: ghostty_point_s(
                tag: GHOSTTY_POINT_VIEWPORT,
                coord: GHOSTTY_POINT_COORD_TOP_LEFT,
                x: 0,
                y: 0
            ),
            bottom_right: ghostty_point_s(
                tag: GHOSTTY_POINT_VIEWPORT,
                coord: GHOSTTY_POINT_COORD_BOTTOM_RIGHT,
                x: 0,
                y: 0
            ),
            rectangle: false
        )

        guard ghostty_surface_read_text(surface, selection, &text), let rawText = text.text else {
            return ""
        }
        defer { ghostty_surface_free_text(surface, &text) }
        return String(cString: rawText)
    }

    func readScreenModelJSON() -> String? {
        guard let surface else { return nil }

        var text = ghostty_text_s()
        guard ghostty_surface_read_screen_model(surface, &text), let rawText = text.text else {
            return nil
        }
        defer { ghostty_surface_free_text(surface, &text) }
        return String(cString: rawText)
    }

    var processExited: Bool {
        guard let surface else { return true }
        return ghostty_surface_process_exited(surface)
    }

    func resizeSurface(to size: CGSize) {
        guard let surface else { return }

        let logicalSize = size.width > 8 && size.height > 8 ? size : readingViewportSize
        let backingSize = terminalView.convertToBacking(CGRect(origin: .zero, size: logicalSize)).size
        let width = max(UInt32(backingSize.width.rounded()), 1)
        let height = max(UInt32(backingSize.height.rounded()), 1)
        let fallbackScale = NSScreen.main?.backingScaleFactor ?? CGFloat(2)
        let scale = Double(terminalView.window?.backingScaleFactor ?? fallbackScale)
        ghostty_surface_set_content_scale(surface, scale, scale)
        ghostty_surface_set_size(surface, width, height)
    }

    private func tick() {
        guard !isClosed, let app else { return }
        ghostty_app_tick(app)
    }

    private func handleProcessExit() {
        guard !isClosed else { return }
        isClosed = true
        onExit?()
    }

    private func readClipboard(state: UnsafeMutableRawPointer?) -> Bool {
        guard let surface else { return false }
        guard let value = NSPasteboard.general.string(forType: .string) else { return false }
        value.withCString { pointer in
            ghostty_surface_complete_clipboard_request(surface, pointer, state, true)
        }
        return true
    }
}

final class PenggieGhosttyHostView: NSView {
    weak var session: PenggieGhosttySession?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.session?.resizeSurface(to: newSize)
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.window?.makeFirstResponder(self)
            self.session?.resizeSurface(to: self.bounds.size)
        }
    }
}

struct PenggieGhosttyTerminalView: NSViewRepresentable {
    @ObservedObject var session: PenggieGhosttySession

    func makeNSView(context: Context) -> PenggieGhosttyHostView {
        session.terminalView
    }

    func updateNSView(_ nsView: PenggieGhosttyHostView, context: Context) {
        session.resizeSurface(to: nsView.bounds.size)
    }
}

enum PenggieGhosttySessionError: LocalizedError {
    case initializationFailed
    case launchFailed

    var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "Penggie could not initialize the terminal session."
        case .launchFailed:
            return "Penggie could not start Codex."
        }
    }
}

private enum PenggieGhosttyRuntime {
    private static var initialized = false

    @MainActor
    static func initialize() throws {
        guard !initialized else { return }
        guard ghostty_init(UInt(CommandLine.argc), CommandLine.unsafeArgv) == GHOSTTY_SUCCESS else {
            throw PenggieGhosttySessionError.initializationFailed
        }
        initialized = true
    }
}
