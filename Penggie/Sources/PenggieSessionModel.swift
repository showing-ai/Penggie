import AppKit
import Foundation
import SwiftUI

@MainActor
final class PenggieSessionModel: ObservableObject {
    static let codexCommandEnvironmentKey = "PENGGIE_CODEX_COMMAND"
    static let forceLaunchFailureEnvironmentKey = "PENGGIE_FORCE_LAUNCH_FAILURE"
    private static let lastWorkingDirectoryDefaultsKey = "PenggieLastWorkingDirectory"

    enum State: Equatable {
        case idle
        case checkingCodex
        case launching
        case reading
        case terminal
        case codexMissing
        case launchFailed(String)
        case exited
        case closed
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var lastError: String?
    @Published private(set) var transcriptText = ""
    @Published private(set) var readingBlocks: [PenggieReadingBlock] = []
    @Published private(set) var ghosttySession: PenggieGhosttySession?
    @Published private(set) var nativeInteractionPhase: PenggieNativeInteractionPhase = .inactive
    @Published private(set) var nativeInteractionDisplayText = ""
    @Published private(set) var nativeInteractionRows: [PenggieNativeInteractionLine] = []
    @Published private(set) var selectedWorkingDirectory: URL?
    @Published private(set) var activeWorkingDirectory: URL?
    @Published private(set) var codexScreenKind: PenggieCodexScreenKind = .unknown
    @Published private(set) var resumePickerProjection = PenggieCodexResumePickerProjection.empty
    @Published private(set) var latestTerminalFrame: PenggieTerminalFrame?
    @Published private(set) var activeTerminalInteractionSurface: PenggieTerminalInteractionSurface?
    @Published private(set) var hasObservedCodexScreen = false
    @Published private(set) var hasReachedStableCodexScreen = false
    @Published var pendingConfirmation: Confirmation?

    let substrate = PenggieGhosttySubstrate()
    private var screenPollTask: Task<Void, Never>?
    private var nativeInteractionResolvingBeganAt: Date?
    private var nativeInteractionEscapeSentAt: Date?
    private var readingTurnStore = PenggieReadingTurnStore()
    private var readingResumeHydrator = PenggieReadingResumeHydrator()
    private var lastReadingProjectionText = ""
    private var lastReadingProjectionRefreshSecond: Int?
    private var pendingDisplayReadyTarget: PenggieCodexDisplayReadyTarget?
    private var pendingDisplayReadyPollCount = 0
    private var resumePickerRequiresFreshSelection = false
    private var terminalFrameID = 0
    private var terminalThemeConfiguration = TerminalThemeConfiguration.fallback
#if DEBUG
    private var lastResumePickerDiagnosticSignature = ""
    private var lastActiveInputStyleDiagnosticSignature = ""
#endif

    init() {
        selectedWorkingDirectory = Self.restoreLastWorkingDirectory()
    }

    var nativeInteractionIsActive: Bool {
        nativeInteractionPhase.isActive
    }

    var canStartCodex: Bool {
        switch state {
        case .idle, .codexMissing, .launchFailed, .exited, .closed:
            return true
        case .checkingCodex, .launching, .reading, .terminal:
            return false
        }
    }

    var canStartNewChat: Bool {
        hasInspectableSession
    }

    var hasInspectableSession: Bool {
        switch state {
        case .reading, .terminal:
            return hasReachedStableCodexScreen
        case .exited:
            return true
        case .idle, .checkingCodex, .launching, .codexMissing, .launchFailed, .closed:
            return false
        }
    }

    var isRunning: Bool {
        switch state {
        case .reading, .terminal:
            return true
        case .idle, .checkingCodex, .launching, .codexMissing, .launchFailed, .exited, .closed:
            return false
        }
    }

    var canSubmitPrompt: Bool {
        isRunning && !codexScreenKind.isTerminalOwnedInteraction && readingTurnStore.canSubmitPrompt
    }

    var canStartConfiguredCodex: Bool {
        guard canStartCodex, let selectedWorkingDirectory else {
            return false
        }

        return Self.isUsableWorkingDirectory(selectedWorkingDirectory)
    }

    var isHoldingInitialSurface: Bool {
        switch state {
        case .checkingCodex, .launching:
            return true
        case .reading:
            return !hasReachedStableCodexScreen
        case .idle, .terminal, .codexMissing, .launchFailed, .exited, .closed:
            return false
        }
    }

    var sessionFolderTitle: String {
        (activeWorkingDirectory ?? selectedWorkingDirectory)?.lastPathComponent.nilIfEmpty ?? "Folder"
    }

    func applyTheme(_ configuration: TerminalThemeConfiguration) {
        terminalThemeConfiguration = configuration
        ghosttySession?.applyTheme(configuration)
    }

    var sessionFolderDisplayPath: String {
        guard let url = activeWorkingDirectory ?? selectedWorkingDirectory else {
            return "Choose a folder"
        }

        return (url.path as NSString).abbreviatingWithTildeInPath
    }

    func startWithCodex() {
        guard canStartConfiguredCodex,
              let workingDirectory = selectedWorkingDirectory else {
            return
        }

        Self.storeLastWorkingDirectory(workingDirectory)
        state = .checkingCodex
        lastError = nil

        Task {
            let isAvailable = await Self.resolveCodexCommandPath() != nil
            await MainActor.run {
                guard isAvailable else {
                    self.state = .codexMissing
                    return
                }

                self.state = .launching
                self.launchCodexSession()
            }
        }
    }

    func switchToReading() {
        guard hasInspectableSession else { return }
        state = .reading
    }

    func switchToTerminal() {
        guard hasInspectableSession else { return }
        state = .terminal
    }

    func requestNewChat() {
        guard hasInspectableSession else { return }
        pendingConfirmation = .newChat
    }

    func requestCloseSession() {
        guard hasInspectableSession else { return }
        pendingConfirmation = .closeSession
    }

    func confirm(_ confirmation: Confirmation) {
        pendingConfirmation = nil
        switch confirmation {
        case .newChat:
            closeCurrentSession()
            state = .closed
            startWithCodex()
        case .closeSession:
            closeCurrentSession()
            state = .closed
        }
    }

    func cancelConfirmation() {
        pendingConfirmation = nil
    }

    @discardableResult
    func chooseWorkingDirectory() -> URL? {
        guard canStartCodex else {
            return selectedWorkingDirectory
        }

        let panel = NSOpenPanel()
        panel.title = "Choose Session Folder"
        panel.prompt = "Choose"
        panel.message = "Penggie will start this agent session in the selected folder."
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = selectedWorkingDirectory ?? FileManager.default.homeDirectoryForCurrentUser

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        selectedWorkingDirectory = url
        Self.storeLastWorkingDirectory(url)
        return url
    }

    private func launchCodexSession() {
        guard substrate.isAvailable else {
            state = .launchFailed("Penggie could not initialize the terminal session.")
            return
        }

        guard let workingDirectory = selectedWorkingDirectory else {
            state = .closed
            return
        }

        guard Self.isUsableWorkingDirectory(workingDirectory) else {
            state = .launchFailed("Penggie cannot access this session folder: \(workingDirectory.path)")
            return
        }

        if Self.shouldForceLaunchFailureForVerification {
            state = .launchFailed("Penggie could not start Codex.")
            return
        }

        Task {
            let codexPath = await Self.resolveCodexCommandPath()
            await MainActor.run {
                guard let codexPath else {
                    self.state = .codexMissing
                    return
                }

                do {
                    let session = try PenggieGhosttySession(
                        codexPath: codexPath,
                        workingDirectory: workingDirectory.path,
                        themeConfiguration: self.terminalThemeConfiguration
                    )
                    session.onExit = { [weak self] in
                        self?.state = .exited
                    }
                    self.ghosttySession = session
                    self.activeWorkingDirectory = workingDirectory
                    self.transcriptText = ""
                    self.readingBlocks = []
                    self.codexScreenKind = .unknown
                    self.resumePickerProjection = .empty
                    self.latestTerminalFrame = nil
                    self.activeTerminalInteractionSurface = nil
                    self.hasObservedCodexScreen = false
                    self.hasReachedStableCodexScreen = false
                    self.resumePickerRequiresFreshSelection = false
                    self.resetDisplayReadyGate()
                    self.readingTurnStore.reset()
                    self.readingResumeHydrator.reset()
                    self.resetReadingProjectionCache()
                    self.startScreenPolling()
                    self.state = .reading
                } catch {
                    self.state = .launchFailed(error.localizedDescription)
                }
            }
        }
    }

    @discardableResult
    func sendPrompt(_ prompt: String) -> Bool {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canSubmitPrompt else { return false }
        readingTurnStore.submitPrompt(trimmed)
        readingBlocks = readingResumeHydrator.combined(with: readingTurnStore.blocks)
        ghosttySession?.sendPrompt(trimmed)
        startScreenPolling()
        return true
    }

    @discardableResult
    func beginNativeInteraction(prefix: String) -> Bool {
        beginNativeInteraction(initialText: prefix)
    }

    @discardableResult
    func beginNativeInteraction(initialText: String) -> Bool {
        guard isRunning,
              !nativeInteractionIsActive,
              PenggieComposerNativeTrigger.prefix(for: initialText) != nil else {
            return false
        }

        nativeInteractionPhase = .editing
        nativeInteractionDisplayText = initialText
        nativeInteractionResolvingBeganAt = nil
        nativeInteractionEscapeSentAt = nil
        nativeInteractionRows = []
        ghosttySession?.sendText(initialText)
        startScreenPolling()
        return true
    }

    @discardableResult
    func sendNativeInteractionText(_ text: String) -> Bool {
        guard nativeInteractionPhase.capturesTextInput, !text.isEmpty else { return false }
        ghosttySession?.sendText(text)
        nativeInteractionDisplayText += text
        startScreenPolling()
        return true
    }

    @discardableResult
    func sendNativeInteractionCommand(_ command: PenggieInteractionCommand) -> Bool {
        guard nativeInteractionPhase.acceptsInput else { return false }

        let sent = sendNativeKey(command)
        updateNativeDisplayText(after: command)
        startScreenPolling()
        return sent
    }

    @discardableResult
    func sendResumePickerCommand(_ command: PenggieInteractionCommand) -> Bool {
        guard isRunning, codexScreenKind == .resumePicker else { return false }
        let sent = sendNativeKey(command)
        if sent {
            resumePickerRequiresFreshSelection = true
        }
        startScreenPolling()
        return sent
    }

    @discardableResult
    func sendResumePickerText(_ text: String) -> Bool {
        guard isRunning, codexScreenKind == .resumePicker, !text.isEmpty else { return false }
        ghosttySession?.sendText(text)
        resumePickerRequiresFreshSelection = true
        startScreenPolling()
        return true
    }

    @discardableResult
    func sendTerminalSurfaceCommand(_ command: PenggieInteractionCommand) -> Bool {
        guard isRunning, activeTerminalInteractionSurface != nil else { return false }
        let sent = sendNativeKey(command)
        startScreenPolling()
        return sent
    }

    @discardableResult
    func sendTerminalSurfaceText(_ text: String) -> Bool {
        guard isRunning, activeTerminalInteractionSurface != nil, !text.isEmpty else { return false }
        ghosttySession?.sendText(text)
        startScreenPolling()
        return true
    }

    @discardableResult
    func sendNativeInteractionEnter() -> Bool {
        sendNativeInteractionCommand(.enter)
    }

    @discardableResult
    func cancelNativeInteraction() -> Bool {
        guard nativeInteractionPhase.acceptsInput else { return false }
        nativeInteractionEscapeSentAt = Date()
        let sent = sendNativeKey(.escape)
        startScreenPolling()
        return sent
    }

    private func closeCurrentSession() {
        screenPollTask?.cancel()
        screenPollTask = nil
        ghosttySession?.close()
        ghosttySession = nil
        activeWorkingDirectory = nil
        transcriptText = ""
        readingBlocks = []
        codexScreenKind = .unknown
        resumePickerProjection = .empty
        latestTerminalFrame = nil
        activeTerminalInteractionSurface = nil
        hasObservedCodexScreen = false
        hasReachedStableCodexScreen = false
        resumePickerRequiresFreshSelection = false
        resetDisplayReadyGate()
        readingTurnStore.reset()
        readingResumeHydrator.reset()
        resetReadingProjectionCache()
        endNativeInteraction()
    }

    private func startScreenPolling() {
        screenPollTask?.cancel()
        screenPollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                await MainActor.run {
                    guard let self, let session = self.ghosttySession else { return }
                    let visibleText = session.readVisibleText()
                    let screenText = session.readScreenText()
                    let readingText = self.nativeInteractionIsActive ? visibleText : screenText
                    let hadObservedCodexScreen = self.hasObservedCodexScreen
                    let currentScreenKind = PenggieCodexScreenKind.detect(in: visibleText)
                    let screenKind = currentScreenKind == .unknown && !hadObservedCodexScreen
                        ? PenggieCodexScreenKind.detect(in: screenText)
                        : currentScreenKind
                    let screenModelJSON = PenggieTerminalScreenModelReadPolicy.requiresScreenModelJSON(
                        visibleText: visibleText,
                        screenText: screenText,
                        screenKind: screenKind,
                        nativeInteractionIsActive: self.nativeInteractionIsActive
                    ) ? session.readScreenModelJSON() : nil
                    let terminalFrame = self.nextTerminalFrame(
                        visibleText: visibleText,
                        screenText: screenText,
                        screenModelJSON: screenModelJSON,
                        processExited: session.processExited
                    )
                    self.latestTerminalFrame = terminalFrame
                    self.transcriptText = visibleText
                    if !readingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        !visibleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.hasObservedCodexScreen = true
                    }
                    self.codexScreenKind = screenKind
                    self.updateResumePickerProjection(
                        from: terminalFrame,
                        projectionText: screenKind == .resumePicker ? visibleText : readingText,
                        screenKind: screenKind,
                        backingText: screenText
                    )
                    let activeSurface = self.updateActiveTerminalInteractionSurface(from: terminalFrame)
#if DEBUG
                    self.logResumePickerDiagnosticIfNeeded(
                        from: terminalFrame,
                        screenKind: screenKind,
                    )
                    self.logTerminalInteractionSurfaceDiagnosticIfNeeded(
                        from: terminalFrame,
                        surface: activeSurface
                    )
                    self.logActiveInputStyleDiagnosticIfNeeded(
                        from: terminalFrame,
                        screenKind: screenKind,
                    )
#endif
                    let displayReadyTarget = PenggieCodexDisplayReadiness.target(
                        screenKind: screenKind,
                        frame: terminalFrame,
                        resumePickerProjection: self.resumePickerProjection,
                        hasObservedCodexScreen: self.hasObservedCodexScreen
                    )
                    self.updateInitialDisplayReadyGate(with: displayReadyTarget)
                    if !self.nativeInteractionIsActive && activeSurface == nil && !self.isHoldingInitialSurface {
                        self.updateReadingBlocks(
                            from: terminalFrame,
                            projectionText: readingText,
                            currentScreenKind: screenKind
                        )
                    } else if screenKind.isLaunchBlockingScreen {
                        self.readingResumeHydrator.reset()
                        self.readingBlocks = self.readingTurnStore.blocks
                    }
                    self.updateNativeInteractionRows(
                        from: terminalFrame
                    )
                    if session.processExited {
                        self.state = .exited
                        self.screenPollTask?.cancel()
                        self.screenPollTask = nil
                    }
                }
            }
        }
    }

    @discardableResult
    private func updateActiveTerminalInteractionSurface(
        from frame: PenggieTerminalFrame
    ) -> PenggieTerminalInteractionSurface? {
        let surface = PenggieTerminalBehaviorZoner.classify(
            frame: frame,
            currentInput: nativeInteractionIsActive ? nativeInteractionDisplayText : nil
        )
        if activeTerminalInteractionSurface != surface {
            activeTerminalInteractionSurface = surface
        }
        return surface
    }

    private func updateResumePickerProjection(
        from frame: PenggieTerminalFrame,
        projectionText: String,
        screenKind: PenggieCodexScreenKind,
        backingText: String
    ) {
        let nextProjection: PenggieCodexResumePickerProjection
        if screenKind == .resumePicker {
            nextProjection = PenggieCodexResumePickerProjection.parse(
                from: projectionText,
                backingProjection: backingText,
                snapshot: frame.snapshot
            )
        } else {
            nextProjection = .empty
        }

        if nextProjection.hasExactlyOneSelectedRow || screenKind != .resumePicker {
            resumePickerRequiresFreshSelection = false
        }

        if resumePickerProjection != nextProjection {
            resumePickerProjection = nextProjection
        }
    }

#if DEBUG
    private func logResumePickerDiagnosticIfNeeded(
        from frame: PenggieTerminalFrame,
        screenKind: PenggieCodexScreenKind
    ) {
        guard screenKind == .resumePicker,
              !resumePickerProjection.rows.isEmpty,
              !resumePickerProjection.hasExactlyOneSelectedRow else {
            return
        }

        let selectedCount = resumePickerProjection.rows.filter(\.isSelected).count
        let snapshot = frame.snapshot
        let signature = [
            "frame=\(frame.id)",
            "\(state)",
            "\(screenKind)",
            "rows=\(resumePickerProjection.rows.count)",
            "selected=\(selectedCount)",
            "fresh=\(resumePickerRequiresFreshSelection)",
            "visibleMarker=\(Self.containsTerminalSelectionMarker(frame.visibleText))",
            "screenMarker=\(Self.containsTerminalSelectionMarker(frame.screenText))",
            "snapshotLines=\(snapshot?.lines.count ?? -1)"
        ].joined(separator: " ")

        guard signature != lastResumePickerDiagnosticSignature else { return }
        lastResumePickerDiagnosticSignature = signature

        NSLog(
            """
            [PenggieResumePickerDiagnostic] %@
            visibleRows=%@
            screenRows=%@
            snapshotRows=%@
            projectedRows=%@
            """,
            signature,
            Self.debugResumeLines(in: frame.visibleText),
            Self.debugResumeLines(in: frame.screenText),
            Self.debugSnapshotLines(snapshot),
            Self.debugProjectionRows(resumePickerProjection.rows)
        )
    }

    private static func debugResumeLines(in text: String) -> String {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter(Self.looksLikeResumePickerRow)
            .prefix(8)
            .joined(separator: " | ")
    }

    private static func debugSnapshotLines(_ snapshot: PenggieTerminalScreenSnapshot?) -> String {
        guard let snapshot else { return "<nil>" }
        return snapshot.lines
            .filter {
                Self.looksLikeResumePickerRow($0.text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .prefix(8)
            .map { line in
                let style = line.styleSummary.map {
                    "sel=\($0.selectedCellCount),selText=\($0.selectedTextCellCount),inv=\($0.inverseTextCellCount),bg=\($0.backgroundTextCellCount),fg=\($0.foregroundTextCellCount),faint=\($0.faintTextCellCount)"
                } ?? "style=nil"
                return "#\(line.index):\(line.text)[selected=\(line.selected),\(style)]"
            }
            .joined(separator: " | ")
    }

    private static func looksLikeResumePickerRow(_ line: String) -> Bool {
        var candidate = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if hasTerminalSelectionMarker(candidate) {
            candidate.removeFirst()
            candidate = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return candidate.range(
            of: #"^\d+\s*(?:s|m|h|d|w|mo|y)\s+ago\s+\S"#,
            options: .regularExpression
        ) != nil
    }

    private static func containsTerminalSelectionMarker(_ text: String) -> Bool {
        text.contains("›") || text.contains("❯")
    }

    private static func hasTerminalSelectionMarker(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("›") || trimmed.hasPrefix("❯")
    }

    private static func debugProjectionRows(_ rows: [PenggieCodexResumePickerRow]) -> String {
        rows.prefix(8)
            .map { row in
                "\(row.isSelected ? "*" : "-")#\(row.sourceLineIndex):\(row.age):\(row.title)"
            }
            .joined(separator: " | ")
    }

    private func logTerminalInteractionSurfaceDiagnosticIfNeeded(
        from frame: PenggieTerminalFrame,
        surface: PenggieTerminalInteractionSurface?
    ) {
        guard let surface,
              surface.kind == .resumePicker,
              !surface.candidates.isEmpty,
              !surface.hasFreshConfirmableSelection else {
            return
        }

        let selectionSummary: String
        let selectionEvidence: [String]
        switch surface.selection {
        case let .single(rowID, source, evidence):
            selectionSummary = "single(\(rowID),\(source))"
            selectionEvidence = evidence
        case let .ambiguous(evidence):
            selectionSummary = "ambiguous"
            selectionEvidence = evidence
        case let .none(evidence):
            selectionSummary = "none"
            selectionEvidence = evidence
        }

        let signature = [
            "frame=\(frame.id)",
            "\(state)",
            "\(surface.kind)",
            "candidates=\(surface.candidates.count)",
            "selection=\(selectionSummary)",
            "confidence=\(surface.selectionConfidence)",
            "freshness=\(surface.freshness)",
            "visibleMarker=\(Self.containsTerminalSelectionMarker(frame.visibleText))",
            "screenMarker=\(Self.containsTerminalSelectionMarker(frame.screenText))",
            "snapshotLines=\(frame.snapshot?.lines.count ?? -1)"
        ].joined(separator: " ")

        guard signature != lastResumePickerDiagnosticSignature else { return }
        lastResumePickerDiagnosticSignature = signature

        let candidateSummary = surface.candidates.prefix(8).map { candidate in
            "#\(candidate.sourceLineIndex):\(candidate.id):\(candidate.text)"
        }.joined(separator: " | ")

        NSLog(
            """
            [PenggieTerminalInteractionSurfaceDiagnostic] %@
            surfaceEvidence=%@
            selectionEvidence=%@
            candidates=%@
            visibleRows=%@
            screenRows=%@
            snapshotRows=%@
            """,
            signature,
            surface.evidence.joined(separator: " | "),
            selectionEvidence.joined(separator: " | "),
            candidateSummary,
            Self.debugResumeLines(in: frame.visibleText),
            Self.debugResumeLines(in: frame.screenText),
            Self.debugSnapshotLines(frame.snapshot)
        )
        Self.appendDebugDiagnostic(
            fileName: "terminal-interaction-surface-diagnostic.log",
            message: """
            [PenggieTerminalInteractionSurfaceDiagnostic] \(Date())
            \(signature)
            surfaceEvidence=\(surface.evidence.joined(separator: " | "))
            selectionEvidence=\(selectionEvidence.joined(separator: " | "))
            candidates=\(candidateSummary)
            visibleRows=\(Self.debugResumeLines(in: frame.visibleText))
            screenRows=\(Self.debugResumeLines(in: frame.screenText))
            snapshotRows=\(Self.debugSnapshotLines(frame.snapshot))

            """
        )
    }

    private static func appendDebugDiagnostic(fileName: String, message: String) {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("Penggie", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appendingPathComponent(fileName)
            let data = Data(message.utf8)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let handle = try FileHandle(forWritingTo: fileURL)
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.close()
            } else {
                try data.write(to: fileURL)
            }
        } catch {
            NSLog("[PenggieDiagnosticWriteFailed] %@ %@", fileName, String(describing: error))
        }
    }

    private func logActiveInputStyleDiagnosticIfNeeded(
        from frame: PenggieTerminalFrame,
        screenKind: PenggieCodexScreenKind
    ) {
        guard screenKind != .resumePicker,
              let snapshot = frame.snapshot else {
            return
        }

        let candidates = Self.debugActiveInputCandidateLines(in: snapshot)
        guard !candidates.isEmpty else { return }

        let signature = [
            "frame=\(frame.id)",
            "\(state)",
            "\(screenKind)",
            "cursor=\(snapshot.cursor.map { "\($0.x),\($0.y),visible=\($0.visible)" } ?? "nil")",
            Self.debugActiveInputLines(candidates)
        ].joined(separator: " ")

        guard signature != lastActiveInputStyleDiagnosticSignature else { return }
        lastActiveInputStyleDiagnosticSignature = signature

        NSLog(
            """
            [PenggieActiveInputStyleDiagnostic] %@
            lines=%@
            """,
            signature,
            Self.debugActiveInputLines(candidates)
        )
    }

    private static func debugActiveInputCandidateLines(
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
            .prefix(8)
            .map { $0 }
    }

    private static func debugActiveInputLines(_ lines: [PenggieTerminalScreenSnapshot.Line]) -> String {
        lines
            .map { line in
                let summary = line.styleSummary.map {
                    "summary{text=\($0.textCellCount),sel=\($0.selectedCellCount),inv=\($0.inverseTextCellCount),bgText=\($0.backgroundTextCellCount),bg=\($0.backgroundCellCount),fg=\($0.foregroundTextCellCount),faint=\($0.faintTextCellCount)}"
                } ?? "summary=nil"
                let runs = line.styleRuns
                    .prefix(6)
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
#endif

    private func updateInitialDisplayReadyGate(with target: PenggieCodexDisplayReadyTarget?) {
        guard !hasReachedStableCodexScreen else { return }

        guard let target else {
            resetDisplayReadyGate()
            return
        }

        if pendingDisplayReadyTarget == target {
            pendingDisplayReadyPollCount += 1
        } else {
            pendingDisplayReadyTarget = target
            pendingDisplayReadyPollCount = 1
        }

        if pendingDisplayReadyPollCount >= 2 {
            hasReachedStableCodexScreen = true
        }
    }

    private func resetDisplayReadyGate() {
        pendingDisplayReadyTarget = nil
        pendingDisplayReadyPollCount = 0
    }

    private func nextTerminalFrame(
        visibleText: String,
        screenText: String,
        screenModelJSON: String?,
        processExited: Bool
    ) -> PenggieTerminalFrame {
        terminalFrameID += 1
        return PenggieTerminalFrame(
            id: terminalFrameID,
            observedAt: Date(),
            visibleText: visibleText,
            screenText: screenText,
            screenModelJSON: screenModelJSON,
            processExited: processExited
        )
    }

    private func updateReadingBlocks(
        from frame: PenggieTerminalFrame,
        projectionText: String,
        currentScreenKind: PenggieCodexScreenKind? = nil
    ) {
        updateReadingBlocks(
            from: projectionText,
            currentScreenKind: currentScreenKind,
            observedAt: frame.observedAt
        )
    }

    private func updateReadingBlocks(
        from projectionText: String,
        currentScreenKind: PenggieCodexScreenKind? = nil,
        observedAt: Date = Date()
    ) {
        let refreshSecond = Int(observedAt.timeIntervalSince1970)
        let projectionChanged = projectionText != lastReadingProjectionText

        if !projectionChanged {
            guard !readingTurnStore.canSubmitPrompt,
                  lastReadingProjectionRefreshSecond != refreshSecond else {
                return
            }

            lastReadingProjectionRefreshSecond = refreshSecond
            readingTurnStore.refreshActiveTurnTiming(at: observedAt)
            readingBlocks = readingResumeHydrator.combined(with: readingTurnStore.blocks)
            return
        }

        lastReadingProjectionText = projectionText
        lastReadingProjectionRefreshSecond = refreshSecond

        let effectiveScreenKind = currentScreenKind ?? PenggieCodexScreenKind.detect(in: projectionText)
        if effectiveScreenKind.isTerminalOwnedInteraction || effectiveScreenKind.isLaunchBlockingScreen {
            readingResumeHydrator.reset()
            readingBlocks = readingTurnStore.blocks
            return
        }

        if codexScreenKind.isTerminalOwnedInteraction {
            readingResumeHydrator.reset()
            readingBlocks = readingTurnStore.blocks
            return
        }

        if readingTurnStore.isEmpty {
            readingResumeHydrator.update(
                from: projectionText,
                terminalColumns: nil,
                createdAt: observedAt
            )
            readingBlocks = readingResumeHydrator.blocks
            return
        }

        readingTurnStore.updateActiveTurn(
            from: projectionText,
            terminalColumns: nil,
            createdAt: observedAt
        )
        readingBlocks = readingResumeHydrator.combined(with: readingTurnStore.blocks)
    }

    private func resetReadingProjectionCache() {
        lastReadingProjectionText = ""
        lastReadingProjectionRefreshSecond = nil
    }

    private func sendNativeKey(_ command: PenggieInteractionCommand) -> Bool {
        guard let ghosttySession else { return false }

        if command == .enter {
            return ghosttySession.sendEnterKey()
        }

        let sent = ghosttySession.sendKeyCode(
            Self.keyCode(for: command),
            text: Self.keyText(for: command),
            unshiftedCodepoint: Self.unshiftedCodepoint(for: command)
        )
        if sent {
            return true
        }

        guard let fallbackText = Self.fallbackText(for: command) else { return false }
        ghosttySession.sendText(fallbackText)
        return true
    }

    private func updateNativeDisplayText(after command: PenggieInteractionCommand) {
        switch command {
        case .escape:
            endNativeInteraction()
        case .enter:
            nativeInteractionPhase = .resolving
            nativeInteractionDisplayText = ""
            nativeInteractionResolvingBeganAt = Date()
        case .backspace:
            if nativeInteractionDisplayText.count > 1 {
                nativeInteractionDisplayText.removeLast()
            } else {
                endNativeInteraction()
            }
        case .tab, .arrowUp, .arrowDown, .arrowLeft, .arrowRight, .delete:
            break
        }
    }

    private func endNativeInteraction() {
        nativeInteractionPhase = .inactive
        nativeInteractionDisplayText = ""
        nativeInteractionResolvingBeganAt = nil
        nativeInteractionEscapeSentAt = nil
        nativeInteractionRows = []
    }

    private func updateNativeInteractionRows(
        from frame: PenggieTerminalFrame
    ) {
        guard nativeInteractionIsActive else {
            nativeInteractionRows = []
            return
        }

        let screenModelRows = frame.snapshot
            .map {
                PenggieNativeInteractionProjection.rows(
                    from: $0,
                    currentInput: nativeInteractionDisplayText
                )
            } ?? []
        let rows = screenModelRows.isEmpty
            ? PenggieNativeInteractionProjection.rowsFromVisibleText(
                frame.visibleText,
                currentInput: nativeInteractionDisplayText
            )
            : screenModelRows

        if let escapeSentAt = nativeInteractionEscapeSentAt {
            if rows.isEmpty {
                endNativeInteraction()
                return
            }

            if Date().timeIntervalSince(escapeSentAt) >= PenggieNativeInteractionTiming.escapeObservationInterval {
                nativeInteractionEscapeSentAt = nil
            }
        }

        switch nativeInteractionPhase {
        case .editing, .continuation:
            nativeInteractionRows = rows
        case .resolving:
            if PenggieNativeInteractionProjection.containsContinuationMenu(rows.map(\.text)) {
                nativeInteractionPhase = .continuation
                nativeInteractionRows = rows
                nativeInteractionResolvingBeganAt = nil
                return
            }

            nativeInteractionRows = rows
            if let beganAt = nativeInteractionResolvingBeganAt,
               Date().timeIntervalSince(beganAt) >= PenggieNativeInteractionTiming.resolvingSettleInterval {
                endNativeInteraction()
            }
        case .inactive:
            nativeInteractionRows = []
        }
    }

    static func keyCode(for command: PenggieInteractionCommand) -> UInt16 {
        switch command {
        case .tab:
            return 48
        case .enter:
            return 36
        case .escape:
            return 53
        case .arrowUp:
            return 126
        case .arrowDown:
            return 125
        case .arrowLeft:
            return 123
        case .arrowRight:
            return 124
        case .backspace:
            return 51
        case .delete:
            return 117
        }
    }

    static func keyText(for command: PenggieInteractionCommand) -> String? {
        switch command {
        case .tab:
            return "\t"
        case .enter:
            return "\r"
        case .backspace:
            return "\u{7F}"
        case .escape, .arrowUp, .arrowDown, .arrowLeft, .arrowRight, .delete:
            return nil
        }
    }

    static func unshiftedCodepoint(for command: PenggieInteractionCommand) -> UInt32 {
        switch command {
        case .tab:
            return 9
        case .enter:
            return 13
        case .backspace:
            return 127
        case .escape, .arrowUp, .arrowDown, .arrowLeft, .arrowRight, .delete:
            return 0
        }
    }

    private static func fallbackText(for command: PenggieInteractionCommand) -> String? {
        switch command {
        case .tab:
            return "\t"
        case .enter:
            return "\r"
        case .escape:
            return "\u{1B}"
        case .arrowUp:
            return "\u{1B}[A"
        case .arrowDown:
            return "\u{1B}[B"
        case .arrowLeft:
            return "\u{1B}[D"
        case .arrowRight:
            return "\u{1B}[C"
        case .backspace:
            return "\u{7F}"
        case .delete:
            return "\u{1B}[3~"
        }
    }

    nonisolated private static func resolveCodexCommandPath() async -> String? {
        let command = ProcessInfo.processInfo.environment[codexCommandEnvironmentKey]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let requestedCommand = command?.isEmpty == false ? command! : "codex"

        if requestedCommand.contains("/") {
            return FileManager.default.isExecutableFile(atPath: requestedCommand)
                ? requestedCommand
                : nil
        }

        return await commandPathInLoginShell(requestedCommand)
    }

    nonisolated private static var shouldForceLaunchFailureForVerification: Bool {
        let value = ProcessInfo.processInfo.environment[forceLaunchFailureEnvironmentKey]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return value == "1" || value == "true" || value == "yes"
    }

    nonisolated private static func commandPathInLoginShell(_ command: String) async -> String? {
        await withCheckedContinuation { continuation in
            let process = Process()
            let output = Pipe()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-lc", "command -v \(shellQuoted(command))"]
            process.standardOutput = output
            process.standardError = Pipe()

            process.terminationHandler = { process in
                guard process.terminationStatus == 0 else {
                    continuation.resume(returning: nil)
                    return
                }

                let data = output.fileHandleForReading.readDataToEndOfFile()
                let path = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(returning: path?.isEmpty == false ? path : nil)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    nonisolated private static func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    nonisolated private static func restoreLastWorkingDirectory() -> URL? {
        guard let path = UserDefaults.standard.string(forKey: lastWorkingDirectoryDefaultsKey),
              !path.isEmpty else {
            return nil
        }

        let url = URL(fileURLWithPath: path)
        return isUsableWorkingDirectory(url) ? url : nil
    }

    nonisolated private static func storeLastWorkingDirectory(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: lastWorkingDirectoryDefaultsKey)
    }

    nonisolated private static func isUsableWorkingDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) &&
            isDirectory.boolValue &&
            FileManager.default.isReadableFile(atPath: url.path)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

enum Confirmation: Identifiable {
    case newChat
    case closeSession

    var id: String {
        switch self {
        case .newChat:
            return "new-chat"
        case .closeSession:
            return "close-session"
        }
    }

    var title: String {
        switch self {
        case .newChat:
            return "Start a new chat?"
        case .closeSession:
            return "End this Codex session?"
        }
    }

    var message: String {
        switch self {
        case .newChat:
            return "This ends the current session and starts a fresh Codex session in this window."
        case .closeSession:
            return "This ends the current Codex session and returns to the Penggie start screen."
        }
    }

    var confirmationButtonTitle: String {
        switch self {
        case .newChat:
            return "Start New Chat"
        case .closeSession:
            return "End Session"
        }
    }
}
