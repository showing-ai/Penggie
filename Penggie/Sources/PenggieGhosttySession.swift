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
    private var themeConfiguration: TerminalThemeConfiguration
    #if DEBUG
    private var lastTerminalStyleDiagnosticSignature = ""
    #endif

    var onExit: (() -> Void)?

    init(
        codexPath: String,
        workingDirectory: String,
        themeConfiguration: TerminalThemeConfiguration
    ) throws {
        try PenggieGhosttyRuntime.initialize()
        self.themeConfiguration = themeConfiguration

        guard let config = ghostty_config_new() else {
            throw PenggieGhosttySessionError.initializationFailed
        }

        do {
            let configPath = try Self.writePenggieEmbeddedTerminalConfig(themeConfiguration)
            configPath.withCString { pathPointer in
                ghostty_config_load_file(config, pathPointer)
            }
        } catch {
            ghostty_config_free(config)
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
            action_cb: { app, target, action in
                guard let userdata = ghostty_app_userdata(app) else { return false }
                let session = Unmanaged<PenggieGhosttySession>.fromOpaque(userdata).takeUnretainedValue()
                return session.handleGhosttyAction(target: target, action: action)
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
        syncGhosttyColorScheme()

        terminalView.session = self
        terminalView.applyTheme(themeConfiguration)

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

        let createdSurface = Self.withCodexSurfaceEnvironmentOverrides { envVars in
            envVars.withUnsafeMutableBufferPointer { envBuffer in
                surfaceConfig.env_vars = envBuffer.baseAddress
                surfaceConfig.env_var_count = envBuffer.count

                return workingDirectory.withCString { workingDirectoryPointer in
                    codexPath.withCString { commandPointer in
                        surfaceConfig.working_directory = workingDirectoryPointer
                        surfaceConfig.command = commandPointer
                        return ghostty_surface_new(app, &surfaceConfig)
                    }
                }
            }
        }

        guard let createdSurface else {
            ghostty_app_free(app)
            ghostty_config_free(config)
            throw PenggieGhosttySessionError.launchFailed
        }

        self.surface = createdSurface
        syncGhosttyColorScheme()
        terminalView.applyTheme(themeConfiguration)
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

    func applyTheme(_ configuration: TerminalThemeConfiguration) {
        themeConfiguration = configuration
        terminalView.applyTheme(configuration)
        syncGhosttyColorScheme()
    }

    func sendPrompt(_ prompt: String) {
        sendText(prompt)
        sendEnterKey()
    }

    func sendText(_ text: String) {
        guard let surface, !text.isEmpty else { return }
        let count = text.lengthOfBytes(using: .utf8)
        text.withCString { pointer in
            ghostty_surface_text(surface, pointer, UInt(count))
        }
    }

    @discardableResult
    func sendKeyCode(
        _ keyCode: UInt16,
        text: String? = nil,
        unshiftedCodepoint: UInt32 = 0
    ) -> Bool {
        sendKeyCode(
            keyCode,
            text: text,
            unshiftedCodepoint: unshiftedCodepoint,
            mods: GHOSTTY_MODS_NONE,
            consumedMods: GHOSTTY_MODS_NONE
        )
    }

    @discardableResult
    func sendEnterKey() -> Bool {
        sendKeyCode(36, text: "\r", unshiftedCodepoint: 13)
    }

    @discardableResult
    func sendKeyEvent(_ event: NSEvent) -> Bool {
        let text = Self.ghosttyText(for: event)
        let unshiftedCodepoint = Self.unshiftedCodepoint(for: event)
        return sendKeyCode(
            event.keyCode,
            text: text,
            unshiftedCodepoint: unshiftedCodepoint,
            mods: Self.ghosttyMods(for: event.modifierFlags),
            consumedMods: Self.consumedGhosttyMods(for: event.modifierFlags)
        )
    }

    @discardableResult
    private func sendKeyCode(
        _ keyCode: UInt16,
        text: String?,
        unshiftedCodepoint: UInt32,
        mods: ghostty_input_mods_e,
        consumedMods: ghostty_input_mods_e
    ) -> Bool {
        guard let surface else { return false }

        func send(textPointer: UnsafePointer<CChar>?) -> Bool {
            var keyEvent = ghostty_input_key_s()
            keyEvent.action = GHOSTTY_ACTION_PRESS
            keyEvent.mods = mods
            keyEvent.consumed_mods = consumedMods
            keyEvent.keycode = UInt32(keyCode)
            keyEvent.text = textPointer
            keyEvent.unshifted_codepoint = unshiftedCodepoint
            keyEvent.composing = false

            let pressed = ghostty_surface_key(surface, keyEvent)
            keyEvent.action = GHOSTTY_ACTION_RELEASE
            let released = ghostty_surface_key(surface, keyEvent)
            return pressed || released
        }

        guard let text else {
            return send(textPointer: nil)
        }

        return text.withCString { pointer in
            send(textPointer: pointer)
        }
    }

    func readVisibleText() -> String {
        readText(pointTag: GHOSTTY_POINT_VIEWPORT)
    }

    func readScreenText() -> String {
        readText(pointTag: GHOSTTY_POINT_SCREEN)
    }

    func readScreenModelJSON() -> String? {
        guard let surface else { return nil }

        var text = ghostty_text_s()
        guard ghostty_surface_read_screen_model(surface, &text), let rawText = text.text else {
            return nil
        }
        defer { ghostty_surface_free_text(surface, &text) }
        let json = String(cString: rawText)
        #if DEBUG
        logTerminalStyleDiagnosticIfNeeded(screenModelJSON: json)
        #endif
        return json
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

    func sendMouseScroll(deltaX: Double, deltaY: Double, precision: Bool, momentumPhase: NSEvent.Phase) {
        guard let surface else { return }

        var x = deltaX
        var y = deltaY
        if precision {
            x *= 2
            y *= 2
        }

        ghostty_surface_mouse_scroll(
            surface,
            x,
            y,
            Self.scrollMods(precision: precision, momentumPhase: momentumPhase)
        )
    }

    func sendMousePosition(_ point: CGPoint, in viewSize: CGSize, modifierFlags: NSEvent.ModifierFlags) {
        guard let surface else { return }
        ghostty_surface_mouse_pos(
            surface,
            Double(point.x),
            Double(viewSize.height - point.y),
            Self.ghosttyMods(for: modifierFlags)
        )
    }

    @discardableResult
    func sendMouseButton(
        state: ghostty_input_mouse_state_e,
        button: ghostty_input_mouse_button_e,
        modifierFlags: NSEvent.ModifierFlags
    ) -> Bool {
        guard let surface else { return false }
        return ghostty_surface_mouse_button(
            surface,
            state,
            button,
            Self.ghosttyMods(for: modifierFlags)
        )
    }

    @discardableResult
    func performGhosttyBindingAction(_ action: String) -> Bool {
        guard let surface else { return false }
        return action.withCString { pointer in
            ghostty_surface_binding_action(
                surface,
                pointer,
                UInt(action.lengthOfBytes(using: .utf8))
            )
        }
    }

    @discardableResult
    func copySelectionToPasteboard() -> Bool {
        guard let surface, ghostty_surface_has_selection(surface) else { return false }

        var text = ghostty_text_s()
        guard ghostty_surface_read_selection(surface, &text),
              let rawText = text.text,
              text.text_len > 0 else {
            return false
        }
        defer { ghostty_surface_free_text(surface, &text) }

        let data = Data(bytes: rawText, count: Int(text.text_len))
        guard let value = String(data: data, encoding: .utf8) else { return false }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        return true
    }

    private func readText(pointTag: ghostty_point_tag_e) -> String {
        guard let surface else { return "" }

        var text = ghostty_text_s()
        let selection = ghostty_selection_s(
            top_left: ghostty_point_s(
                tag: pointTag,
                coord: GHOSTTY_POINT_COORD_TOP_LEFT,
                x: 0,
                y: 0
            ),
            bottom_right: ghostty_point_s(
                tag: pointTag,
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

    private static func scrollMods(precision: Bool, momentumPhase: NSEvent.Phase) -> ghostty_input_scroll_mods_t {
        var rawValue: Int32 = precision ? 0b0000_0001 : 0
        rawValue |= Int32(scrollMomentumRawValue(for: momentumPhase)) << 1
        return rawValue
    }

    private static func scrollMomentumRawValue(for phase: NSEvent.Phase) -> UInt8 {
        switch phase {
        case .began:
            return 1
        case .stationary:
            return 2
        case .changed:
            return 3
        case .ended:
            return 4
        case .cancelled:
            return 5
        case .mayBegin:
            return 6
        default:
            return 0
        }
    }

    private static func ghosttyText(for event: NSEvent) -> String? {
        guard let characters = event.characters, !characters.isEmpty else { return nil }

        if characters.count == 1,
           let scalar = characters.unicodeScalars.first {
            if scalar.value < 0x20 {
                return event.characters(byApplyingModifiers: event.modifierFlags.subtracting(.control))
            }

            if scalar.value >= 0xF700 && scalar.value <= 0xF8FF {
                return nil
            }
        }

        return characters
    }

    private static func unshiftedCodepoint(for event: NSEvent) -> UInt32 {
        guard event.type == .keyDown || event.type == .keyUp,
              let characters = event.characters(byApplyingModifiers: []),
              let scalar = characters.unicodeScalars.first else {
            return 0
        }

        return scalar.value
    }

    private static func ghosttyMods(for flags: NSEvent.ModifierFlags) -> ghostty_input_mods_e {
        var rawValue: UInt32 = 0
        if flags.contains(.capsLock) {
            rawValue |= GHOSTTY_MODS_CAPS.rawValue
        }
        if flags.contains(.shift) {
            rawValue |= GHOSTTY_MODS_SHIFT.rawValue
        }
        if flags.contains(.control) {
            rawValue |= GHOSTTY_MODS_CTRL.rawValue
        }
        if flags.contains(.option) {
            rawValue |= GHOSTTY_MODS_ALT.rawValue
        }
        if flags.contains(.command) {
            rawValue |= GHOSTTY_MODS_SUPER.rawValue
        }
        return ghostty_input_mods_e(rawValue: rawValue)
    }

    private static func consumedGhosttyMods(for flags: NSEvent.ModifierFlags) -> ghostty_input_mods_e {
        ghosttyMods(for: flags.subtracting([.control, .command]))
    }

    private func tick() {
        guard !isClosed, let app else { return }
        ghostty_app_tick(app)
    }

    private func syncGhosttyColorScheme() {
        #if DEBUG
        Self.logDebugDiagnostic(
            "[PenggieTerminalThemeDiagnostic] apply \(themeConfiguration.debugPaletteSummary)"
        )
        #endif
        if let app {
            ghostty_app_set_color_scheme(app, themeConfiguration.colorScheme.ghosttyColorScheme)
        }
        if let surface {
            ghostty_surface_set_color_scheme(surface, themeConfiguration.colorScheme.ghosttyColorScheme)
        }
    }

    private func handleGhosttyAction(target: ghostty_target_s, action: ghostty_action_s) -> Bool {
        guard action.tag == GHOSTTY_ACTION_RELOAD_CONFIG,
              let config else {
            return false
        }

        switch target.tag {
        case GHOSTTY_TARGET_APP:
            guard let app else { return false }
            ghostty_app_update_config(app, config)
            #if DEBUG
            Self.logDebugDiagnostic(
                "[PenggieTerminalThemeDiagnostic] reload-config target=app \(themeConfiguration.debugPaletteSummary)"
            )
            #endif
            return true
        case GHOSTTY_TARGET_SURFACE:
            guard let surface = target.target.surface else { return false }
            ghostty_surface_update_config(surface, config)
            #if DEBUG
            Self.logDebugDiagnostic(
                "[PenggieTerminalThemeDiagnostic] reload-config target=surface \(themeConfiguration.debugPaletteSummary)"
            )
            #endif
            return true
        default:
            return false
        }
    }

#if DEBUG
    private func logTerminalStyleDiagnosticIfNeeded(screenModelJSON: String) {
        guard let snapshot = PenggieTerminalScreenSnapshot(json: screenModelJSON) else { return }
        let candidates = Self.terminalStyleDiagnosticLines(in: snapshot)
        guard !candidates.isEmpty else { return }

        let signature = [
            themeConfiguration.debugPaletteSummary,
            "cursor=\(snapshot.cursor.map { "\($0.x),\($0.y),visible=\($0.visible)" } ?? "nil")",
            Self.debugTerminalStyleLines(candidates)
        ].joined(separator: " ")

        guard signature != lastTerminalStyleDiagnosticSignature else { return }
        lastTerminalStyleDiagnosticSignature = signature

        Self.logDebugDiagnostic(
            """
            [PenggieTerminalStyleDiagnostic] \(themeConfiguration.debugPaletteSummary)
            cursor=\(snapshot.cursor.map { "\($0.x),\($0.y),visible=\($0.visible)" } ?? "nil")
            lines=\(Self.debugTerminalStyleLines(candidates))
            """
        )
    }

    private static func terminalStyleDiagnosticLines(
        in snapshot: PenggieTerminalScreenSnapshot
    ) -> [PenggieTerminalScreenSnapshot.Line] {
        var indices: [Int] = []

        func append(_ index: Int?) {
            guard let index,
                  !indices.contains(index),
                  snapshot.lines.contains(where: { $0.index == index }) else {
                return
            }
            indices.append(index)
        }

        append(snapshot.cursor?.y)

        for line in snapshot.lines {
            let trimmed = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let summary = line.styleSummary
            let hasPromptMarker = Self.hasTerminalSelectionMarker(trimmed)
            let hasWideBackground = (summary?.backgroundCellCount ?? 0) >= max(12, snapshot.columns / 3)
            let hasInverse = (summary?.inverseTextCellCount ?? 0) > 0

            if hasPromptMarker || hasWideBackground || hasInverse {
                append(line.index)
            }
        }

        return indices
            .compactMap { index in snapshot.lines.first { $0.index == index } }
            .prefix(10)
            .map { $0 }
    }

    private static func hasTerminalSelectionMarker(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("›") || trimmed.hasPrefix("❯")
    }

    private static func debugTerminalStyleLines(_ lines: [PenggieTerminalScreenSnapshot.Line]) -> String {
        lines
            .map { line in
                let summary = line.styleSummary.map {
                    "summary{text=\($0.textCellCount),termSel=\(line.terminalTextSelected),sel=\($0.selectedCellCount),selText=\($0.selectedTextCellCount),inv=\($0.inverseTextCellCount),bgText=\($0.backgroundTextCellCount),bg=\($0.backgroundCellCount),bgOnly=\($0.backgroundOnlyCellCount),fg=\($0.foregroundTextCellCount),fgCells=\($0.foregroundCellCount),faint=\($0.faintTextCellCount),bold=\($0.boldTextCellCount)}"
                } ?? "summary=nil"
                let runs = line.styleRuns
                    .prefix(8)
                    .map(Self.debugStyleRun)
                    .joined(separator: ",")
                return "#\(line.index):'\(line.text)' \(summary) runs=[\(runs)]"
            }
            .joined(separator: " | ")
    }

    private static func debugStyleRun(_ run: PenggieTerminalScreenSnapshot.Line.StyleRun) -> String {
        [
            "\(run.startColumn)-\(run.endColumn)",
            "fg=\(debugColor(run.foreground))",
            "bg=\(debugColor(run.background))",
            "bold=\(run.bold)",
            "faint=\(run.faint)",
            "inv=\(run.inverse)",
            "text=\(run.textCellCount)",
            "bgCells=\(run.backgroundCellCount)"
        ].joined(separator: ":")
    }

    private static func debugColor(_ color: PenggieTerminalScreenSnapshot.Line.StyleRun.Color?) -> String {
        guard let color else { return "nil" }
        return [color.kind, color.value].compactMap(\.self).joined(separator: "=")
    }

    private static func logDebugDiagnostic(_ message: String) {
        NSLog("%@", message)

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Penggie", isDirectory: true)
        let url = directory.appendingPathComponent("terminal-style-diagnostic.log")
        guard let data = ("\(Date()) \(message)\n").data(using: .utf8) else { return }

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: url.path),
               let handle = try? FileHandle(forWritingTo: url) {
                defer { try? handle.close() }
                try handle.seekToEnd()
                handle.write(data)
            } else {
                try data.write(to: url)
            }
        } catch {
            NSLog("[PenggieTerminalStyleDiagnostic] failed to write debug log: %@", String(describing: error))
        }
    }
#endif

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

    private static func writePenggieEmbeddedTerminalConfig(
        _ themeConfiguration: TerminalThemeConfiguration
    ) throws -> String {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Penggie", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let url = directory.appendingPathComponent("ghostty-embedded.conf")
        let lightThemeURL = directory.appendingPathComponent("penggie-terminal-light.theme")
        let darkThemeURL = directory.appendingPathComponent("penggie-terminal-dark.theme")

        try themeConfiguration.lightRendererTheme.write(
            to: lightThemeURL,
            atomically: true,
            encoding: .utf8
        )
        try themeConfiguration.darkRendererTheme.write(
            to: darkThemeURL,
            atomically: true,
            encoding: .utf8
        )

        let contents = themeConfiguration.ghosttyConfigContents(
            lightThemePath: lightThemeURL.path,
            darkThemePath: darkThemeURL.path
        )

        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url.path
    }

    private static func withCodexSurfaceEnvironmentOverrides<Result>(
        _ body: (inout [ghostty_env_var_s]) -> Result
    ) -> Result {
        #if DEBUG
        NSLog(
            "[PenggieCodexLaunchEnvironment] surface env overrides: NO_COLOR=<unset> CLICOLOR=1 CLICOLOR_FORCE=<unset> FORCE_COLOR=<unset>; TERM/COLORTERM/TERM_PROGRAM are Ghostty-owned"
        )
        #endif
        let overrides = [
            ("NO_COLOR", ""),
            ("CLICOLOR", "1"),
            ("CLICOLOR_FORCE", ""),
            ("FORCE_COLOR", "")
        ]
        let storage = overrides.map { key, value in
            (key: strdup(key), value: strdup(value))
        }
        defer {
            for entry in storage {
                free(entry.key)
                free(entry.value)
            }
        }

        var envVars = storage.map { entry in
            ghostty_env_var_s(key: UnsafePointer(entry.key), value: UnsafePointer(entry.value))
        }
        return body(&envVars)
    }

}

final class PenggieGhosttyHostView: NSView {
    weak var session: PenggieGhosttySession?
    var isInteractive = true
    private var trackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        applyTheme(.fallback)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var acceptsFirstResponder: Bool {
        isInteractive
    }

    func applyTheme(_ configuration: TerminalThemeConfiguration) {
        wantsLayer = true
        layer?.backgroundColor = configuration.hostBackgroundColor.cgColor
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let nextTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseEnteredAndExited, .mouseMoved, .inVisibleRect],
            owner: self
        )
        addTrackingArea(nextTrackingArea)
        trackingArea = nextTrackingArea
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
            if self.isInteractive {
                self.window?.makeFirstResponder(self)
            }
            self.session?.resizeSurface(to: self.bounds.size)
        }
    }

    override func scrollWheel(with event: NSEvent) {
        guard isInteractive else { return }
        session?.sendMouseScroll(
            deltaX: event.scrollingDeltaX,
            deltaY: event.scrollingDeltaY,
            precision: event.hasPreciseScrollingDeltas,
            momentumPhase: event.momentumPhase
        )
    }

    override func mouseDown(with event: NSEvent) {
        guard isInteractive else { return }
        window?.makeFirstResponder(self)
        sendMousePosition(event)
        _ = session?.sendMouseButton(
            state: GHOSTTY_MOUSE_PRESS,
            button: GHOSTTY_MOUSE_LEFT,
            modifierFlags: event.modifierFlags
        )
    }

    override func mouseDragged(with event: NSEvent) {
        guard isInteractive else { return }
        sendMousePosition(event)
    }

    override func mouseUp(with event: NSEvent) {
        guard isInteractive else { return }
        sendMousePosition(event)
        _ = session?.sendMouseButton(
            state: GHOSTTY_MOUSE_RELEASE,
            button: GHOSTTY_MOUSE_LEFT,
            modifierFlags: event.modifierFlags
        )
    }

    override func rightMouseDown(with event: NSEvent) {
        guard isInteractive else {
            super.rightMouseDown(with: event)
            return
        }
        sendMousePosition(event)
        let consumed = session?.sendMouseButton(
            state: GHOSTTY_MOUSE_PRESS,
            button: GHOSTTY_MOUSE_RIGHT,
            modifierFlags: event.modifierFlags
        ) ?? false
        if !consumed {
            super.rightMouseDown(with: event)
        }
    }

    override func rightMouseUp(with event: NSEvent) {
        guard isInteractive else {
            super.rightMouseUp(with: event)
            return
        }
        sendMousePosition(event)
        let consumed = session?.sendMouseButton(
            state: GHOSTTY_MOUSE_RELEASE,
            button: GHOSTTY_MOUSE_RIGHT,
            modifierFlags: event.modifierFlags
        ) ?? false
        if !consumed {
            super.rightMouseUp(with: event)
        }
    }

    override func rightMouseDragged(with event: NSEvent) {
        guard isInteractive else { return }
        sendMousePosition(event)
    }

    override func otherMouseDown(with event: NSEvent) {
        guard isInteractive else { return }
        sendMousePosition(event)
        _ = session?.sendMouseButton(
            state: GHOSTTY_MOUSE_PRESS,
            button: ghosttyMouseButton(for: event.buttonNumber),
            modifierFlags: event.modifierFlags
        )
    }

    override func otherMouseUp(with event: NSEvent) {
        guard isInteractive else { return }
        sendMousePosition(event)
        _ = session?.sendMouseButton(
            state: GHOSTTY_MOUSE_RELEASE,
            button: ghosttyMouseButton(for: event.buttonNumber),
            modifierFlags: event.modifierFlags
        )
    }

    override func otherMouseDragged(with event: NSEvent) {
        guard isInteractive else { return }
        sendMousePosition(event)
    }

    override func mouseMoved(with event: NSEvent) {
        guard isInteractive else { return }
        sendMousePosition(event)
    }

    override func mouseEntered(with event: NSEvent) {
        guard isInteractive else { return }
        sendMousePosition(event)
    }

    override func mouseExited(with event: NSEvent) {
        guard isInteractive, NSEvent.pressedMouseButtons == 0 else { return }
        session?.sendMousePosition(
            CGPoint(x: -1, y: bounds.height + 1),
            in: bounds.size,
            modifierFlags: event.modifierFlags
        )
    }

    override func keyDown(with event: NSEvent) {
        guard isInteractive else {
            super.keyDown(with: event)
            return
        }
        guard session?.sendKeyEvent(event) == true else {
            super.keyDown(with: event)
            return
        }
    }

    @IBAction func copy(_ sender: Any?) {
        guard isInteractive else { return }
        if session?.performGhosttyBindingAction("copy_to_clipboard") == true {
            return
        }
        _ = session?.copySelectionToPasteboard()
    }

    @IBAction func paste(_ sender: Any?) {
        guard isInteractive else { return }
        _ = session?.performGhosttyBindingAction("paste_from_clipboard")
    }

    private func sendMousePosition(_ event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        session?.sendMousePosition(point, in: bounds.size, modifierFlags: event.modifierFlags)
    }

    private func ghosttyMouseButton(for buttonNumber: Int) -> ghostty_input_mouse_button_e {
        switch buttonNumber {
        case 0:
            return GHOSTTY_MOUSE_LEFT
        case 1:
            return GHOSTTY_MOUSE_RIGHT
        case 2:
            return GHOSTTY_MOUSE_MIDDLE
        case 3:
            return GHOSTTY_MOUSE_FOUR
        case 4:
            return GHOSTTY_MOUSE_FIVE
        case 5:
            return GHOSTTY_MOUSE_SIX
        case 6:
            return GHOSTTY_MOUSE_SEVEN
        case 7:
            return GHOSTTY_MOUSE_EIGHT
        case 8:
            return GHOSTTY_MOUSE_NINE
        case 9:
            return GHOSTTY_MOUSE_TEN
        case 10:
            return GHOSTTY_MOUSE_ELEVEN
        default:
            return GHOSTTY_MOUSE_UNKNOWN
        }
    }
}

private extension PenggieTerminalColorScheme {
    var ghosttyColorScheme: ghostty_color_scheme_e {
        switch self {
        case .light:
            return GHOSTTY_COLOR_SCHEME_LIGHT
        case .dark:
            return GHOSTTY_COLOR_SCHEME_DARK
        }
    }
}

struct PenggieGhosttyTerminalView: NSViewRepresentable {
    @ObservedObject var session: PenggieGhosttySession
    let isActive: Bool

    func makeNSView(context: Context) -> PenggieGhosttyHostView {
        session.terminalView.isInteractive = isActive
        session.terminalView.isHidden = false
        session.terminalView.alphaValue = isActive ? 1 : 0
        return session.terminalView
    }

    func updateNSView(_ nsView: PenggieGhosttyHostView, context: Context) {
        nsView.isInteractive = isActive
        nsView.isHidden = false
        nsView.alphaValue = isActive ? 1 : 0
        if isActive, nsView.window?.firstResponder !== nsView {
            nsView.window?.makeFirstResponder(nsView)
        }
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
