import Testing
@testable import PenggieCore

@Suite
struct PenggieSessionLifecyclePolicyTests {
    @Test
    func setupAndRecoveryPhasesAreStartableButNotInspectable() {
        let startableNonInspectablePhases: [PenggieSessionLifecyclePhase] = [
            .idle,
            .closed,
            .codexMissing,
            .launchFailed,
        ]

        for phase in startableNonInspectablePhases {
            #expect(PenggieSessionLifecyclePolicy.canStartCodex(in: phase))
            #expect(!PenggieSessionLifecyclePolicy.hasInspectableSession(in: phase))
            #expect(!PenggieSessionLifecyclePolicy.isRunning(in: phase))
            #expect(PenggieSessionLifecyclePolicy.displayTransition(from: phase, to: .terminal) == .noOp)
            #expect(PenggieSessionLifecyclePolicy.displayTransition(from: phase, to: .reading) == .noOp)
            #expect(!PenggieSessionLifecyclePolicy.canSubmitPrompt(
                in: phase,
                isTerminalOwnedInteraction: false,
                turnStoreCanSubmitPrompt: true
            ))
        }
    }

    @Test
    func nonInspectableStartupPhasesBlockInspectableActionsAndPromptSubmission() {
        let nonInspectableStartupPhases: [PenggieSessionLifecyclePhase] = [
            .checkingCodex,
            .launching,
            .reading(hasStableCodexScreen: false),
            .terminal(hasStableCodexScreen: false),
        ]

        for phase in nonInspectableStartupPhases {
            #expect(!PenggieSessionLifecyclePolicy.hasInspectableSession(in: phase))
            #expect(!PenggieSessionLifecyclePolicy.canStartCodex(in: phase))
            #expect(PenggieSessionLifecyclePolicy.displayTransition(from: phase, to: .terminal) == .noOp)
            #expect(PenggieSessionLifecyclePolicy.displayTransition(from: phase, to: .reading) == .noOp)
            #expect(!PenggieSessionLifecyclePolicy.canSubmitPrompt(
                in: phase,
                isTerminalOwnedInteraction: false,
                turnStoreCanSubmitPrompt: true
            ))
        }

        for phase in [PenggieSessionLifecyclePhase.checkingCodex, .launching] {
            #expect(!PenggieSessionLifecyclePolicy.isRunning(in: phase))
        }

        for phase in [
            PenggieSessionLifecyclePhase.reading(hasStableCodexScreen: false),
            .terminal(hasStableCodexScreen: false),
        ] {
            #expect(PenggieSessionLifecyclePolicy.isRunning(in: phase))
        }
    }

    @Test
    func rawTerminalAvailabilityRequiresInspectableSessionOrExitedSession() {
        #expect(!PenggieSessionLifecyclePolicy.hasInspectableSession(
            in: .reading(hasStableCodexScreen: false)
        ))
        #expect(!PenggieSessionLifecyclePolicy.hasInspectableSession(
            in: .terminal(hasStableCodexScreen: false)
        ))

        #expect(PenggieSessionLifecyclePolicy.hasInspectableSession(
            in: .reading(hasStableCodexScreen: true)
        ))
        #expect(PenggieSessionLifecyclePolicy.hasInspectableSession(
            in: .terminal(hasStableCodexScreen: true)
        ))
        #expect(PenggieSessionLifecyclePolicy.hasInspectableSession(in: .exited))
    }

    @Test
    func lowConfidenceFallbackAuditCanSwitchToRawTerminalWhenSessionIsInspectable() {
        let stableReading = PenggieSessionLifecyclePhase.reading(hasStableCodexScreen: true)
        #expect(PenggieSessionLifecyclePolicy.hasInspectableSession(in: stableReading))
        #expect(PenggieSessionLifecyclePolicy.displayTransition(
            from: stableReading,
            to: .terminal
        ) == .setDisplayMode(.terminal))

        let unstableReading = PenggieSessionLifecyclePhase.reading(hasStableCodexScreen: false)
        #expect(!PenggieSessionLifecyclePolicy.hasInspectableSession(in: unstableReading))
        #expect(PenggieSessionLifecyclePolicy.displayTransition(
            from: unstableReading,
            to: .terminal
        ) == .noOp)
    }

    @Test
    func exitedSessionIsInspectableButNotRunningOrPromptSubmittable() {
        #expect(PenggieSessionLifecyclePolicy.hasInspectableSession(in: .exited))
        #expect(!PenggieSessionLifecyclePolicy.isRunning(in: .exited))
        #expect(PenggieSessionLifecyclePolicy.canStartCodex(in: .exited))
        #expect(!PenggieSessionLifecyclePolicy.canSubmitPrompt(
            in: .exited,
            isTerminalOwnedInteraction: false,
            turnStoreCanSubmitPrompt: true
        ))
    }

    @Test
    func readingTerminalSwitchesAreModeOnlyAfterStableInspectableSession() {
        #expect(PenggieSessionLifecyclePolicy.displayTransition(
            from: .reading(hasStableCodexScreen: false),
            to: .terminal
        ) == .noOp)
        #expect(PenggieSessionLifecyclePolicy.displayTransition(
            from: .terminal(hasStableCodexScreen: false),
            to: .reading
        ) == .noOp)

        #expect(PenggieSessionLifecyclePolicy.displayTransition(
            from: .reading(hasStableCodexScreen: true),
            to: .terminal
        ) == .setDisplayMode(.terminal))
        #expect(PenggieSessionLifecyclePolicy.displayTransition(
            from: .terminal(hasStableCodexScreen: true),
            to: .reading
        ) == .setDisplayMode(.reading))
    }

    @Test
    func terminalOwnedInteractionBlocksPromptEvenWhenSessionIsRunning() {
        #expect(PenggieSessionLifecyclePolicy.canSubmitPrompt(
            in: .reading(hasStableCodexScreen: true),
            isTerminalOwnedInteraction: false,
            turnStoreCanSubmitPrompt: true
        ))
        #expect(!PenggieSessionLifecyclePolicy.canSubmitPrompt(
            in: .reading(hasStableCodexScreen: true),
            isTerminalOwnedInteraction: true,
            turnStoreCanSubmitPrompt: true
        ))
        #expect(!PenggieSessionLifecyclePolicy.canSubmitPrompt(
            in: .terminal(hasStableCodexScreen: true),
            isTerminalOwnedInteraction: false,
            turnStoreCanSubmitPrompt: false
        ))
    }
}
