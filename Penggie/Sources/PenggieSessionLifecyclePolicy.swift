enum PenggieSessionDisplayMode: Equatable {
    case reading
    case terminal
}

enum PenggieSessionLifecyclePhase: Equatable {
    case idle
    case checkingCodex
    case launching
    case reading(hasStableCodexScreen: Bool)
    case terminal(hasStableCodexScreen: Bool)
    case codexMissing
    case launchFailed
    case exited
    case closed
}

enum PenggieSessionDisplayTransition: Equatable {
    case noOp
    case setDisplayMode(PenggieSessionDisplayMode)
}

enum PenggieSessionLifecyclePolicy {
    static func canStartCodex(in phase: PenggieSessionLifecyclePhase) -> Bool {
        switch phase {
        case .idle, .codexMissing, .launchFailed, .exited, .closed:
            return true
        case .checkingCodex, .launching, .reading, .terminal:
            return false
        }
    }

    static func hasInspectableSession(in phase: PenggieSessionLifecyclePhase) -> Bool {
        switch phase {
        case .reading(let hasStableCodexScreen), .terminal(let hasStableCodexScreen):
            return hasStableCodexScreen
        case .exited:
            return true
        case .idle, .checkingCodex, .launching, .codexMissing, .launchFailed, .closed:
            return false
        }
    }

    static func isRunning(in phase: PenggieSessionLifecyclePhase) -> Bool {
        switch phase {
        case .reading, .terminal:
            return true
        case .idle, .checkingCodex, .launching, .codexMissing, .launchFailed, .exited, .closed:
            return false
        }
    }

    static func canSubmitPrompt(
        in phase: PenggieSessionLifecyclePhase,
        isTerminalOwnedInteraction: Bool,
        turnStoreCanSubmitPrompt: Bool
    ) -> Bool {
        isRunning(in: phase)
            && hasInspectableSession(in: phase)
            && !isTerminalOwnedInteraction
            && turnStoreCanSubmitPrompt
    }

    static func displayTransition(
        from phase: PenggieSessionLifecyclePhase,
        to targetMode: PenggieSessionDisplayMode
    ) -> PenggieSessionDisplayTransition {
        guard hasInspectableSession(in: phase) else {
            return .noOp
        }

        switch (phase, targetMode) {
        case (.reading, .terminal):
            return .setDisplayMode(.terminal)
        case (.terminal, .reading):
            return .setDisplayMode(.reading)
        default:
            return .noOp
        }
    }
}
