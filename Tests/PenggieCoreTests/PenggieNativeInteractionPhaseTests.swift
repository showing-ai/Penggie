import Testing
@testable import PenggieCore

@Suite
struct PenggieNativeInteractionPhaseTests {
    @Test
    func editingAndContinuationOwnComposerInput() {
        #expect(PenggieNativeInteractionPhase.editing.isActive)
        #expect(PenggieNativeInteractionPhase.editing.acceptsInput)
        #expect(PenggieNativeInteractionPhase.editing.capturesTextInput)
        #expect(PenggieNativeInteractionPhase.continuation.isActive)
        #expect(PenggieNativeInteractionPhase.continuation.acceptsInput)
        #expect(PenggieNativeInteractionPhase.continuation.capturesTextInput)
    }

    @Test
    func resolvingDoesNotAcceptInput() {
        #expect(PenggieNativeInteractionPhase.resolving.isActive)
        #expect(!PenggieNativeInteractionPhase.resolving.acceptsInput)
        #expect(!PenggieNativeInteractionPhase.inactive.isActive)
    }
}
