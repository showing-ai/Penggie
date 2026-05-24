import Foundation
import SwiftUI

@MainActor
final class PenggieSessionModel: ObservableObject {
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
    @Published private(set) var ghosttySession: PenggieGhosttySession?
    @Published var pendingConfirmation: Confirmation?

    let substrate = PenggieGhosttySubstrate()
    private var screenPollTask: Task<Void, Never>?

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
            let isAvailable = await Self.commandExistsInLoginShell("codex")
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

        Task {
            let codexPath = await Self.commandPathInLoginShell("codex")
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
        ghosttySession?.sendPrompt(trimmed)
        startScreenPolling()
    }

    private func closeCurrentSession() {
        screenPollTask?.cancel()
        screenPollTask = nil
        ghosttySession?.close()
        ghosttySession = nil
        transcriptText = ""
    }

    private func startScreenPolling() {
        screenPollTask?.cancel()
        screenPollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                await MainActor.run {
                    guard let self, let session = self.ghosttySession else { return }
                    self.transcriptText = session.readVisibleText()
                }
            }
        }
    }

    nonisolated private static func commandExistsInLoginShell(_ command: String) async -> Bool {
        await commandPathInLoginShell(command) != nil
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
