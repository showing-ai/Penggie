import Foundation
import Testing
@testable import PenggieCore

@Suite
struct PenggieReadingTranscriptTests {
    @Test
    func turnStoreKeepsCompletedTurnsImmutableAcrossLaterTerminalProjections() throws {
        let base = Date()
        var store = PenggieReadingTurnStore()

        store.submitPrompt("First question", submittedAt: base)
        store.updateActiveTurn(
            from: "First answer",
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(10)
        )
        settleActiveTurn(
            &store,
            projection: "First answer",
            at: base.addingTimeInterval(10)
        )
        let frozenFirstBlocks = store.blocks

        store.submitPrompt("Second question", submittedAt: base.addingTimeInterval(20))
        store.updateActiveTurn(
            from: """
            Mutated first answer

            Second answer
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(30)
        )

        #expect(Array(store.blocks.prefix(frozenFirstBlocks.count)) == frozenFirstBlocks)
        #expect(visibleText(from: store.blocks) == [
            "First question",
            "Worked for 10s",
            "First answer",
            "Second question",
            "Worked for 10s",
            "Mutated first answer\n\nSecond answer"
        ])
    }

    @Test
    func turnStoreInterleavesThreeComposerTurnsWhenProjectionMergesAllAnswers() throws {
        let base = Date()
        var store = PenggieReadingTurnStore()

        store.submitPrompt("First question", submittedAt: base)
        store.updateActiveTurn(
            from: "First answer",
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(10)
        )
        settleActiveTurn(
            &store,
            projection: "First answer",
            at: base.addingTimeInterval(10)
        )

        store.submitPrompt("Second question", submittedAt: base.addingTimeInterval(20))
        store.updateActiveTurn(
            from: """
            First answer

            Second answer
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(30)
        )
        settleActiveTurn(
            &store,
            projection: """
            First answer

            Second answer
            """,
            at: base.addingTimeInterval(30)
        )

        store.submitPrompt("Third question", submittedAt: base.addingTimeInterval(40))
        store.updateActiveTurn(
            from: """
            First answer

            Second answer

            Third answer
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(50)
        )

        #expect(visibleText(from: store.blocks) == [
            "First question",
            "Worked for 10s",
            "First answer",
            "Second question",
            "Worked for 10s",
            "Second answer",
            "Third question",
            "Worked for 10s",
            "Third answer"
        ])
    }

    @Test
    func turnStoreDoesNotUpdateCompletedTurnWhenViewportDropsOldHistory() throws {
        let base = Date()
        var store = PenggieReadingTurnStore()

        store.submitPrompt("First question", submittedAt: base)
        store.updateActiveTurn(
            from: "First answer",
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(10)
        )
        settleActiveTurn(
            &store,
            projection: "First answer",
            at: base.addingTimeInterval(10)
        )

        store.submitPrompt("Second question", submittedAt: base.addingTimeInterval(20))
        store.updateActiveTurn(
            from: "Second answer",
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(30)
        )
        settleActiveTurn(
            &store,
            projection: "Second answer",
            at: base.addingTimeInterval(30)
        )

        store.submitPrompt("Third question", submittedAt: base.addingTimeInterval(40))
        store.updateActiveTurn(
            from: "Third answer",
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(50)
        )

        #expect(visibleText(from: store.blocks) == [
            "First question",
            "Worked for 10s",
            "First answer",
            "Second question",
            "Worked for 10s",
            "Second answer",
            "Third question",
            "Worked for 10s",
            "Third answer"
        ])
    }

    @Test
    func turnStoreUsesActivePromptEchoBoundaryWhenViewportStartsInsideCompletedTurn() throws {
        let base = Date()
        var store = PenggieReadingTurnStore()

        store.submitPrompt("First question", submittedAt: base)
        store.updateActiveTurn(
            from: """
            First answer opening

            4. Previous answer tail
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(10)
        )
        settleActiveTurn(
            &store,
            projection: """
            First answer opening

            4. Previous answer tail
            """,
            at: base.addingTimeInterval(10)
        )

        store.submitPrompt("Second question", submittedAt: base.addingTimeInterval(20))
        store.updateActiveTurn(
            from: """
            4. Previous answer tail

            › Second question

            Second answer
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(30)
        )

        #expect(visibleText(from: store.blocks) == [
            "First question",
            "Worked for 10s",
            "First answer opening\n\n4. Previous answer tail",
            "Second question",
            "Worked for 10s",
            "Second answer"
        ])
    }

    @Test
    func turnStoreStripsLeadingCompletedOverlapWhenPromptEchoIsNotVisible() throws {
        let base = Date()
        var store = PenggieReadingTurnStore()

        store.submitPrompt("First question", submittedAt: base)
        store.updateActiveTurn(
            from: """
            First answer opening

            4. Previous answer tail
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(10)
        )
        settleActiveTurn(
            &store,
            projection: """
            First answer opening

            4. Previous answer tail
            """,
            at: base.addingTimeInterval(10)
        )

        store.submitPrompt("Second question", submittedAt: base.addingTimeInterval(20))
        store.updateActiveTurn(
            from: """
            4. Previous answer tail

            Second answer
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(30)
        )

        #expect(visibleText(from: store.blocks) == [
            "First question",
            "Worked for 10s",
            "First answer opening\n\n4. Previous answer tail",
            "Second question",
            "Worked for 10s",
            "Second answer"
        ])
    }

    @Test
    func turnStoreAccumulatesActiveTurnWhenVisibleProjectionAdvances() throws {
        let base = Date()
        var store = PenggieReadingTurnStore()

        store.submitPrompt("Long question", submittedAt: base)
        store.updateActiveTurn(
            from: """
            First part of the answer.

            Middle part of the answer.
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(10)
        )
        store.updateActiveTurn(
            from: """
            Middle part of the answer.

            Final part of the answer.
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(20)
        )

        #expect(visibleText(from: store.blocks) == [
            "Long question",
            "Worked for 10s",
            "First part of the answer.\n\nMiddle part of the answer.",
            "Final part of the answer."
        ])
    }

    @Test
    func turnStoreDoesNotLetStaleWorkingStatusHideFinalAnswer() throws {
        let base = Date()
        var store = PenggieReadingTurnStore()

        store.submitPrompt("Explain London", submittedAt: base)
        store.updateActiveTurn(
            from: """
            Searching the web

            Working (0s • esc to interrupt)
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(1)
        )
        store.updateActiveTurn(
            from: """
            London is the capital of the United Kingdom.

            It is also a major financial and cultural center.
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(10)
        )

        #expect(visibleText(from: store.blocks) == [
            "Explain London",
            "Worked for 10s",
            "London is the capital of the United Kingdom.\n\nIt is also a major financial and cultural center."
        ])
    }

    @Test
    func turnStoreDoesNotDuplicateRepeatedStableSnapshots() throws {
        let base = Date()
        var store = PenggieReadingTurnStore()

        store.submitPrompt("Explain London", submittedAt: base)
        store.updateActiveTurn(
            from: """
            London is the capital of the United Kingdom.

            It has many museums.
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(10)
        )
        store.updateActiveTurn(
            from: """
            London is the capital of the United Kingdom.

            It has many museums.
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(20)
        )

        #expect(visibleText(from: store.blocks) == [
            "Explain London",
            "Worked for 10s",
            "London is the capital of the United Kingdom.\n\nIt has many museums."
        ])
    }

    @Test
    func turnStoreKeepsPreviousLongAnswerWhenNextTurnRunsLong() throws {
        let base = Date()
        var store = PenggieReadingTurnStore()

        store.submitPrompt("Introduce London", submittedAt: base)
        store.updateActiveTurn(
            from: """
            London is the capital of the United Kingdom.

            It is known for finance, culture, museums, and transport.
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(10)
        )
        settleActiveTurn(
            &store,
            projection: """
            London is the capital of the United Kingdom.

            It is known for finance, culture, museums, and transport.
            """,
            at: base.addingTimeInterval(10)
        )

        store.submitPrompt("Tell me about studying there", submittedAt: base.addingTimeInterval(20))
        store.updateActiveTurn(
            from: """
            London is the capital of the United Kingdom.

            It is known for finance, culture, museums, and transport.

            › Tell me about studying there

            Studying in London gives access to many universities.

            The city is expensive but has strong internships and networks.
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(30)
        )
        store.updateActiveTurn(
            from: """
            The city is expensive but has strong internships and networks.

            Students should budget carefully and plan commute time.
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(40)
        )

        #expect(visibleText(from: store.blocks) == [
            "Introduce London",
            "Worked for 10s",
            "London is the capital of the United Kingdom.\n\nIt is known for finance, culture, museums, and transport.",
            "Tell me about studying there",
            "Worked for 10s",
            "Studying in London gives access to many universities.\n\nThe city is expensive but has strong internships and networks.",
            "Students should budget carefully and plan commute time."
        ])
    }

    @Test
    func turnStoreOnlyAllowsNextPromptAfterCodexReturnsToIdle() throws {
        let base = Date()
        var store = PenggieReadingTurnStore()

        #expect(store.canSubmitPrompt)

        store.submitPrompt("Explain London", submittedAt: base)
        #expect(!store.canSubmitPrompt)

        store.updateActiveTurn(
            from: "London is the capital of the United Kingdom.",
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(10)
        )
        #expect(!store.canSubmitPrompt)

        store.updateActiveTurn(
            from: """
            London is the capital of the United Kingdom.

            gpt-5.4 medium · ~
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(11)
        )
        #expect(!store.canSubmitPrompt)

        store.updateActiveTurn(
            from: """
            London is the capital of the United Kingdom.

            gpt-5.4 medium · ~
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(12)
        )

        #expect(store.canSubmitPrompt)
        #expect(visibleText(from: store.blocks) == [
            "Explain London",
            "Worked for 12s",
            "London is the capital of the United Kingdom."
        ])
    }

    @Test
    func turnStoreDoesNotFreezeOnFirstIdleMetadataFrame() throws {
        let base = Date()
        var store = PenggieReadingTurnStore()

        store.submitPrompt("Explain London", submittedAt: base)
        store.updateActiveTurn(
            from: """
            London is the capital of the United Kingdom.

            gpt-5.4 medium · ~
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(10)
        )

        #expect(!store.canSubmitPrompt)

        store.updateActiveTurn(
            from: """
            London is the capital of the United Kingdom.

            It has museums, finance, universities, and transport.

            gpt-5.4 medium · ~
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(11)
        )

        #expect(!store.canSubmitPrompt)

        store.updateActiveTurn(
            from: """
            London is the capital of the United Kingdom.

            It has museums, finance, universities, and transport.

            gpt-5.4 medium · ~
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(12)
        )

        #expect(store.canSubmitPrompt)
        #expect(visibleText(from: store.blocks) == [
            "Explain London",
            "Worked for 12s",
            "London is the capital of the United Kingdom.",
            "It has museums, finance, universities, and transport."
        ])
    }

    @Test
    func completedTurnStillAcceptsLateTailUntilNextPromptSealsIt() throws {
        let base = Date()
        var store = PenggieReadingTurnStore()

        store.submitPrompt("Question A", submittedAt: base)

        let firstIdleProjection = """
        Answer A paragraph 1.

        gpt-5.4 medium · ~
        """
        store.updateActiveTurn(
            from: firstIdleProjection,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(16)
        )
        store.updateActiveTurn(
            from: firstIdleProjection,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(17)
        )

        #expect(store.canSubmitPrompt)

        let lateTailProjection = """
        Answer A paragraph 1.

        Answer A paragraph 2.

        - Answer A detail 1
        - Answer A detail 2

        gpt-5.4 medium · ~
        """
        store.updateActiveTurn(
            from: lateTailProjection,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(18)
        )
        store.updateActiveTurn(
            from: lateTailProjection,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(19)
        )

        #expect(store.canSubmitPrompt)
        let firstTurnText = visibleText(from: store.blocks)
        #expect(firstTurnText.contains("Question A"))
        #expect(firstTurnText.contains("Worked for 19s"))
        #expect(firstTurnText.contains("Answer A paragraph 1."))
        #expect(firstTurnText.contains("Answer A paragraph 2.\n\n- Answer A detail 1\n- Answer A detail 2"))

        store.submitPrompt("Question B", submittedAt: base.addingTimeInterval(30))
        store.updateActiveTurn(
            from: """
            Mutated answer A.

            › Question B

            Answer B paragraph 1.
            """,
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(40)
        )

        let allTurnText = visibleText(from: store.blocks)
        #expect(allTurnText.contains("Answer A paragraph 2.\n\n- Answer A detail 1\n- Answer A detail 2"))
        #expect(!allTurnText.contains("Mutated answer A."))
        #expect(allTurnText.contains("Question B"))
        #expect(allTurnText.contains("Answer B paragraph 1."))
    }

    @Test
    func turnStoreShowsLocalWorkingTimerWhenCodexWorkingTextIsAbsent() throws {
        let base = Date()
        var store = PenggieReadingTurnStore()

        store.submitPrompt("Explain London", submittedAt: base)
        store.updateActiveTurn(
            from: "",
            terminalColumns: 80,
            createdAt: base.addingTimeInterval(3)
        )

        #expect(visibleText(from: store.blocks) == [
            "Explain London",
            "Working... 3s"
        ])
    }

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

    @Test
    func groupsToolActivityAsCollapsedDisclosureItems() throws {
        let projection = """
        › Summarize this project

        I will inspect the repository and then give you a concise summary.

        Searching the web

        Searched project documentation

        Searching the web

        Searched architecture notes

        This project builds a focused macOS app around a Codex session.
        """

        let blocks = PenggieReadingProjectionModel.blocks(from: projection, terminalColumns: 80)
        let items = PenggieReadingPresentation.visibleItems(
            from: blocks,
            nativeInteractionIsActive: false
        )

        #expect(items.count == 3)
        #expect(items.first?.block?.variant == .proseLike)

        let disclosure = try #require(items.dropFirst().first?.disclosure)
        #expect(disclosure.isCollapsedByDefault)
        #expect(disclosure.blocks.count == 4)
        #expect(disclosure.summary == "Searched the web 4 times")
        #expect(disclosure.detailText.contains("Searched project documentation"))

        #expect(items.last?.block.map { PenggieReadingPresentation.chatText(for: $0) } == "This project builds a focused macOS app around a Codex session.")
    }

    @Test
    func disclosureSummaryPrefersWorkedForStatus() throws {
        let projection = """
        Worked for 24s

        Searching the web

        Searched project documentation

        The repository contains the Penggie app shell.
        """

        let blocks = PenggieReadingProjectionModel.blocks(from: projection, terminalColumns: 80)
        let items = PenggieReadingPresentation.visibleItems(
            from: blocks,
            nativeInteractionIsActive: false
        )

        let disclosure = try #require(items.first?.disclosure)
        #expect(disclosure.summary == "Worked for 24s")
        #expect(items.last?.block.map { PenggieReadingPresentation.chatText(for: $0) } == "The repository contains the Penggie app shell.")
    }

    @Test
    func insertsWorkedForSummaryBeforePlainAssistantAnswer() throws {
        let base = Date()
        let submission = PenggieComposerSubmission(text: "Explain this codebase", submittedAt: base)
        let previousBlocks = [
            PenggieReadingBlock(
                id: submission.id,
                kind: .input,
                text: "Explain this codebase",
                displayText: submission.text,
                createdAt: base,
                variant: .prompt,
                confidence: .high,
                composerSubmissionID: submission.id
            )
        ]
        let projection = """
        The repository contains the Penggie app shell.
        """

        let blocks = PenggieReadingProjectionModel.blocks(
            from: projection,
            terminalColumns: 80,
            previousBlocks: previousBlocks,
            composerSubmissions: [submission],
            consumedComposerSubmissionIDs: [submission.id],
            createdAt: base.addingTimeInterval(24)
        )
        let items = PenggieReadingPresentation.visibleItems(
            from: blocks,
            nativeInteractionIsActive: false
        )

        #expect(items.count == 3)
        #expect(items.first?.block?.kind == .input)

        let disclosure = try #require(items.dropFirst().first?.disclosure)
        #expect(disclosure.summary == "Worked for 24s")
        #expect(disclosure.detailText.isEmpty)

        #expect(items.last?.block.map { PenggieReadingPresentation.chatText(for: $0) } == "The repository contains the Penggie app shell.")
    }

    @Test
    func localWorkedForSummaryWrapsToolDetailsWhenCodexStatusIsMissing() throws {
        let base = Date()
        let submission = PenggieComposerSubmission(text: "Summarize this project", submittedAt: base)
        let previousBlocks = [
            PenggieReadingBlock(
                id: submission.id,
                kind: .input,
                text: "Summarize this project",
                displayText: submission.text,
                createdAt: base,
                variant: .prompt,
                confidence: .high,
                composerSubmissionID: submission.id
            )
        ]
        let projection = """
        Searching the web

        Searched project documentation

        The repository contains the Penggie app shell.
        """

        let blocks = PenggieReadingProjectionModel.blocks(
            from: projection,
            terminalColumns: 80,
            previousBlocks: previousBlocks,
            composerSubmissions: [submission],
            consumedComposerSubmissionIDs: [submission.id],
            createdAt: base.addingTimeInterval(24)
        )
        let items = PenggieReadingPresentation.visibleItems(
            from: blocks,
            nativeInteractionIsActive: false
        )

        let disclosure = try #require(items.dropFirst().first?.disclosure)
        #expect(disclosure.summary == "Worked for 24s")
        #expect(disclosure.detailText.contains("Searched project documentation"))
    }

    @Test
    func disclosureSummaryShowsWorkingDurationWhileActive() throws {
        let projection = """
        Searching the web

        Working (2s • esc to interrupt)

        Write tests for @filename
        """

        let blocks = PenggieReadingProjectionModel.blocks(from: projection, terminalColumns: 80)
        let items = PenggieReadingPresentation.visibleItems(
            from: blocks,
            nativeInteractionIsActive: false
        )

        let disclosure = try #require(items.first?.disclosure)
        #expect(disclosure.summary == "Working... 2s")
    }

    @Test
    func activeTurnDoesNotInsertDuplicateLocalTimer() throws {
        let base = Date()
        let input = PenggieReadingBlock(
            kind: .input,
            text: "Explain this project",
            displayText: "Explain this project",
            createdAt: base,
            variant: .prompt,
            confidence: .high
        )
        let preamble = PenggieReadingBlock(
            kind: .output,
            text: "I will inspect the repository first.",
            createdAt: base.addingTimeInterval(1),
            variant: .proseLike
        )
        let activity = PenggieReadingBlock(
            kind: .output,
            text: "Searching the web",
            createdAt: base.addingTimeInterval(3),
            variant: .activity
        )
        let working = PenggieReadingBlock(
            kind: .output,
            text: "Working (14s • esc to interrupt)",
            createdAt: base.addingTimeInterval(14),
            variant: .activity
        )

        let items = PenggieReadingPresentation.visibleItems(
            from: [input, preamble, activity, working],
            nativeInteractionIsActive: false
        )

        #expect(items.count == 2)
        #expect(items.first?.block?.kind == .input)

        let disclosure = try #require(items.last?.disclosure)
        #expect(disclosure.summary == "Working... 14s")
        #expect(disclosure.detailText.contains("I will inspect the repository first."))
        #expect(disclosure.detailText.contains("Working (14s"))
    }

    @Test
    func localWorkedForSummaryDoesNotKeepCountingAcrossStableProjectionPolls() throws {
        let base = Date()
        let submission = PenggieComposerSubmission(text: "Explain this project", submittedAt: base)
        let previousBlocks = [
            PenggieReadingBlock(
                id: submission.id,
                kind: .input,
                text: "Explain this project",
                displayText: submission.text,
                createdAt: base,
                variant: .prompt,
                confidence: .high,
                composerSubmissionID: submission.id
            )
        ]
        let projection = "This project builds the Penggie app shell."

        let firstPollBlocks = PenggieReadingProjectionModel.blocks(
            from: projection,
            terminalColumns: 80,
            previousBlocks: previousBlocks,
            composerSubmissions: [submission],
            consumedComposerSubmissionIDs: [submission.id],
            createdAt: base.addingTimeInterval(14)
        )
        let secondPollBlocks = PenggieReadingProjectionModel.blocks(
            from: projection,
            terminalColumns: 80,
            previousBlocks: firstPollBlocks,
            composerSubmissions: [submission],
            consumedComposerSubmissionIDs: [submission.id],
            createdAt: base.addingTimeInterval(36)
        )

        let items = PenggieReadingPresentation.visibleItems(
            from: secondPollBlocks,
            nativeInteractionIsActive: false
        )

        let disclosure = try #require(items.dropFirst().first?.disclosure)
        #expect(disclosure.summary == "Worked for 14s")
    }

    @Test
    func keepsSequentialComposerPromptsInterleavedWithTheirAnswersWhenTerminalDropsPromptEchoes() throws {
        let base = Date()
        let firstSubmission = PenggieComposerSubmission(text: "First question", submittedAt: base)
        let secondSubmission = PenggieComposerSubmission(text: "Second question", submittedAt: base.addingTimeInterval(20))
        let previousBlocks = [
            PenggieReadingBlock(
                id: firstSubmission.id,
                kind: .input,
                text: firstSubmission.text,
                displayText: firstSubmission.text,
                createdAt: firstSubmission.submittedAt,
                variant: .prompt,
                confidence: .high,
                composerSubmissionID: firstSubmission.id
            ),
            PenggieReadingBlock(
                kind: .output,
                text: "First answer",
                createdAt: base.addingTimeInterval(10),
                variant: .proseLike
            )
        ]
        let projection = """
        First answer

        Second answer
        """

        let blocks = PenggieReadingProjectionModel.blocks(
            from: projection,
            terminalColumns: 80,
            previousBlocks: previousBlocks,
            composerSubmissions: [firstSubmission, secondSubmission],
            consumedComposerSubmissionIDs: [firstSubmission.id],
            createdAt: base.addingTimeInterval(30)
        )
        let items = PenggieReadingPresentation.visibleItems(
            from: blocks,
            nativeInteractionIsActive: false
        )
        let visibleText = items.compactMap { item -> String? in
            switch item {
            case .block(let block):
                return PenggieReadingPresentation.chatText(for: block)
            case .disclosure(let disclosure):
                return disclosure.summary
            }
        }

        #expect(visibleText == [
            "First question",
            "Worked for 10s",
            "First answer",
            "Second question",
            "Worked for 10s",
            "Second answer"
        ])
    }

    @Test
    func keepsThreeSequentialComposerPromptsInterleavedWhenTerminalMergesAllAnswers() throws {
        let base = Date()
        let firstSubmission = PenggieComposerSubmission(text: "First question", submittedAt: base)
        let secondSubmission = PenggieComposerSubmission(text: "Second question", submittedAt: base.addingTimeInterval(20))
        let thirdSubmission = PenggieComposerSubmission(text: "Third question", submittedAt: base.addingTimeInterval(40))
        let previousBlocks = [
            PenggieReadingBlock(
                id: firstSubmission.id,
                kind: .input,
                text: firstSubmission.text,
                displayText: firstSubmission.text,
                createdAt: firstSubmission.submittedAt,
                variant: .prompt,
                confidence: .high,
                composerSubmissionID: firstSubmission.id
            ),
            PenggieReadingBlock(
                kind: .output,
                text: "First answer",
                createdAt: base.addingTimeInterval(10),
                variant: .proseLike
            ),
            PenggieReadingBlock(
                id: secondSubmission.id,
                kind: .input,
                text: secondSubmission.text,
                displayText: secondSubmission.text,
                createdAt: secondSubmission.submittedAt,
                variant: .prompt,
                confidence: .high,
                composerSubmissionID: secondSubmission.id
            ),
            PenggieReadingBlock(
                kind: .output,
                text: "Second answer",
                createdAt: base.addingTimeInterval(30),
                variant: .proseLike
            )
        ]
        let projection = """
        First answer

        Second answer

        Third answer
        """

        let blocks = PenggieReadingProjectionModel.blocks(
            from: projection,
            terminalColumns: 80,
            previousBlocks: previousBlocks,
            composerSubmissions: [firstSubmission, secondSubmission, thirdSubmission],
            consumedComposerSubmissionIDs: [firstSubmission.id, secondSubmission.id],
            createdAt: base.addingTimeInterval(50)
        )
        let items = PenggieReadingPresentation.visibleItems(
            from: blocks,
            nativeInteractionIsActive: false
        )
        let visibleText = items.compactMap { item -> String? in
            switch item {
            case .block(let block):
                return PenggieReadingPresentation.chatText(for: block)
            case .disclosure(let disclosure):
                return disclosure.summary
            }
        }

        #expect(visibleText == [
            "First question",
            "Worked for 10s",
            "First answer",
            "Second question",
            "Worked for 10s",
            "Second answer",
            "Third question",
            "Worked for 10s",
            "Third answer"
        ])
    }

    @Test
    func realWorkedForStatusOwnsCompletedTurnTiming() throws {
        let base = Date()
        let input = PenggieReadingBlock(
            kind: .input,
            text: "Explain this project",
            displayText: "Explain this project",
            createdAt: base,
            variant: .prompt,
            confidence: .high
        )
        let worked = PenggieReadingBlock(
            kind: .output,
            text: "Worked for 24s",
            createdAt: base.addingTimeInterval(24),
            variant: .status
        )
        let answer = PenggieReadingBlock(
            kind: .output,
            text: "This project builds the Penggie app shell.",
            createdAt: base.addingTimeInterval(30),
            variant: .proseLike
        )

        let items = PenggieReadingPresentation.visibleItems(
            from: [input, worked, answer],
            nativeInteractionIsActive: false
        )

        #expect(items.count == 3)
        let disclosure = try #require(items.dropFirst().first?.disclosure)
        #expect(disclosure.summary == "Worked for 24s")
        #expect(items.last?.block.map { PenggieReadingPresentation.chatText(for: $0) } == "This project builds the Penggie app shell.")
    }

    @Test
    func hidesTrailingCodexSessionMetadataFromReadingSurface() {
        let projection = """
        The repository contains the Penggie app shell.

        gpt-5.4 medium · ~
        """

        let blocks = PenggieReadingProjectionModel.blocks(from: projection, terminalColumns: 80)
        let visible = PenggieReadingPresentation.visibleBlocks(
            from: blocks,
            nativeInteractionIsActive: false
        )

        #expect(visible.count == 1)
        #expect(PenggieReadingPresentation.chatText(for: visible[0]) == "The repository contains the Penggie app shell.")
    }

    @Test
    func hidesTerminalPromptEchoWhenComposerOwnsPrompt() {
        let submission = PenggieComposerSubmission(text: "Summarize this project", submittedAt: Date())
        let projection = """
        › Summarize this project

        I will inspect the repository and then give you a concise summary.
        """

        let blocks = PenggieReadingProjectionModel.blocks(
            from: projection,
            terminalColumns: 80,
            composerSubmissions: [submission]
        )
        let visible = PenggieReadingPresentation.visibleBlocks(
            from: blocks,
            nativeInteractionIsActive: false
        )

        #expect(visible.count == 2)
        #expect(visible.first?.kind == .input)
        #expect(visible.last?.kind == .output)
        #expect(visible.last?.variant == .proseLike)
    }

    @Test
    func hidesStartupChromeFromReadingSurface() {
        let projection = """
        ╭────────────────────────╮
        │ >_ OpenAI Codex        │
        │ model: test            │
        ╰────────────────────────╯
        """

        let blocks = PenggieReadingProjectionModel.blocks(from: projection, terminalColumns: 80)
        let visible = PenggieReadingPresentation.visibleBlocks(
            from: blocks,
            nativeInteractionIsActive: false
        )

        #expect(blocks.first?.variant == .startup)
        #expect(visible.isEmpty)
    }

    @Test
    func hidesNativeInteractionMenuChromeFromReadingSurface() {
        let projection = """
        › /m

          /model     choose model
          /memories  configure memories
        """

        let blocks = PenggieReadingProjectionModel.blocks(from: projection, terminalColumns: 80)
        let visible = PenggieReadingPresentation.visibleBlocks(
            from: blocks,
            nativeInteractionIsActive: true
        )

        #expect(blocks.contains { $0.variant == .prompt || $0.variant == .menu })
        #expect(visible.isEmpty)
    }

    @Test
    func hidesCodexSessionMetadataFromReadingSurface() throws {
        let submission = PenggieComposerSubmission(text: "Explain this codebase", submittedAt: Date())
        let projection = """
        Explain this codebase

          gpt-5.4 medium · ~
        """

        let blocks = PenggieReadingProjectionModel.blocks(
            from: projection,
            terminalColumns: 80,
            composerSubmissions: [submission]
        )
        let visible = PenggieReadingPresentation.visibleBlocks(
            from: blocks,
            nativeInteractionIsActive: false
        )

        #expect(visible.count == 1)
        #expect(try #require(visible.first).kind == .input)
    }

    @Test
    func doesNotHidePlainOutputWhenPromptEchoAndResponseShareABlock() {
        let submission = PenggieComposerSubmission(text: "Explain this codebase", submittedAt: Date())
        let projection = """
        Explain this codebase

          This codebase builds a Penggie macOS app.
        """

        let blocks = PenggieReadingProjectionModel.blocks(
            from: projection,
            terminalColumns: 80,
            composerSubmissions: [submission]
        )
        let visible = PenggieReadingPresentation.visibleBlocks(
            from: blocks,
            nativeInteractionIsActive: false
        )

        #expect(visible.contains { PenggieReadingPresentation.chatText(for: $0).contains("Penggie macOS app") })
    }

    @Test
    func keepsComposerPromptWhenTerminalViewportDropsPromptEcho() {
        let submission = PenggieComposerSubmission(text: "今天伦敦天气怎么样?", submittedAt: Date())
        let previousBlocks = [
            PenggieReadingBlock(
                id: submission.id,
                kind: .input,
                text: "› 今天伦敦天气怎么样?",
                displayText: submission.text,
                createdAt: submission.submittedAt,
                variant: .prompt,
                confidence: .high,
                composerSubmissionID: submission.id
            )
        ]
        let projection = """
        按伦敦当地时间来看，今天是 2026 年 5 月 24 日。

        - 最高约 32°C
        - 最低约 20°C
        """

        let blocks = PenggieReadingProjectionModel.blocks(
            from: projection,
            terminalColumns: 80,
            previousBlocks: previousBlocks,
            composerSubmissions: [submission],
            consumedComposerSubmissionIDs: [submission.id]
        )
        let visible = PenggieReadingPresentation.visibleBlocks(
            from: blocks,
            nativeInteractionIsActive: false
        )

        #expect(visible.first?.kind == .input)
        #expect(visible.first?.displayText == submission.text)
        #expect(visible.contains { PenggieReadingPresentation.chatText(for: $0).contains("最高约 32°C") })
    }

    private func visibleText(from blocks: [PenggieReadingBlock]) -> [String] {
        PenggieReadingPresentation.visibleItems(from: blocks, nativeInteractionIsActive: false)
            .compactMap { item -> String? in
                switch item {
                case .block(let block):
                    return PenggieReadingPresentation.chatText(for: block)
                case .disclosure(let disclosure):
                    return disclosure.summary
                }
            }
    }

    private func settleActiveTurn(
        _ store: inout PenggieReadingTurnStore,
        projection: String,
        terminalColumns: Int? = 80,
        at date: Date
    ) {
        let settledProjection = """
        \(projection)

        gpt-5.4 medium · ~
        """

        store.updateActiveTurn(
            from: settledProjection,
            terminalColumns: terminalColumns,
            createdAt: date
        )
        store.updateActiveTurn(
            from: settledProjection,
            terminalColumns: terminalColumns,
            createdAt: date
        )
    }
}
