import Testing
@testable import PenggieCore

@Suite
struct PenggieSessionLifecyclePolicyTests {
    @Test
    func launchPhasesBlockInspectableActionsAndPromptSubmission() {
        for phase in [PenggieSessionLifecyclePhase.checkingCodex, .launching] {
            #expect(!PenggieSessionLifecyclePolicy.hasInspectableSession(in: phase))
            #expect(!PenggieSessionLifecyclePolicy.canStartCodex(in: phase))
            #expect(!PenggieSessionLifecyclePolicy.isRunning(in: phase))
            #expect(PenggieSessionLifecyclePolicy.displayTransition(from: phase, to: .terminal) == .noOp)
            #expect(!PenggieSessionLifecyclePolicy.canSubmitPrompt(
                in: phase,
                isTerminalOwnedInteraction: false,
                turnStoreCanSubmitPrompt: true
            ))
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
