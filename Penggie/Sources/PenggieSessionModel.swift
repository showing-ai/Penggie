import AppKit
import Foundation
import SwiftUI

@MainActor
final class PenggieSessionModel: ObservableObject {
    static let codexCommandEnvironmentKey = "PENGGIE_CODEX_COMMAND"
    static let forceLaunchFailureEnvironmentKey = "PENGGIE_FORCE_LAUNCH_FAILURE"

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
    @Published private(set) var nativeInteractionRows: [String] = []
    @Published var pendingConfirmation: Confirmation?

    let substrate = PenggieGhosttySubstrate()
    private var screenPollTask: Task<Void, Never>?
    private var nativeInteractionResolvingBeganAt: Date?
    private var composerSubmissions: [PenggieComposerSubmission] = []
    private var consumedComposerSubmissionIDs = Set<UUID>()

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
        case .reading, .terminal, .exited:
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

    var projectDisplayName: String {
        FileManager.default.homeDirectoryForCurrentUser.lastPathComponent
    }

    func startWithCodex() {
        guard canStartCodex else { return }
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

    private func launchCodexSession() {
        guard substrate.isAvailable else {
            state = .launchFailed("Penggie could not initialize the terminal session.")
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
                        workingDirectory: FileManager.default.homeDirectoryForCurrentUser.path
                    )
                    session.onExit = { [weak self] in
                        self?.state = .exited
                    }
                    self.ghosttySession = session
                    self.transcriptText = ""
                    self.readingBlocks = []
                    self.composerSubmissions = []
                    self.consumedComposerSubmissionIDs = []
                    self.startScreenPolling()
                    self.state = .reading
                } catch {
                    self.state = .launchFailed(error.localizedDescription)
                }
            }
        }
    }

    func sendPrompt(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        composerSubmissions.append(.init(text: trimmed, submittedAt: Date()))
        ghosttySession?.sendPrompt(trimmed)
        startScreenPolling()
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
    func sendNativeInteractionEnter() -> Bool {
        sendNativeInteractionCommand(.enter)
    }

    @discardableResult
    func cancelNativeInteraction() -> Bool {
        guard nativeInteractionPhase.acceptsInput else { return false }
        nativeInteractionPhase = .cancelling
        let sent = sendNativeKey(.escape)
        endNativeInteraction()
        return sent
    }

    private func closeCurrentSession() {
        screenPollTask?.cancel()
        screenPollTask = nil
        ghosttySession?.close()
        ghosttySession = nil
        transcriptText = ""
        readingBlocks = []
        composerSubmissions = []
        consumedComposerSubmissionIDs = []
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
                    let screenModelJSON = session.readScreenModelJSON()
                    self.transcriptText = visibleText
                    if !self.nativeInteractionIsActive {
                        self.updateReadingBlocks(from: visibleText)
                    }
                    self.updateNativeInteractionRows(
                        from: visibleText,
                        screenModelJSON: screenModelJSON
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

    private func updateReadingBlocks(from visibleText: String) {
        readingBlocks = PenggieReadingProjectionModel.blocks(
            from: visibleText,
            terminalColumns: nil,
            previousBlocks: readingBlocks,
            composerSubmissions: composerSubmissions,
            consumedComposerSubmissionIDs: consumedComposerSubmissionIDs
        )
        consumedComposerSubmissionIDs.formUnion(
            readingBlocks.compactMap(\.composerSubmissionID)
        )
    }

    private func sendNativeKey(_ command: PenggieInteractionCommand) -> Bool {
        guard let ghosttySession else { return false }

        let sent = ghosttySession.sendKeyCode(Self.keyCode(for: command))
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
        nativeInteractionRows = []
    }

    private func updateNativeInteractionRows(
        from visibleText: String,
        screenModelJSON: String?
    ) {
        guard nativeInteractionIsActive else {
            nativeInteractionRows = []
            return
        }

        let screenModelRows = screenModelJSON
            .flatMap(PenggieTerminalScreenSnapshot.init(json:))
            .map {
                PenggieNativeInteractionProjection.rows(
                    from: $0,
                    currentInput: nativeInteractionDisplayText
                ).map(\.text)
            } ?? []
        let rows = screenModelRows.isEmpty
            ? PenggieNativeInteractionProjection.rows(fromVisibleText: visibleText)
            : screenModelRows

        switch nativeInteractionPhase {
        case .editing, .continuation:
            nativeInteractionRows = rows
        case .resolving:
            if PenggieNativeInteractionProjection.containsContinuationMenu(rows) {
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
        case .inactive, .cancelling:
            nativeInteractionRows = []
        }
    }

    private static func keyCode(for command: PenggieInteractionCommand) -> UInt16 {
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
}
