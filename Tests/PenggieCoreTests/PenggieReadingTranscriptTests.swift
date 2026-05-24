import Foundation
import Testing
@testable import PenggieCore

@Suite
struct PenggieReadingTranscriptTests {
    @Test
    func blockizesStartupAndPrompt() {
        let projection = """
        ╭────────────────────────╮
        │ >_ OpenAI Codex        │
        │ model: test            │
        ╰────────────────────────╯

        › Say hello

          hello
        """

        let blocks = PenggieReadingProjectionModel.blocks(from: projection, terminalColumns: 80)

        #expect(blocks.first?.variant == .startup)
        #expect(blocks.contains { $0.variant == .prompt })
        #expect(blocks.contains { PenggieReadingPresentation.chatText(for: $0).contains("hello") })
    }

    @Test
    func promotesComposerOwnedPromptToInputBlock() throws {
        let submission = PenggieComposerSubmission(text: "Say hello", submittedAt: Date())
        let projection = """
        › Say hello

          hello
        """

        let blocks = PenggieReadingProjectionModel.blocks(
            from: projection,
            terminalColumns: 80,
            composerSubmissions: [submission]
        )

        let prompt = try #require(blocks.first)
        #expect(prompt.kind == .input)
        #expect(prompt.displayText == "Say hello")
        #expect(prompt.composerSubmissionID == submission.id)
    }

    @Test
    func classifiesToolLikeOutput() {
        let projection = """
        Ran ls

        • Done
        """

        let blocks = PenggieReadingProjectionModel.blocks(from: projection, terminalColumns: 80)

        #expect(blocks.first?.variant == .toolLike)
        #expect(blocks.last?.variant == .proseLike)
    }
}
