import Testing
@testable import ShowCLI

struct ShowCLIItemTranscriptTests {
    @Test func composerNativeTriggerUsesOnlyFirstCharacter() {
        #expect(
            ShowCLIComposerNativeTrigger.prefix(
                for: "/model",
                canUseCodexDollarCommand: true
            ) == "/"
        )
        #expect(
            ShowCLIComposerNativeTrigger.prefix(
                for: " /model",
                canUseCodexDollarCommand: true
            ) == nil
        )
        #expect(
            ShowCLIComposerNativeTrigger.prefix(
                for: "Explain /model",
                canUseCodexDollarCommand: true
            ) == nil
        )
        #expect(
            ShowCLIComposerNativeTrigger.prefix(
                for: "Use $HOME as an example",
                canUseCodexDollarCommand: true
            ) == nil
        )
    }

    @Test func composerNativeTriggerUsesFirstCharacterAcrossMultilineText() {
        #expect(
            ShowCLIComposerNativeTrigger.prefix(
                for: "/model\nhigh",
                canUseCodexDollarCommand: true
            ) == "/"
        )
        #expect(
            ShowCLIComposerNativeTrigger.prefix(
                for: "\n/model",
                canUseCodexDollarCommand: true
            ) == nil
        )
        #expect(
            ShowCLIComposerNativeTrigger.prefix(
                for: "Explain this:\n/model",
                canUseCodexDollarCommand: true
            ) == nil
        )
    }

    @Test func composerNativeTriggerRestrictsDollarToCodexSessions() {
        #expect(
            ShowCLIComposerNativeTrigger.prefix(
                for: "$",
                canUseCodexDollarCommand: true
            ) == "$"
        )
        #expect(
            ShowCLIComposerNativeTrigger.prefix(
                for: "$",
                canUseCodexDollarCommand: false
            ) == nil
        )
        #expect(
            ShowCLIComposerNativeTrigger.prefix(
                for: "$model",
                canUseCodexDollarCommand: true
            ) == "$"
        )
        #expect(
            ShowCLIComposerNativeTrigger.prefix(
                for: " $model",
                canUseCodexDollarCommand: true
            ) == nil
        )
        #expect(
            ShowCLIComposerNativeTrigger.prefix(
                for: "Explain $model",
                canUseCodexDollarCommand: true
            ) == nil
        )
        #expect(
            ShowCLIComposerNativeTrigger.prefix(
                for: "$model",
                canUseCodexDollarCommand: false
            ) == nil
        )
    }

    @Test func composerNativeTriggerCanInterceptOnlyEmptyUnmarkedFirstKey() {
        #expect(
            ShowCLIComposerNativeTrigger.prefixForFirstKeyCharacters(
                "/",
                existingText: "",
                hasMarkedText: false,
                canUseCodexDollarCommand: true
            ) == "/"
        )
        #expect(
            ShowCLIComposerNativeTrigger.prefixForFirstKeyCharacters(
                "$",
                existingText: "",
                hasMarkedText: false,
                canUseCodexDollarCommand: true
            ) == "$"
        )
        #expect(
            ShowCLIComposerNativeTrigger.prefixForFirstKeyCharacters(
                "/",
                existingText: "hello",
                hasMarkedText: false,
                canUseCodexDollarCommand: true
            ) == nil
        )
        #expect(
            ShowCLIComposerNativeTrigger.prefixForFirstKeyCharacters(
                "/",
                existingText: "",
                hasMarkedText: true,
                canUseCodexDollarCommand: true
            ) == nil
        )
        #expect(
            ShowCLIComposerNativeTrigger.prefixForFirstKeyCharacters(
                "$",
                existingText: "",
                hasMarkedText: false,
                canUseCodexDollarCommand: false
            ) == nil
        )
    }

    @Test func composerNativeTriggerKeepsMarkedTextVisibleForPlaceholder() {
        #expect(
            ShowCLIComposerNativeTrigger.hasVisibleComposerText(
                string: "",
                hasMarkedText: true
            )
        )
        #expect(
            ShowCLIComposerNativeTrigger.hasVisibleComposerText(
                string: "hello",
                hasMarkedText: false
            )
        )
        #expect(
            !ShowCLIComposerNativeTrigger.hasVisibleComposerText(
                string: "",
                hasMarkedText: false
            )
        )
    }

    private static func instructionStyle(
        textCellCount: Int = 40
    ) -> ShowCLITerminalScreenSnapshot.Line.StyleSummary {
        .init(
            textCellCount: textCellCount,
            selectedCellCount: 0,
            selectedTextCellCount: 0,
            boldTextCellCount: 0,
            faintTextCellCount: textCellCount,
            inverseTextCellCount: 0,
            backgroundTextCellCount: 0,
            foregroundTextCellCount: 0
        )
    }

    @Test func nativeInteractionScopeIgnoresEarlierToolRowsWhenInputAnchorExists() {
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 12,
            cursor: .init(x: 2, y: 4, visible: true),
            lines: [
                .init(index: 0, text: "⚠ Skill descriptions were shortened to fit the 2% skills context budget.", selected: false),
                .init(index: 1, text: "Searching the web", selected: true),
                .init(index: 2, text: "Searching the web", selected: false),
                .init(index: 3, text: "/", selected: false),
                .init(index: 4, text: "/model        choose what model and reasoning effort to use", selected: false),
                .init(index: 5, text: "/fast         1.5x speed, increased usage", selected: false),
                .init(index: 6, text: "/permissions  choose what Codex is allowed to do", selected: false),
            ]
        )

        let rows = ShowCLINativeInteractionScope.rows(
            from: snapshot,
            currentInput: "/"
        ).map(\.text)

        #expect(rows == [
            "/model        choose what model and reasoning effort to use",
            "/fast         1.5x speed, increased usage",
            "/permissions  choose what Codex is allowed to do",
        ])
    }

    @Test func nativeInteractionScopeDoesNotFallbackToOldTranscriptWithoutCurrentScreenEvidence() {
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 8,
            cursor: .init(x: 0, y: 7, visible: true),
            lines: [
                .init(index: 0, text: "⚠ Skill descriptions were shortened to fit the 2% skills context budget.", selected: false),
                .init(index: 1, text: "Searching the web", selected: false),
                .init(index: 2, text: "Searching the web", selected: false),
                .init(index: 3, text: "Searched weather: London", selected: false),
            ]
        )

        #expect(ShowCLINativeInteractionScope.rows(from: snapshot, currentInput: "/").isEmpty)
    }

    @Test func nativeInteractionScopeRequiresCurrentInputAnchorBeforeUsingSelectedRegion() {
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 12,
            cursor: .init(x: 0, y: 8, visible: true),
            lines: [
                .init(index: 2, text: "1. gpt-5.5 (default)  Frontier model for complex coding, research, and real-world work.", selected: false),
                .init(index: 3, text: "2. gpt-5.4            Strong model for everyday coding.", selected: true),
                .init(index: 4, text: "3. gpt-5.4-mini       Small, fast, and cost-efficient model for simpler coding tasks.", selected: false),
                .init(index: 5, text: "", selected: false),
                .init(
                    index: 6,
                    text: "Press enter to confirm or esc to go back",
                    selected: false,
                    styleSummary: Self.instructionStyle()
                ),
            ]
        )

        #expect(ShowCLINativeInteractionScope.rows(from: snapshot, currentInput: "/").isEmpty)
    }

    @Test func nativeInteractionScopeDoesNotNormalizeLeadingWhitespaceInCurrentInput() {
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 12,
            cursor: .init(x: 4, y: 1, visible: true),
            lines: [
                .init(index: 1, text: "›  /", selected: false),
                .init(index: 2, text: "/model        choose what model and reasoning effort to use", selected: false),
                .init(index: 3, text: "/fast         1.5x speed, increased usage", selected: false),
                .init(index: 4, text: "/permissions  choose what Codex is allowed to do", selected: false),
            ]
        )

        #expect(ShowCLINativeInteractionScope.rows(from: snapshot, currentInput: " /").isEmpty)
    }

    @Test func nativeInteractionScopeDoesNotShowToolRowsAfterInputAnchor() {
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 10,
            cursor: .init(x: 2, y: 1, visible: true),
            lines: [
                .init(index: 1, text: "› /", selected: false),
                .init(index: 2, text: "Searching the web", selected: false),
                .init(index: 3, text: "Searched weather: London", selected: false),
                .init(index: 4, text: "", selected: false),
                .init(index: 5, text: "/model        choose what model and reasoning effort to use", selected: false),
                .init(index: 6, text: "/fast         1.5x speed, increased usage", selected: false),
            ]
        )

        #expect(ShowCLINativeInteractionScope.rows(from: snapshot, currentInput: "/").isEmpty)
    }

    @Test func nativeInteractionScopeDoesNotTreatToolRowsWithTrailingSlashSuggestionsAsMenu() {
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 14,
            cursor: .init(x: 2, y: 0, visible: true),
            lines: [
                .init(index: 0, text: "› /", selected: false),
                .init(index: 1, text: "", selected: false),
                .init(index: 2, text: "⚠ Skill descriptions were shortened to fit the 2% skills context budget.", selected: false),
                .init(index: 3, text: "Searching the web", selected: false),
                .init(index: 4, text: "Searching the web", selected: true),
                .init(index: 5, text: "Searching the web", selected: false),
                .init(index: 6, text: "", selected: false),
                .init(index: 7, text: "/experimental  toggle experimental features", selected: false),
                .init(index: 8, text: "/approve       approve one retry of a recent auto-review denial", selected: false),
                .init(index: 9, text: "/memories      configure memory use and generation", selected: false),
            ]
        )

        #expect(ShowCLINativeInteractionScope.rows(from: snapshot, currentInput: "/").isEmpty)
        #expect(ShowCLINativeInteractionScope.rows(from: snapshot, currentInput: "").isEmpty)
        #expect(!ShowCLINativeInteractionScope.hasActiveContinuation(in: snapshot))
    }

    @Test func nativeInteractionScopeDoesNotSkipInterveningTerminalRowsToFindSlashSuggestions() {
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 14,
            cursor: .init(x: 2, y: 1, visible: true),
            lines: [
                .init(index: 1, text: "› /", selected: false),
                .init(index: 2, text: "⚠ Skill descriptions were shortened to fit the skills context budget.", selected: false),
                .init(index: 3, text: "Searching the web", selected: true),
                .init(index: 4, text: "Searching the web", selected: false),
                .init(index: 5, text: "/model        choose what model and reasoning effort to use", selected: false),
                .init(index: 6, text: "/fast         1.5x speed, increased usage", selected: false),
                .init(index: 7, text: "/permissions  choose what Codex is allowed to do", selected: false),
            ]
        )

        let rows = ShowCLINativeInteractionScope.rows(from: snapshot, currentInput: "/")

        #expect(rows.isEmpty)
    }

    @Test func nativeInteractionScopeFiltersUnchangedRowsBeforeMatchingCurrentInputMenu() {
        let baseline = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 20,
            cursor: .init(x: 0, y: 8, visible: true),
            lines: [
                .init(index: 8, text: "› ", selected: false),
                .init(index: 9, text: "Searching the web", selected: true),
                .init(index: 10, text: "Searching the web", selected: false),
                .init(index: 11, text: "", selected: false),
            ]
        )
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 20,
            cursor: .init(x: 2, y: 8, visible: true),
            lines: [
                .init(index: 8, text: "› /", selected: false),
                .init(index: 9, text: "Searching the web", selected: true),
                .init(index: 10, text: "Searching the web", selected: false),
                .init(index: 11, text: "/model        choose what model and reasoning effort to use", selected: false),
                .init(index: 12, text: "/ide          include current selection, open files, and other context from your IDE", selected: false),
            ]
        )

        let rows = ShowCLINativeInteractionScope.rows(
            from: snapshot,
            currentInput: "/",
            excludingRowsUnchangedFrom: baseline
        )

        #expect(rows.map(\.text) == [
            "/model        choose what model and reasoning effort to use",
            "/ide          include current selection, open files, and other context from your IDE",
        ])
    }

    @Test func nativeInteractionScopeFiltersUnchangedSlashLikeTerminalRowsFromCurrentInputMenu() {
        let baseline = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 20,
            cursor: .init(x: 0, y: 8, visible: true),
            lines: [
                .init(index: 8, text: "› ", selected: false),
                .init(index: 9, text: "/tmp/showcli-output", selected: false),
                .init(index: 10, text: "/Users/showing/A-ThinkBig", selected: false),
            ]
        )
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 20,
            cursor: .init(x: 2, y: 8, visible: true),
            lines: [
                .init(index: 8, text: "› /", selected: false),
                .init(index: 9, text: "/tmp/showcli-output", selected: false),
                .init(index: 10, text: "/Users/showing/A-ThinkBig", selected: false),
                .init(index: 11, text: "/model        choose what model and reasoning effort to use", selected: false),
                .init(index: 12, text: "/permissions  choose what Codex is allowed to do", selected: false),
            ]
        )

        let rows = ShowCLINativeInteractionScope.rows(
            from: snapshot,
            currentInput: "/",
            excludingRowsUnchangedFrom: baseline
        )

        #expect(rows.map(\.text) == [
            "/model        choose what model and reasoning effort to use",
            "/permissions  choose what Codex is allowed to do",
        ])
    }

    @Test func nativeInteractionScopeUsesCurrentSelectedRegion() {
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 12,
            cursor: .init(x: 0, y: 11, visible: true),
            lines: [
                .init(index: 0, text: "Searching the web", selected: false),
                .init(index: 1, text: "", selected: false),
                .init(index: 2, text: "1. gpt-5.5 (default)  Frontier model for complex coding, research, and real-world work.", selected: false),
                .init(index: 3, text: "2. gpt-5.4            Strong model for everyday coding.", selected: true),
                .init(index: 4, text: "3. gpt-5.4-mini       Small, fast, and cost-efficient model for simpler coding tasks.", selected: false),
                .init(index: 5, text: "", selected: false),
                .init(
                    index: 6,
                    text: "Press enter to confirm or esc to go back",
                    selected: false,
                    styleSummary: Self.instructionStyle()
                ),
            ]
        )

        let rows = ShowCLINativeInteractionScope.rows(
            from: snapshot,
            currentInput: ""
        )

        #expect(rows.map(\.text) == [
            "1. gpt-5.5 (default)  Frontier model for complex coding, research, and real-world work.",
            "2. gpt-5.4            Strong model for everyday coding.",
            "3. gpt-5.4-mini       Small, fast, and cost-efficient model for simpler coding tasks.",
            "",
            "Press enter to confirm or esc to go back",
        ])
        #expect(rows.map(\.isSelected) == [false, true, false, false, false])
    }

    @Test func nativeInteractionScopeUsesStyledSelectionFromScreenModel() throws {
        let json = """
        {
          "columns": 120,
          "rows": 12,
          "cursor": {"x": 2, "y": 4, "visible": true},
          "lines": [
            {"index": 3, "text": "/", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 0, "styleSummary": {"textCellCount": 1, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 4, "text": "/model        choose what model and reasoning effort to use", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 56, "styleSummary": {"textCellCount": 49, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 28, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 5, "text": "/keymap       remap TUI shortcuts", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 32, "styleSummary": {"textCellCount": 29, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 7, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 6, "text": "/vim          toggle Vim mode for the composer", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 43, "styleSummary": {"textCellCount": 37, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 27, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let snapshot = try #require(ShowCLITerminalScreenSnapshot(json: json))

        let rows = ShowCLINativeInteractionScope.rows(
            from: snapshot,
            currentInput: "/"
        )

        #expect(rows.map(\.text) == [
            "/model        choose what model and reasoning effort to use",
            "/keymap       remap TUI shortcuts",
            "/vim          toggle Vim mode for the composer",
        ])
        #expect(rows.map(\.isSelected) == [false, true, false])
    }

    @Test func nativeInteractionScopeUsesForegroundColorSelectionFromScreenModel() throws {
        let json = """
        {
          "columns": 120,
          "rows": 12,
          "cursor": {"x": 2, "y": 4, "visible": true},
          "lines": [
            {"index": 3, "text": "/", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 0, "styleSummary": {"textCellCount": 1, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 4, "text": "/model        choose what model and reasoning effort to use", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 56, "styleSummary": {"textCellCount": 49, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 28, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 5, "text": "/keymap       remap TUI shortcuts", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 32, "styleSummary": {"textCellCount": 29, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 29}},
            {"index": 6, "text": "/vim          toggle Vim mode for the composer", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 43, "styleSummary": {"textCellCount": 37, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 27, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let snapshot = try #require(ShowCLITerminalScreenSnapshot(json: json))

        let rows = ShowCLINativeInteractionScope.rows(
            from: snapshot,
            currentInput: "/"
        )

        #expect(rows.map(\.text) == [
            "/model        choose what model and reasoning effort to use",
            "/keymap       remap TUI shortcuts",
            "/vim          toggle Vim mode for the composer",
        ])
        #expect(rows.map(\.isSelected) == [false, true, false])
    }

    @Test func nativeInteractionScopeDoesNotUseSelectedSlashRowsPastInterveningTerminalRows() {
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 14,
            cursor: .init(x: 2, y: 3, visible: true),
            lines: [
                .init(index: 2, text: "› /", selected: false),
                .init(index: 3, text: "⚠ Skill descriptions were shortened to fit the 2% skills context budget.", selected: false),
                .init(index: 4, text: "Searching the web", selected: false),
                .init(index: 5, text: "", selected: false),
                .init(index: 6, text: "/model        choose what model and reasoning effort to use", selected: false),
                .init(
                    index: 7,
                    text: "/keymap       remap TUI shortcuts",
                    selected: false,
                    styleSummary: .init(
                        textCellCount: 29,
                        selectedCellCount: 0,
                        selectedTextCellCount: 0,
                        boldTextCellCount: 7,
                        faintTextCellCount: 0,
                        inverseTextCellCount: 0,
                        backgroundTextCellCount: 0,
                        foregroundTextCellCount: 0
                    )
                ),
                .init(index: 8, text: "/vim          toggle Vim mode for the composer", selected: false),
            ]
        )

        let rows = ShowCLINativeInteractionScope.rows(
            from: snapshot,
            currentInput: "/"
        )

        #expect(rows.isEmpty)
    }

    @Test func nativeInteractionScopeRequiresCursorLocalInputAnchorWhenCursorExists() {
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 30,
            cursor: .init(x: 0, y: 24, visible: true),
            lines: [
                .init(index: 4, text: "› /", selected: false),
                .init(index: 5, text: "/model        choose what model and reasoning effort to use", selected: false),
                .init(index: 6, text: "/fast         1.5x speed, increased usage", selected: false),
                .init(index: 24, text: "› ", selected: false),
            ]
        )

        #expect(ShowCLINativeInteractionScope.rows(from: snapshot, currentInput: "/").isEmpty)
    }

    @Test func nativeInteractionScopeKeepsOnlyContinuousCurrentInputSuggestions() {
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 12,
            cursor: .init(x: 5, y: 1, visible: true),
            lines: [
                .init(index: 1, text: "› /mod", selected: false),
                .init(index: 2, text: "/model        choose what model and reasoning effort to use", selected: false),
                .init(index: 3, text: "/modal-test   should remain with the filtered prefix", selected: false),
                .init(index: 4, text: "/permissions  choose what Codex is allowed to do", selected: false),
                .init(index: 5, text: "/model-debug  should not be pulled after the first non-match", selected: false),
            ]
        )

        let rows = ShowCLINativeInteractionScope.rows(from: snapshot, currentInput: "/mod")

        #expect(rows.map(\.text) == [
            "/model        choose what model and reasoning effort to use",
            "/modal-test   should remain with the filtered prefix",
        ])
    }

    @Test func nativeInteractionScopeDoesNotNormalizeNativeInputForMenuMatching() {
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 12,
            cursor: .init(x: 3, y: 1, visible: true),
            lines: [
                .init(index: 1, text: "› /", selected: false),
                .init(index: 2, text: "/model        choose what model and reasoning effort to use", selected: false),
                .init(index: 3, text: "/fast         1.5x speed, increased usage", selected: false),
                .init(index: 4, text: "/permissions  choose what Codex is allowed to do", selected: false),
            ]
        )

        #expect(ShowCLINativeInteractionScope.rows(from: snapshot, currentInput: "/ ").isEmpty)
    }

    @Test func nativeInteractionPhaseDistinguishesResolvingFromContinuation() {
        #expect(ShowCLINativeInteractionPhase.editing.isActive)
        #expect(ShowCLINativeInteractionPhase.resolving.isActive)
        #expect(ShowCLINativeInteractionPhase.continuation.isActive)
        #expect(!ShowCLINativeInteractionPhase.resolving.acceptsInput)
        #expect(ShowCLINativeInteractionPhase.continuation.acceptsInput)
    }

    @Test func nativeInteractionPhaseCapturesTextOnlyWhenCLIInputIsAccepted() {
        #expect(ShowCLINativeInteractionPhase.editing.capturesTextInput)
        #expect(!ShowCLINativeInteractionPhase.resolving.capturesTextInput)
        #expect(ShowCLINativeInteractionPhase.continuation.capturesTextInput)
        #expect(!ShowCLINativeInteractionPhase.cancelling.capturesTextInput)
        #expect(!ShowCLINativeInteractionPhase.inactive.capturesTextInput)
    }

    @Test func nativeInteractionPhaseOwnsComposerOnlyWhenCLICanReceiveInput() {
        #expect(ShowCLINativeInteractionPhase.editing.ownsComposerInput)
        #expect(!ShowCLINativeInteractionPhase.resolving.ownsComposerInput)
        #expect(ShowCLINativeInteractionPhase.continuation.ownsComposerInput)
        #expect(!ShowCLINativeInteractionPhase.cancelling.ownsComposerInput)
        #expect(!ShowCLINativeInteractionPhase.inactive.ownsComposerInput)
    }

    @Test func nativeInteractionResolvingKeepsLifecycleActiveWithoutCapturingInput() {
        #expect(ShowCLINativeInteractionPhase.resolving.isActive)
        #expect(!ShowCLINativeInteractionPhase.resolving.ownsComposerInput)
        #expect(!ShowCLINativeInteractionPhase.resolving.acceptsInput)
        #expect(!ShowCLINativeInteractionPhase.resolving.capturesTextInput)
    }

    @Test func nativeInteractionPresentationShowsRowsOnlyWhenPhaseCanOwnTheMenu() {
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 12,
            cursor: .init(x: 2, y: 1, visible: true),
            lines: [
                .init(index: 1, text: "› /", selected: false),
                .init(index: 2, text: "/model        choose what model and reasoning effort to use", selected: false),
                .init(index: 3, text: "/fast         1.5x speed, increased usage", selected: false),
            ]
        )

        #expect(
            ShowCLINativeInteractionPresentation.rows(
                from: snapshot,
                phase: .editing,
                currentInput: "/"
            ).map(\.text) == [
                "/model        choose what model and reasoning effort to use",
                "/fast         1.5x speed, increased usage",
            ]
        )
        #expect(
            ShowCLINativeInteractionPresentation.rows(
                from: snapshot,
                phase: .resolving,
                currentInput: ""
            ).isEmpty
        )
        #expect(
            ShowCLINativeInteractionPresentation.rows(
                from: snapshot,
                phase: .inactive,
                currentInput: "/"
            ).isEmpty
        )
    }

    @Test func nativeInteractionPresentationUsesContinuationRowsOnlyInContinuationPhase() throws {
        let json = """
        {
          "columns": 176,
          "rows": 48,
          "cursor": {"x": 76, "y": 16, "visible": true},
          "lines": [
            {"index": 13, "text": "  Select Reasoning Level", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 25, "styleSummary": {"textCellCount": 24, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 24, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 14, "text": "", "selected": false, "firstNonBlankColumn": null, "lastNonBlankColumn": null, "styleSummary": {"textCellCount": 0, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 15, "text": "  1. Low     Fast responses", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 27, "styleSummary": {"textCellCount": 26, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 15, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 16, "text": "  2. Medium  Balanced", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 21, "styleSummary": {"textCellCount": 20, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 17, "text": "  3. High    Deep reasoning", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 28, "styleSummary": {"textCellCount": 27, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 17, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let snapshot = try #require(ShowCLITerminalScreenSnapshot(json: json))

        #expect(
            ShowCLINativeInteractionPresentation.rows(
                from: snapshot,
                phase: .continuation,
                currentInput: ""
            ).map(\.text) == [
                "1. Low     Fast responses",
                "2. Medium  Balanced",
                "3. High    Deep reasoning",
            ]
        )
        #expect(
            ShowCLINativeInteractionPresentation.rows(
                from: snapshot,
                phase: .resolving,
                currentInput: ""
            ).isEmpty
        )
    }

    @Test func nativeInteractionPresentationLetsStandardComposerRenderDuringResolvingButNotEdit() {
        #expect(ShowCLINativeInteractionPresentation.usesNativeComposerInput(phase: .editing))
        #expect(ShowCLINativeInteractionPresentation.usesNativeComposerInput(phase: .continuation))
        #expect(!ShowCLINativeInteractionPresentation.usesNativeComposerInput(phase: .resolving))
        #expect(!ShowCLINativeInteractionPresentation.standardComposerIsEnabled(phase: .resolving))
        #expect(ShowCLINativeInteractionPresentation.standardComposerIsEnabled(phase: .inactive))
    }



    @Test func nativeInteractionScopeUsesUndimmedRowSelectionAfterInputAnchor() throws {
        let json = """
        {
          "columns": 176,
          "rows": 48,
          "cursor": {"x": 3, "y": 13, "visible": true},
          "lines": [
            {"index": 13, "text": "› /", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 2, "styleSummary": {"textCellCount": 2, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 1, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 15, "text": "  /model         choose what model and reasoning effort to use", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 61, "styleSummary": {"textCellCount": 60, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 16, "text": "  /ide           include current selection, open files, and other context from your IDE", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 86, "styleSummary": {"textCellCount": 85, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 70, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 17, "text": "  /permissions   choose what Codex is allowed to do", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 50, "styleSummary": {"textCellCount": 49, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 34, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let snapshot = try #require(ShowCLITerminalScreenSnapshot(json: json))

        let rows = ShowCLINativeInteractionScope.rows(
            from: snapshot,
            currentInput: "/"
        )

        #expect(rows.map(\.text) == [
            "/model         choose what model and reasoning effort to use",
            "/ide           include current selection, open files, and other context from your IDE",
            "/permissions   choose what Codex is allowed to do",
        ])
        #expect(rows.map(\.isSelected) == [true, false, false])
    }

    @Test func nativeInteractionScopeUsesUndimmedRowSelectionInContinuationMenu() throws {
        let json = """
        {
          "columns": 176,
          "rows": 48,
          "cursor": {"x": 76, "y": 16, "visible": true},
          "lines": [
            {"index": 13, "text": "  Select Reasoning Level for gpt-5.3-codex", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 41, "styleSummary": {"textCellCount": 40, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 40, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 14, "text": "", "selected": false, "firstNonBlankColumn": null, "lastNonBlankColumn": null, "styleSummary": {"textCellCount": 0, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 15, "text": "  1. Low               Fast responses with lighter reasoning", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 61, "styleSummary": {"textCellCount": 60, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 37, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 16, "text": "› 2. Medium (default)  Balances speed and reasoning depth for everyday tasks", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 75, "styleSummary": {"textCellCount": 76, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 17, "text": "  3. High (current)    Greater reasoning depth for complex problems", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 68, "styleSummary": {"textCellCount": 67, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 44, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 19, "text": "", "selected": false, "firstNonBlankColumn": null, "lastNonBlankColumn": null, "styleSummary": {"textCellCount": 0, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 20, "text": "  Press enter to confirm or esc to go back", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 41, "styleSummary": {"textCellCount": 174, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 174, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let snapshot = try #require(ShowCLITerminalScreenSnapshot(json: json))

        let rows = ShowCLINativeInteractionScope.rows(
            from: snapshot,
            currentInput: ""
        )

        #expect(rows.map(\.text) == [
            "1. Low               Fast responses with lighter reasoning",
            "› 2. Medium (default)  Balances speed and reasoning depth for everyday tasks",
            "3. High (current)    Greater reasoning depth for complex problems",
            "",
            "Press enter to confirm or esc to go back",
        ])
        #expect(rows.map(\.isSelected) == [false, true, false, false, false])
    }

    @Test func nativeInteractionScopeDoesNotTreatStartupOrPromptAsContinuationMenu() throws {
        let json = """
        {
          "columns": 176,
          "rows": 48,
          "cursor": {"x": 0, "y": 7, "visible": true},
          "lines": [
            {"index": 0, "text": "Last login: Sun May 24 08:37:14 on ttys000", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 43, "styleSummary": {"textCellCount": 44, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 1, "text": "codex", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 4, "styleSummary": {"textCellCount": 5, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 2, "text": "(base) showing@Showings-MBP ~ % codex", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 38, "styleSummary": {"textCellCount": 39, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 3, "text": "╭────────────────────────────────────────╮", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 42, "styleSummary": {"textCellCount": 43, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 43, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 4, "text": "│  OpenAI Codex                         │", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 42, "styleSummary": {"textCellCount": 43, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 12, "faintTextCellCount": 31, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 5, "text": "╰────────────────────────────────────────╯", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 42, "styleSummary": {"textCellCount": 43, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 43, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 7, "text": "› ", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 1, "styleSummary": {"textCellCount": 1, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 1, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let snapshot = try #require(ShowCLITerminalScreenSnapshot(json: json))

        #expect(ShowCLINativeInteractionScope.rows(from: snapshot, currentInput: "").isEmpty)
    }

    @Test func nativeInteractionScopeDoesNotTreatSelectedStartupRegionAsContinuationMenu() throws {
        let json = """
        {
          "columns": 176,
          "rows": 48,
          "cursor": {"x": 0, "y": 12, "visible": true},
          "lines": [
            {"index": 0, "text": "Model changed to gpt-5.4 medium", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 31, "styleSummary": {"textCellCount": 32, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 1, "text": "", "selected": false, "firstNonBlankColumn": null, "lastNonBlankColumn": null, "styleSummary": {"textCellCount": 0, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 2, "text": "Last login: Sun May 24 08:37:14 on ttys000", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 43, "styleSummary": {"textCellCount": 44, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 3, "text": "codex", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 4, "styleSummary": {"textCellCount": 5, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 4, "text": "(base) showing@Showings-MBP ~ % codex", "selected": true, "firstNonBlankColumn": 0, "lastNonBlankColumn": 38, "styleSummary": {"textCellCount": 39, "selectedCellCount": 39, "selectedTextCellCount": 39, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 39, "foregroundTextCellCount": 0}},
            {"index": 5, "text": "╭────────────────────────────────────────╮", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 42, "styleSummary": {"textCellCount": 43, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 43, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 6, "text": "│  OpenAI Codex                         │", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 42, "styleSummary": {"textCellCount": 43, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 12, "faintTextCellCount": 31, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 7, "text": "╰────────────────────────────────────────╯", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 42, "styleSummary": {"textCellCount": 43, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 43, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 8, "text": "", "selected": false, "firstNonBlankColumn": null, "lastNonBlankColumn": null, "styleSummary": {"textCellCount": 0, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 9, "text": "Tip: Use /mcp to list configured MCP tools.", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 40, "styleSummary": {"textCellCount": 41, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 5, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let snapshot = try #require(ShowCLITerminalScreenSnapshot(json: json))

        #expect(ShowCLINativeInteractionScope.rows(from: snapshot, currentInput: "").isEmpty)
        #expect(!ShowCLINativeInteractionScope.hasActiveContinuation(in: snapshot))
    }

    @Test func nativeInteractionScopeDoesNotKeepTopLevelSlashSuggestionsAfterInputClears() throws {
        let json = """
        {
          "columns": 176,
          "rows": 48,
          "cursor": {"x": 3, "y": 13, "visible": true},
          "lines": [
            {"index": 13, "text": "› /", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 2, "styleSummary": {"textCellCount": 2, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 1, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 15, "text": "  /model         choose what model and reasoning effort to use", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 61, "styleSummary": {"textCellCount": 60, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 16, "text": "  /ide           include current selection, open files, and other context from your IDE", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 86, "styleSummary": {"textCellCount": 85, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 70, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 17, "text": "  /permissions   choose what Codex is allowed to do", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 50, "styleSummary": {"textCellCount": 49, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 34, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let snapshot = try #require(ShowCLITerminalScreenSnapshot(json: json))

        #expect(ShowCLINativeInteractionScope.rows(from: snapshot, currentInput: "").isEmpty)
    }

    @Test func nativeInteractionScopeDoesNotKeepSelectedTopLevelSlashSuggestionsAfterInputClears() throws {
        let json = """
        {
          "columns": 176,
          "rows": 48,
          "cursor": {"x": 3, "y": 13, "visible": true},
          "lines": [
            {"index": 13, "text": "› /", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 2, "styleSummary": {"textCellCount": 2, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 1, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 15, "text": "  /model         choose what model and reasoning effort to use", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 61, "styleSummary": {"textCellCount": 60, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 40, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 16, "text": "  /vim           toggle Vim mode for the composer", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 50, "styleSummary": {"textCellCount": 49, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 49, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 17, "text": "  /experimental  toggle experimental features", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 47, "styleSummary": {"textCellCount": 46, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 31, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 18, "text": "", "selected": false, "firstNonBlankColumn": null, "lastNonBlankColumn": null, "styleSummary": {"textCellCount": 0, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 19, "text": "gpt-5.5 medium · ~", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 17, "styleSummary": {"textCellCount": 18, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let snapshot = try #require(ShowCLITerminalScreenSnapshot(json: json))

        #expect(ShowCLINativeInteractionScope.rows(from: snapshot, currentInput: "").isEmpty)
        #expect(!ShowCLINativeInteractionScope.hasActiveContinuation(in: snapshot))
    }

    @Test func nativeInteractionScopeReportsActiveContinuationOnlyForContinuationRows() throws {
        let continuationJSON = """
        {
          "columns": 176,
          "rows": 48,
          "cursor": {"x": 76, "y": 16, "visible": true},
          "lines": [
            {"index": 13, "text": "  Select Reasoning Level", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 25, "styleSummary": {"textCellCount": 24, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 24, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 14, "text": "", "selected": false, "firstNonBlankColumn": null, "lastNonBlankColumn": null, "styleSummary": {"textCellCount": 0, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 15, "text": "  1. Low     Fast responses", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 27, "styleSummary": {"textCellCount": 26, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 15, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 16, "text": "  2. Medium  Balanced", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 21, "styleSummary": {"textCellCount": 20, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 17, "text": "  3. High    Deep reasoning", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 28, "styleSummary": {"textCellCount": 27, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 17, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let idleJSON = """
        {
          "columns": 176,
          "rows": 48,
          "cursor": {"x": 0, "y": 7, "visible": true},
          "lines": [
            {"index": 0, "text": "Last login: Sun May 24 08:37:14 on ttys000", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 43, "styleSummary": {"textCellCount": 44, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 1, "text": "codex", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 4, "styleSummary": {"textCellCount": 5, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 2, "text": "(base) showing@Showings-MBP ~ % codex", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 38, "styleSummary": {"textCellCount": 39, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 3, "text": "╭────────────────────────────────────────╮", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 42, "styleSummary": {"textCellCount": 43, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 43, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 7, "text": "› ", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 1, "styleSummary": {"textCellCount": 1, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 1, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let continuation = try #require(ShowCLITerminalScreenSnapshot(json: continuationJSON))
        let idle = try #require(ShowCLITerminalScreenSnapshot(json: idleJSON))

        #expect(ShowCLINativeInteractionScope.hasActiveContinuation(in: continuation))
        #expect(!ShowCLINativeInteractionScope.hasActiveContinuation(in: idle))
    }

    @Test func nativeInteractionScopeExposesCurrentInputAnchorLine() {
        let snapshot = ShowCLITerminalScreenSnapshot(
            columns: 120,
            rows: 20,
            cursor: .init(x: 4, y: 12, visible: true),
            lines: [
                .init(index: 2, text: "› /old", selected: false),
                .init(index: 3, text: "/old-command  stale suggestion", selected: false),
                .init(index: 12, text: "› /mod", selected: false),
                .init(index: 13, text: "/model        choose what model and reasoning effort to use", selected: false),
            ]
        )

        #expect(
            ShowCLINativeInteractionScope.inputAnchorScreenLineIndex(
                in: snapshot,
                currentInput: "/mod"
            ) == 12
        )
        #expect(
            ShowCLINativeInteractionScope.inputAnchorScreenLineIndex(
                in: snapshot,
                currentInput: "/missing"
            ) == nil
        )
    }

    @Test func nativeInteractionScopeUsesLowerBoundForContinuationMenus() throws {
        let json = """
        {
          "columns": 176,
          "rows": 48,
          "cursor": {"x": 76, "y": 16, "visible": true},
          "lines": [
            {"index": 2, "text": "  Old Menu", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 9, "styleSummary": {"textCellCount": 8, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 8, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 3, "text": "", "selected": false, "firstNonBlankColumn": null, "lastNonBlankColumn": null, "styleSummary": {"textCellCount": 0, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 4, "text": "  1. Old", "selected": true, "firstNonBlankColumn": 2, "lastNonBlankColumn": 9, "styleSummary": {"textCellCount": 8, "selectedCellCount": 8, "selectedTextCellCount": 8, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 8, "foregroundTextCellCount": 0}},
            {"index": 5, "text": "  2. Stale", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 11, "styleSummary": {"textCellCount": 10, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 5, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 6, "text": "", "selected": false, "firstNonBlankColumn": null, "lastNonBlankColumn": null, "styleSummary": {"textCellCount": 0, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 7, "text": "  Press enter to confirm or esc to go back", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 41, "styleSummary": {"textCellCount": 40, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 40, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 13, "text": "  Select Reasoning Level", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 25, "styleSummary": {"textCellCount": 24, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 24, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 14, "text": "", "selected": false, "firstNonBlankColumn": null, "lastNonBlankColumn": null, "styleSummary": {"textCellCount": 0, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 15, "text": "  1. Low     Fast responses", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 27, "styleSummary": {"textCellCount": 26, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 15, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 16, "text": "  2. Medium  Balanced", "selected": true, "firstNonBlankColumn": 2, "lastNonBlankColumn": 21, "styleSummary": {"textCellCount": 20, "selectedCellCount": 20, "selectedTextCellCount": 20, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 20, "foregroundTextCellCount": 0}},
            {"index": 17, "text": "  3. High    Deep reasoning", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 28, "styleSummary": {"textCellCount": 27, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 17, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let snapshot = try #require(ShowCLITerminalScreenSnapshot(json: json))

        let scopedRows = ShowCLINativeInteractionScope.rows(
            from: snapshot,
            currentInput: "",
            minimumScreenLineIndex: 12
        )

        #expect(scopedRows.map(\.text) == [
            "1. Low     Fast responses",
            "2. Medium  Balanced",
            "3. High    Deep reasoning",
        ])
        #expect(scopedRows.map(\.isSelected) == [false, true, false])
        #expect(
            !ShowCLINativeInteractionScope.hasActiveContinuation(
                in: snapshot,
                minimumScreenLineIndex: 18
            )
        )
    }

    @Test func nativeInteractionScopeDoesNotTreatPreEnterSlashMenuAsContinuation() throws {
        let json = """
        {
          "columns": 176,
          "rows": 48,
          "cursor": {"x": 2, "y": 9, "visible": true},
          "lines": [
            {"index": 8, "text": "› /", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 2, "styleSummary": {"textCellCount": 2, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 1, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 9, "text": "/model        choose what model and reasoning effort to use", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 56, "styleSummary": {"textCellCount": 57, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 37, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 10, "text": "/ide          include current selection, open files, and other context from your IDE", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 77, "styleSummary": {"textCellCount": 78, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 58, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 11, "text": "/permissions  choose what Codex is allowed to do", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 45, "styleSummary": {"textCellCount": 46, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 26, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 12, "text": "/keymap       remap TUI shortcuts", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 32, "styleSummary": {"textCellCount": 33, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 33}},
            {"index": 13, "text": "/vim          toggle Vim mode for the composer", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 43, "styleSummary": {"textCellCount": 44, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 24, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let preEnterSnapshot = try #require(ShowCLITerminalScreenSnapshot(json: json))
        let postEnterSnapshot = preEnterSnapshot

        #expect(
            !ShowCLINativeInteractionScope.hasActiveContinuation(
                in: postEnterSnapshot,
                minimumScreenLineIndex: 8,
                excludingRowsUnchangedFrom: preEnterSnapshot
            )
        )
    }

    @Test func nativeInteractionScopeKeepsPostEnterContinuationThatChangedFromPreEnterMenu() throws {
        let preEnterJSON = """
        {
          "columns": 176,
          "rows": 48,
          "cursor": {"x": 2, "y": 9, "visible": true},
          "lines": [
            {"index": 8, "text": "› /model", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 7, "styleSummary": {"textCellCount": 7, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 1, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 9, "text": "/model        choose what model and reasoning effort to use", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 56, "styleSummary": {"textCellCount": 57, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 37, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let continuationJSON = """
        {
          "columns": 176,
          "rows": 48,
          "cursor": {"x": 76, "y": 16, "visible": true},
          "lines": [
            {"index": 13, "text": "  Select Reasoning Level", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 25, "styleSummary": {"textCellCount": 24, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 24, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 14, "text": "", "selected": false, "firstNonBlankColumn": null, "lastNonBlankColumn": null, "styleSummary": {"textCellCount": 0, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 15, "text": "  1. Low     Fast responses", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 27, "styleSummary": {"textCellCount": 26, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 15, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}},
            {"index": 16, "text": "  2. Medium  Balanced", "selected": true, "firstNonBlankColumn": 2, "lastNonBlankColumn": 21, "styleSummary": {"textCellCount": 20, "selectedCellCount": 20, "selectedTextCellCount": 20, "boldTextCellCount": 0, "faintTextCellCount": 0, "inverseTextCellCount": 0, "backgroundTextCellCount": 20, "foregroundTextCellCount": 0}},
            {"index": 17, "text": "  3. High    Deep reasoning", "selected": false, "firstNonBlankColumn": 2, "lastNonBlankColumn": 28, "styleSummary": {"textCellCount": 27, "selectedCellCount": 0, "selectedTextCellCount": 0, "boldTextCellCount": 0, "faintTextCellCount": 17, "inverseTextCellCount": 0, "backgroundTextCellCount": 0, "foregroundTextCellCount": 0}}
          ]
        }
        """
        let preEnterSnapshot = try #require(ShowCLITerminalScreenSnapshot(json: preEnterJSON))
        let continuation = try #require(ShowCLITerminalScreenSnapshot(json: continuationJSON))

        #expect(
            ShowCLINativeInteractionScope.hasActiveContinuation(
                in: continuation,
                minimumScreenLineIndex: 8,
                excludingRowsUnchangedFrom: preEnterSnapshot
            )
        )
    }

    @Test func nativeInteractionLineIDDoesNotChangeWhenSelectionMoves() {
        let row = ShowCLINativeInteractionLine(
            screenLineIndex: 7,
            text: "/keymap       remap TUI shortcuts",
            isSelected: false
        )

        #expect(row.id == row.withSelection(true).id)
    }

    @Test func nativeInteractionRefreshBurstOutlastsResolvingSettleWindow() {
        let lastRefreshDelay = ShowCLINativeInteractionTiming.refreshBurstDelays.last ?? 0

        #expect(lastRefreshDelay > ShowCLINativeInteractionTiming.resolvingSettleInterval)
    }

    @Test func itemMarkerIsStructureNotDisplayContent() {
        let blocks = ShowCLITranscriptBlockizer.blockizeOutput(
            "• Ran true\n  └ (no output)\n",
            terminalColumns: 112
        )

        #expect(blocks.count == 1)
        #expect(blocks[0].variant == .toolLike)
        #expect(blocks[0].text == "• Ran true\n  └ (no output)\n")
        #expect(blocks[0].displayText == "Ran true\n  └ (no output)\n")
        #expect(blocks[0].transcriptFeatures.marker.text == "•")
        #expect(blocks[0].transcriptFeatures.marker.kind == .itemMarker)
    }

    @Test func promptMarkerIsSeparatedFromPromptDisplayText() {
        let blocks = ShowCLITranscriptBlockizer.blockizeOutput(
            "› Write tests for @filename\n\n  gpt-5.5 medium · ~/Project",
            terminalColumns: 112
        )

        #expect(blocks.count == 1)
        #expect(blocks[0].variant == .prompt)
        #expect(blocks[0].confidence == .high)
        #expect(blocks[0].text.hasPrefix("› Write tests"))
        #expect(blocks[0].displayText.hasPrefix("Write tests"))
        #expect(blocks[0].transcriptFeatures.marker.kind == .promptMarker)
    }

    @Test func rawTextReconstructsProjectionAcrossItems() {
        let projection = [
            "• Ran pwd",
            "  └ /Users/showing/A-ThinkBig/Project-ShowCLI",
            "",
            "────────────────────────────────────────────────────────",
            "",
            "• 已完成。",
            "",
            "› Write tests for @filename",
        ].joined(separator: "\n")

        let blocks = ShowCLITranscriptBlockizer.blockizeOutput(
            projection,
            terminalColumns: 112
        )

        #expect(blocks.count == 4)
        #expect(blocks.map(\.text).joined(separator: "\n") == projection)
        #expect(blocks.map(\.variant) == [.toolLike, .status, .proseLike, .prompt])
    }

    @Test func fileMutationHintsDecorateToolLikeItems() {
        let blocks = ShowCLITranscriptBlockizer.blockizeOutput(
            "• Added corpus/tmp-note.md (+1 -0)",
            terminalColumns: 112
        )

        #expect(blocks.count == 1)
        #expect(blocks[0].variant == .toolLike)
        #expect(blocks[0].transcriptFeatures.hintIDs == ["codex.tool.edited"])
    }

    @Test func skillContextBudgetWarningIsTerminalStatusChrome() {
        let warning = "⚠ Skill descriptions were shortened to fit the 2% skills context budget."
        let blocks = ShowCLITranscriptBlockizer.blockizeOutput(
            warning,
            terminalColumns: 112
        )

        #expect(blocks.count == 1)
        #expect(blocks[0].variant == .status)
        #expect(blocks[0].transcriptFeatures.hintIDs == ["codex.status.skill_context_budget"])
        #expect(ShowCLIReadingPresentation.isToolChromeBlock(blocks[0]))
        #expect(blocks[0].text == warning)
    }

    @Test func ambiguousProjectionFallsBackWithoutDroppingText() {
        let projection = "plain repaint fragment without marker"
        let blocks = ShowCLITranscriptBlockizer.blockizeOutput(
            projection,
            terminalColumns: 112
        )

        #expect(blocks.count == 1)
        #expect(blocks[0].variant == .unknown)
        #expect(blocks[0].confidence == .low)
        #expect(blocks[0].text == projection)
        #expect(blocks[0].displayText == projection)
    }

    @Test func presentationHidesPureDividerChrome() {
        let projection = [
            "────────────────────────────────────────────────────────",
            "────────────────────────────────────────────────────────",
        ].joined(separator: "\n")
        let blocks = ShowCLITranscriptBlockizer.blockizeOutput(
            projection,
            terminalColumns: 112
        )

        #expect(blocks.count == 2)
        #expect(blocks.allSatisfy { ShowCLIReadingPresentation.isHiddenChromeBlock($0) })
        #expect(blocks.map(\.text).joined(separator: "\n") == projection)
    }

    @Test func presentationPromptBubbleUsesOnlyPromptText() {
        let blocks = ShowCLITranscriptBlockizer.blockizeOutput(
            "› Write tests for @filename\n\n  gpt-5.5 medium · ~",
            terminalColumns: 112
        )

        #expect(blocks.count == 1)
        #expect(ShowCLIReadingPresentation.promptText(for: blocks[0]) == "Write tests for @filename")
        #expect(ShowCLIReadingPresentation.isPromptBlock(blocks[0]))
        #expect(!ShowCLIReadingPresentation.isUserPromptBlock(blocks[0]))
        #expect(ShowCLIReadingPresentation.isToolChromeBlock(blocks[0]))
    }

    @Test func presentationAppInputPreservesMultilineComposerText() {
        let block = ShowCLIReadingBlock(
            kind: .input,
            text: "Line one\nLine two"
        )

        #expect(ShowCLIReadingPresentation.promptText(for: block) == "Line one\nLine two")
        #expect(ShowCLIReadingPresentation.chatText(for: block) == "Line one\nLine two")
        #expect(ShowCLIReadingPresentation.isUserPromptBlock(block))
        #expect(!ShowCLIReadingPresentation.isToolChromeBlock(block))
    }

    @Test func presentationRecognizesToolChromeWithoutHidingRawText() {
        let blocks = ShowCLITranscriptBlockizer.blockizeOutput(
            "• Ran pwd\n  └ /Users/showing/A-ThinkBig/Project-ShowCLI",
            terminalColumns: 112
        )

        #expect(blocks.count == 1)
        #expect(ShowCLIReadingPresentation.isToolChromeBlock(blocks[0]))
        #expect(!ShowCLIReadingPresentation.isHiddenChromeBlock(blocks[0]))
        #expect(blocks[0].text.hasPrefix("• Ran pwd"))
    }

    @Test func presentationJoinsTerminalSoftWrappedChineseProse() {
        let block = ShowCLIReadingBlock(
            kind: .output,
            text: "伦敦今天（2026年5月23日）偏热，白天大约 28°C，可能有少量降雨，体感接近夏天；外出建议穿轻薄衣物、带\n水，最好也备\n一把伞。\n来源：Weather25、Timeanddate、GlobalMeteo。",
            variant: .proseLike
        )

        let text = ShowCLIReadingPresentation.chatText(for: block)

        #expect(text.contains("带水，最好也备一把伞。"))
        #expect(text.contains("\n来源：Weather25、Timeanddate、GlobalMeteo。"))
        #expect(!text.contains("备\n一把"))
    }

    @Test func presentationJoinsEnglishSoftWrapWithSpaces() {
        let block = ShowCLIReadingBlock(
            kind: .output,
            text: "Bring a light rain jacket and keep\nan umbrella nearby.\nSource: Weather25.",
            variant: .proseLike
        )

        let text = ShowCLIReadingPresentation.chatText(for: block)

        #expect(text.contains("keep an umbrella nearby."))
        #expect(text.contains("\nSource: Weather25."))
    }

    @Test func presentationJoinsWrappedLabelContinuation() {
        let block = ShowCLIReadingBlock(
            kind: .output,
            text: "来源：Weather25、Timeanddate、\nGlobalMeteo。",
            variant: .proseLike
        )

        let text = ShowCLIReadingPresentation.chatText(for: block)

        #expect(text == "来源：Weather25、Timeanddate、GlobalMeteo。")
    }

    @Test func presentationPreservesMarkdownListStructureWhileJoiningProse() {
        let block = ShowCLIReadingBlock(
            kind: .output,
            text: "Weather summary for today\naround London:\n- temperature: warm\n- rain: possible\nSource: Weather25.",
            variant: .proseLike
        )

        let text = ShowCLIReadingPresentation.chatText(for: block)

        #expect(text.contains("Weather summary for today around London:"))
        #expect(text.contains("\n- temperature: warm\n- rain: possible"))
        #expect(text.contains("\nSource: Weather25."))
    }

    @Test func terminalPromptProjectionWithoutComposerSubmissionIsTerminalDetail() {
        let blocks = ShowCLITranscriptBlockizer.blockizeOutput(
            "› 北京天气呢?\n\n  gpt-5.5 medium · ~/Project",
            terminalColumns: 112
        )

        #expect(blocks.count == 1)
        #expect(blocks[0].kind == .output)
        #expect(blocks[0].variant == .prompt)
        #expect(blocks[0].isLiveProjection)
        #expect(ShowCLIReadingPresentation.promptText(for: blocks[0]) == "北京天气呢?")
        #expect(!ShowCLIReadingPresentation.isUserPromptBlock(blocks[0]))
        #expect(ShowCLIReadingPresentation.isToolChromeBlock(blocks[0]))
    }

    @Test func projectionModelPromotesMatchedComposerPromptToUserBubble() {
        let projection = [
            "› 北京天气呢?",
            "",
            "• 北京今天晴，气温约 18-29°C。",
        ].joined(separator: "\n")

        let blocks = ShowCLIReadingProjectionModel.blocks(
            from: projection,
            terminalColumns: 112,
            composerSubmissions: [
                ShowCLIComposerSubmission(
                    text: "北京天气呢?",
                    submittedAt: Date(timeIntervalSince1970: 12)
                )
            ]
        )

        let userBlocks = blocks.filter(ShowCLIReadingPresentation.isUserPromptBlock)

        #expect(userBlocks.count == 1)
        #expect(userBlocks[0].kind == .input)
        #expect(userBlocks[0].isLiveProjection)
        #expect(ShowCLIReadingPresentation.chatText(for: userBlocks[0]) == "北京天气呢?")
        #expect(ShowCLIReadingProjectionModel.rawText(from: blocks) == projection)
    }

    @Test func projectionModelDoesNotPromoteUnmatchedPromptPlaceholder() {
        let projection = [
            "• Finished previous task.",
            "",
            "› Suggested next task",
            "",
            "  gpt-5.5 medium · ~/Project",
        ].joined(separator: "\n")

        let blocks = ShowCLIReadingProjectionModel.blocks(
            from: projection,
            terminalColumns: 112,
            composerSubmissions: [
                ShowCLIComposerSubmission(
                    text: "A different submitted prompt",
                    submittedAt: Date(timeIntervalSince1970: 12)
                )
            ]
        )

        #expect(blocks.contains { $0.variant == .prompt && $0.kind == .output })
        #expect(!blocks.contains { ShowCLIReadingPresentation.isUserPromptBlock($0) })
        #expect(blocks.contains { ShowCLIReadingPresentation.isToolChromeBlock($0) })
        #expect(ShowCLIReadingProjectionModel.rawText(from: blocks) == projection)
    }

    @Test func projectionModelDoesNotReuseConsumedComposerSubmissionForLaterPrompt() {
        let submission = ShowCLIComposerSubmission(
            text: "北京天气呢?",
            submittedAt: Date(timeIntervalSince1970: 12)
        )
        let projection = [
            "• 北京今天晴，气温约 18-29°C。",
            "",
            "› 北京天气呢?",
        ].joined(separator: "\n")

        let blocks = ShowCLIReadingProjectionModel.blocks(
            from: projection,
            terminalColumns: 112,
            composerSubmissions: [submission],
            consumedComposerSubmissionIDs: [submission.id]
        )

        #expect(!blocks.contains { ShowCLIReadingPresentation.isUserPromptBlock($0) })
        #expect(blocks.contains { $0.variant == .prompt && $0.kind == .output })
        #expect(ShowCLIReadingProjectionModel.rawText(from: blocks) == projection)
    }

    @Test func projectionModelRebuildsFromLatestTerminalProjection() {
        let previousProjection = [
            "› 伦敦今天天气怎么样?",
            "",
            "• 伦敦今天偏热。",
        ].joined(separator: "\n")

        let latestProjection = [
            "› 北京天气呢?",
            "",
            "• 北京今天晴，气温约 18-29°C。",
        ].joined(separator: "\n")

        let previousBlocks = ShowCLIReadingProjectionModel.blocks(
            from: previousProjection,
            terminalColumns: 112
        )
        let rebuiltBlocks = ShowCLIReadingProjectionModel.blocks(
            from: latestProjection,
            terminalColumns: 112,
            previousBlocks: previousBlocks
        )
        let raw = ShowCLIReadingProjectionModel.rawText(from: rebuiltBlocks)

        #expect(raw == latestProjection)
        #expect(!raw.contains("伦敦今天偏热。"))
        #expect(raw.contains("北京今天晴，气温约 18-29°C。"))
        #expect(rebuiltBlocks.allSatisfy { $0.isLiveProjection })
        #expect(!rebuiltBlocks.contains { $0.kind == .input })
    }

    @Test func projectionModelDoesNotAppendAfterOptimisticInputBlock() {
        let previousProjection = [
            "› 伦敦今天天气怎么样?",
            "",
            "• Searching the web",
            "",
            "• 伦敦今天（2026年5月23日）天气晴朗偏热。",
            "",
            "来源：GlobalMeteo 今日伦敦预报。",
        ].joined(separator: "\n")

        let previousBlocks = ShowCLIReadingProjectionModel.blocks(
            from: previousProjection,
            terminalColumns: 112
        ) + [
            ShowCLIReadingBlock(
                kind: .input,
                text: "北京天气呢?",
                isLiveProjection: false
            )
        ]

        let latestProjection = [
            "› 伦敦今天天气怎么样?",
            "",
            "• Searching the web",
            "",
            "• 伦敦今天（2026年5月23日）天气晴朗偏热。",
            "",
            "来源：GlobalMeteo 今日伦敦预报。",
            "",
            "› 北京天气呢?",
            "",
            "• Searching the web",
            "",
            "• 北京今天晴，气温约 18-29°C。",
        ].joined(separator: "\n")

        let rebuiltBlocks = ShowCLIReadingProjectionModel.blocks(
            from: latestProjection,
            terminalColumns: 112,
            previousBlocks: previousBlocks,
            composerSubmissions: [
                ShowCLIComposerSubmission(
                    text: "北京天气呢?",
                    submittedAt: Date(timeIntervalSince1970: 24)
                )
            ]
        )
        let raw = ShowCLIReadingProjectionModel.rawText(from: rebuiltBlocks)

        #expect(raw == latestProjection)
        #expect(raw.components(separatedBy: "伦敦今天（2026年5月23日）天气晴朗偏热。").count - 1 == 1)
        #expect(raw.components(separatedBy: "北京今天晴，气温约 18-29°C。").count - 1 == 1)
        #expect(rebuiltBlocks.filter { $0.kind == .input }.count == 1)
        #expect(rebuiltBlocks.contains { ShowCLIReadingPresentation.isUserPromptBlock($0) && ShowCLIReadingPresentation.chatText(for: $0) == "北京天气呢?" })
    }
}
