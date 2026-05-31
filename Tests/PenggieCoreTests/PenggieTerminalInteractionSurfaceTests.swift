import Foundation
import Testing
@testable import PenggieCore

@Suite
struct PenggieTerminalInteractionSurfaceTests {
    @Test
    func resumePickerSurfaceCarriesFrameIdentityCandidatesAndSelection() {
        let frame = PenggieTerminalFrame(
            id: 11,
            observedAt: Date(timeIntervalSince1970: 1_800_000_011),
            visibleText: """
            Resume a previous session
            Type to search
            Filter: [Cwd] All     Sort: [Updated] Created
            › 1h ago    对比一下伦敦和巴黎
              2h ago    伦敦天气怎么样?
            enter resume  esc exit
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )

        let surface = PenggieTerminalBehaviorZoner.classify(frame: frame)

        #expect(surface?.kind == .resumePicker)
        #expect(surface?.frameID == 11)
        #expect(surface?.candidates.count == 2)
        #expect(surface?.selectionConfidence == .reliable)
        #expect(surface?.hasFreshConfirmableSelection == true)
        #expect(surface?.zones.contains(where: { $0.kind == .keyboardSelectableList }) == true)
    }

    @Test
    func approvalPromptSurfaceIsModalChoiceAndUsesTerminalMarker() {
        let frame = PenggieTerminalFrame(
            id: 12,
            observedAt: Date(timeIntervalSince1970: 1_800_000_012),
            visibleText: """
            Approve command?
            › Allow once
              Deny
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )

        let surface = PenggieTerminalBehaviorZoner.classify(frame: frame)

        #expect(surface?.kind == .approvalPrompt)
        #expect(surface?.frameID == 12)
        #expect(surface?.candidates.map(\.text) == ["Allow once", "Deny"])
        #expect(surface?.selectionConfidence == .reliable)
        #expect(surface?.hasFreshConfirmableSelection == true)
        #expect(surface?.zones.contains(where: { $0.kind == .modalChoice }) == true)
    }

    @Test
    func permissionPromptSurfaceIsModalChoiceAndUsesTerminalMarker() {
        let frame = PenggieTerminalFrame(
            id: 17,
            observedAt: Date(timeIntervalSince1970: 1_800_000_017),
            visibleText: """
            Permission required to edit files
              Allow once
            › Deny
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )

        let surface = PenggieTerminalBehaviorZoner.classify(frame: frame)

        #expect(surface?.kind == .permissionPrompt)
        #expect(surface?.frameID == 17)
        #expect(surface?.candidates.map(\.text) == ["Allow once", "Deny"])
        #expect(surface?.selectionConfidence == .reliable)
        #expect(surface?.hasFreshConfirmableSelection == true)
        #expect(surface?.zones.contains(where: { $0.kind == .modalChoice }) == true)
    }

    @Test
    func modelPickerSurfaceParsesNumberedCandidates() {
        let frame = PenggieTerminalFrame(
            id: 18,
            observedAt: Date(timeIntervalSince1970: 1_800_000_018),
            visibleText: """
            Select Model and Effort

              1. gpt-5.5 (current)
            › 2. gpt-5.4
              3. gpt-5.4-mini

            Press enter to confirm or esc to go back
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )

        let surface = PenggieTerminalBehaviorZoner.classify(frame: frame)

        #expect(surface?.kind == .modelPicker)
        #expect(surface?.frameID == 18)
        #expect(surface?.candidates.map(\.text) == [
            "1. gpt-5.5 (current)",
            "2. gpt-5.4",
            "3. gpt-5.4-mini"
        ])
        #expect(surface?.candidates.first?.id == "modelPicker:2:1. gpt-5.5 (current)")
        #expect(surface?.selectionConfidence == .reliable)
        #expect(surface?.hasFreshConfirmableSelection == true)
        #expect(surface?.zones.contains(where: { $0.kind == .keyboardSelectableList }) == true)
        #expect(surface?.zones.contains(where: { $0.kind == .footerHelp }) == true)
    }

    @Test
    func effortPickerSurfaceParsesNumberedCandidates() {
        let frame = PenggieTerminalFrame(
            id: 19,
            observedAt: Date(timeIntervalSince1970: 1_800_000_019),
            visibleText: """
            Select Reasoning Level for gpt-5.3-codex

              1. Low               Fast responses with lighter reasoning
            › 2. Medium (default)  Balances speed and reasoning depth
              3. High (current)    Greater reasoning depth

            Press enter to confirm or esc to go back
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )

        let surface = PenggieTerminalBehaviorZoner.classify(frame: frame)

        #expect(surface?.kind == .effortPicker)
        #expect(surface?.frameID == 19)
        #expect(surface?.candidates.map(\.text) == [
            "1. Low               Fast responses with lighter reasoning",
            "2. Medium (default)  Balances speed and reasoning depth",
            "3. High (current)    Greater reasoning depth"
        ])
        #expect(surface?.selectionConfidence == .reliable)
        #expect(surface?.hasFreshConfirmableSelection == true)
    }

    @Test
    func terminalSurfacePolicyAllowsReliableConfirmAndBlocksMissingSelection() throws {
        let reliableFrame = PenggieTerminalFrame(
            id: 21,
            observedAt: Date(timeIntervalSince1970: 1_800_000_021),
            visibleText: """
            Select Model and Effort

            › 1. gpt-5.5
              2. gpt-5.4
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )
        let missingSelectionFrame = PenggieTerminalFrame(
            id: 22,
            observedAt: Date(timeIntervalSince1970: 1_800_000_022),
            visibleText: """
            Approve command?
              Allow once
              Deny
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )

        let reliableSurface = try #require(PenggieTerminalBehaviorZoner.classify(frame: reliableFrame))
        let missingSelectionSurface = try #require(PenggieTerminalBehaviorZoner.classify(frame: missingSelectionFrame))

        #expect(PenggieTerminalInputPolicy.commandDecision(.enter, surface: reliableSurface) == .unhandled)
        guard case .blocked = PenggieTerminalInputPolicy.commandDecision(.enter, surface: missingSelectionSurface) else {
            Issue.record("Expected Enter to be blocked without reliable terminal-owned selection")
            return
        }
        #expect(PenggieTerminalInputPolicy.commandDecision(.arrowDown, surface: missingSelectionSurface) == .unhandled)
    }

    @Test
    func reliableConfirmIsRoutedForResumeModelAndApprovalSurfaces() throws {
        let resume = try #require(PenggieTerminalBehaviorZoner.classify(frame: PenggieTerminalFrame(
            id: 51,
            observedAt: Date(timeIntervalSince1970: 1_800_000_051),
            visibleText: """
            Resume a previous session
            Type to search
            › 1h ago    对比一下伦敦和巴黎
              2h ago    伦敦天气怎么样?
            enter resume  esc exit
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )))
        let model = try #require(PenggieTerminalBehaviorZoner.classify(frame: PenggieTerminalFrame(
            id: 52,
            observedAt: Date(timeIntervalSince1970: 1_800_000_052),
            visibleText: """
            Select Model and Effort
            › 1. gpt-5.5
              2. gpt-5.4
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )))
        let approval = try #require(PenggieTerminalBehaviorZoner.classify(frame: PenggieTerminalFrame(
            id: 53,
            observedAt: Date(timeIntervalSince1970: 1_800_000_053),
            visibleText: """
            Approve command?
            › Allow once
              Deny
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )))

        for surface in [resume, model, approval] {
            #expect(surface.hasFreshConfirmableSelection)
            #expect(PenggieTerminalInputPolicy.commandDecision(.enter, surface: surface) == .unhandled)
        }
    }

    @Test
    func resumeSurfaceSelectionUsesCentralVisibleMarkerAndRegionEvidence() throws {
        let frame = PenggieTerminalFrame(
            id: 54,
            observedAt: Date(timeIntervalSince1970: 1_800_000_054),
            visibleText: """
            Resume a previous session
            Type to search
            › 1h ago    对比一下伦敦和巴黎
              2h ago    伦敦天气怎么样?
            enter resume  esc exit
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )

        let surface = try #require(PenggieTerminalBehaviorZoner.classify(frame: frame))

        guard case let .single(rowID, source, evidence) = surface.selection else {
            Issue.record("Expected visible marker to produce a single selected row")
            return
        }
        #expect(source == .visibleMarker)
        #expect(rowID == surface.candidates[0].id)
        #expect(evidence.contains(where: { $0.contains("contiguousRegion=2...3") }))
    }

    @Test
    func resumeSurfaceMapsScreenTextMarkerWhenRelativeAgeDriftsBetweenTerminalReads() throws {
        let frame = PenggieTerminalFrame(
            id: 59,
            observedAt: Date(timeIntervalSince1970: 1_800_000_059),
            visibleText: """
            Resume a previous session
            Type to search
            Filter: [Cwd] All     Sort: [Updated] Created
              1d ago    对比一下伦敦和巴黎
              1d ago    伦敦今天的天气怎么样?
            enter resume  esc exit
            """,
            screenText: """
            Resume a previous session
            Type to search
            Filter: [Cwd] All     Sort: [Updated] Created
            › 6h ago    对比一下伦敦和巴黎
              1d ago    伦敦今天的天气怎么样?
            enter resume  esc exit
            """,
            screenModelJSON: nil,
            processExited: false
        )

        let surface = try #require(PenggieTerminalBehaviorZoner.classify(frame: frame))

        guard case let .single(rowID, source, _) = surface.selection else {
            Issue.record("Expected screen text marker to select the matching visible resume row")
            return
        }
        #expect(surface.selectionConfidence == .reliable)
        #expect(surface.hasFreshConfirmableSelection)
        #expect(source == .visibleMarker)
        #expect(rowID == surface.candidates.first?.id)
    }

    @Test
    func resumeSurfaceTreatsHeavyChevronAsTerminalSelectionMarker() throws {
        let alternatingRowBackground = PenggieTerminalScreenSnapshot.Line.StyleSummary(
            textCellCount: 28,
            selectedCellCount: 0,
            selectedTextCellCount: 0,
            boldTextCellCount: 0,
            faintTextCellCount: 12,
            inverseTextCellCount: 0,
            backgroundTextCellCount: 28,
            foregroundTextCellCount: 0,
            backgroundCellCount: 127,
            backgroundOnlyCellCount: 99
        )
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 140,
            rows: 40,
            cursor: nil,
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "Filter: [Cwd] All     Sort: [Updated] Created", selected: false),
                .init(index: 3, text: "  ❯ 6h ago      对 比 一 下 伦 敦 和 巴 黎", selected: false),
                .init(index: 4, text: "    1d ago      对 比 一 下 伦 敦 和 巴 黎", selected: false, styleSummary: alternatingRowBackground),
                .init(index: 5, text: "    1d ago      伦 敦 今 天 的 天 气 怎 么 样 ？", selected: false),
                .init(index: 6, text: "    1d ago      伦 敦 今 天 天 气 怎 么 样 ？", selected: false, styleSummary: alternatingRowBackground),
                .init(index: 7, text: "enter resume  esc exit", selected: false)
            ]
        )
        let snapshotJSON = String(
            data: try JSONEncoder().encode(snapshot),
            encoding: .utf8
        )!
        let frame = PenggieTerminalFrame(
            id: 67,
            observedAt: Date(timeIntervalSince1970: 1_800_000_067),
            visibleText: """
            Resume a previous session
            Type to search
            Filter: [Cwd] All     Sort: [Updated] Created
            6h ago      对比一下伦敦和巴黎
            1d ago      对比一下伦敦和巴黎
            1d ago      伦敦今天的天气怎么样？
            1d ago      伦敦今天天气怎么样？
            enter resume  esc exit
            """,
            screenText: "",
            screenModelJSON: snapshotJSON,
            processExited: false
        )

        let surface = try #require(PenggieTerminalBehaviorZoner.classify(frame: frame))

        #expect(surface.kind == .resumePicker)
        #expect(surface.selectionConfidence == .reliable)
        #expect(surface.hasFreshConfirmableSelection)
        guard case let .single(rowID, source, evidence) = surface.selection else {
            Issue.record("Expected heavy chevron marker to win over ambiguous row background styles")
            return
        }
        #expect(source == .screenModelMarker)
        #expect(rowID == surface.candidates[0].id)
        #expect(evidence.contains(where: { $0.contains("line=3") }))
    }

    @Test
    func resumeSurfaceFallsBackToScreenModelStyleForRawTerminalParity() throws {
        let selectedStyle = selectedStyle(textCellCount: 24)
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: nil,
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "1h ago    对比一下伦敦和巴黎", selected: false),
                .init(index: 3, text: "2h ago    伦敦天气怎么样?", selected: false, styleSummary: selectedStyle),
                .init(index: 4, text: "enter resume  esc exit", selected: false)
            ]
        )
        let frame = terminalFrame(id: 55, snapshot: snapshot)

        let surface = try #require(PenggieTerminalBehaviorZoner.classify(frame: frame))

        #expect(surface.kind == .resumePicker)
        guard case let .single(rowID, source, evidence) = surface.selection else {
            Issue.record("Expected screen-model style to produce a single selected row")
            return
        }
        #expect(source == .explicitSelectedCells)
        #expect(rowID == surface.candidates[1].id)
        #expect(evidence.contains(where: { $0.contains("line=3") }))
    }

    @Test
    func resumeSurfaceKeepsRowsVisibleWithLowConfidenceWhenParityCannotBeProven() throws {
        let frame = PenggieTerminalFrame(
            id: 56,
            observedAt: Date(timeIntervalSince1970: 1_800_000_056),
            visibleText: """
            Resume a previous session
            Type to search
              1h ago    对比一下伦敦和巴黎
              2h ago    伦敦天气怎么样?
            enter resume  esc exit
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )

        let surface = try #require(PenggieTerminalBehaviorZoner.classify(frame: frame))

        #expect(surface.candidates.count == 2)
        #expect(surface.selectionConfidence == .low)
        #expect(!surface.hasFreshConfirmableSelection)
        if case .none = surface.selection {} else {
            Issue.record("Expected low-confidence resume surface to avoid fabricating a selected row")
        }
    }

    @Test
    func candidateViewportKeepsSelectedRowVisibleWithoutScrollState() {
        let candidates = (0..<12).map { index in
            PenggieTerminalInteractionCandidate(
                id: "row-\(index)",
                sourceLineIndex: index,
                text: "Row \(index)",
                isConfirmable: true
            )
        }

        let nearTop = PenggieTerminalInteractionCandidateViewport.derive(
            candidates: candidates,
            selectedRowID: "row-2",
            maxVisibleCount: 5
        )
        #expect(nearTop.candidates.map(\.id) == ["row-0", "row-1", "row-2", "row-3", "row-4"])
        #expect(nearTop.hasLeadingOverflow == false)
        #expect(nearTop.hasTrailingOverflow == true)

        let nearBottom = PenggieTerminalInteractionCandidateViewport.derive(
            candidates: candidates,
            selectedRowID: "row-9",
            maxVisibleCount: 5
        )
        #expect(nearBottom.candidates.map(\.id) == ["row-6", "row-7", "row-8", "row-9", "row-10"])
        #expect(nearBottom.hasLeadingOverflow == true)
        #expect(nearBottom.hasTrailingOverflow == true)

        let missingSelection = PenggieTerminalInteractionCandidateViewport.derive(
            candidates: candidates,
            selectedRowID: nil,
            maxVisibleCount: 5
        )
        #expect(missingSelection.candidates.map(\.id) == ["row-0", "row-1", "row-2", "row-3", "row-4"])
    }

    @Test
    func transcriptMentionsApprovalWithoutChoicesDoesNotBecomeActiveSurface() {
        let frame = PenggieTerminalFrame(
            id: 13,
            observedAt: Date(timeIntervalSince1970: 1_800_000_013),
            visibleText: """
            The approval process should be documented in the README.
            There are no active terminal choices here.
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )

        #expect(PenggieTerminalBehaviorZoner.classify(frame: frame) == nil)
    }

    @Test
    func historicalModelTextWithoutPickerHeaderDoesNotBecomeSurface() {
        let frame = PenggieTerminalFrame(
            id: 20,
            observedAt: Date(timeIntervalSince1970: 1_800_000_020),
            visibleText: """
            Earlier we compared 1. gpt-5.5 and 2. gpt-5.4 in the docs.
            This is transcript content, not a visible terminal picker.
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )

        #expect(PenggieTerminalBehaviorZoner.classify(frame: frame) == nil)
    }

    @Test
    func historicalResumeTextWithoutActivePickerChromeDoesNotBecomeSurface() {
        let frame = PenggieTerminalFrame(
            id: 15,
            observedAt: Date(timeIntervalSince1970: 1_800_000_015),
            visibleText: """
            You can resume a previous session later from the terminal.
            This is ordinary assistant prose, not the Codex picker UI.
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )

        #expect(PenggieTerminalBehaviorZoner.classify(frame: frame) == nil)
    }

    @Test
    func historicalSlashTextWithoutActiveComposerInputDoesNotBecomeSurface() {
        let frame = PenggieTerminalFrame(
            id: 16,
            observedAt: Date(timeIntervalSince1970: 1_800_000_016),
            visibleText: """
            Useful commands include /model, /permissions, and /status.
            This paragraph is transcript content, not a keyboard-owned menu.
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )

        #expect(PenggieTerminalBehaviorZoner.classify(frame: frame) == nil)
    }

    @Test
    func slashSurfaceUsesCurrentTerminalRowsWithoutLocalCommandList() {
        let frame = PenggieTerminalFrame(
            id: 14,
            observedAt: Date(timeIntervalSince1970: 1_800_000_014),
            visibleText: """
            › /
            › /model        choose what model and reasoning effort to use
              /permissions  choose what Codex is allowed to do
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )

        let surface = PenggieTerminalBehaviorZoner.classify(frame: frame, currentInput: "/")

        #expect(surface?.kind == .slashSuggestions)
        #expect(surface?.frameID == 14)
        #expect(surface?.candidates.map(\.text) == [
            "› /model        choose what model and reasoning effort to use",
            "/permissions  choose what Codex is allowed to do"
        ])
        #expect(surface?.selectionConfidence == .reliable)
        #expect(surface?.hasFreshConfirmableSelection == true)
    }

    @Test
    func slashContinuationSurfaceClassifiesNumberedContinuationMenu() throws {
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 90,
            rows: 24,
            cursor: nil,
            lines: [
                .init(index: 0, text: "› /model", selected: false),
                .init(index: 1, text: "Select Model and Effort", selected: false),
                .init(index: 2, text: "› 1. gpt-5.5 high", selected: false),
                .init(index: 3, text: "  2. gpt-5.4 mini", selected: false),
                .init(index: 4, text: "Press enter to confirm or esc to go back", selected: false)
            ]
        )
        let frame = terminalFrame(id: 57, snapshot: snapshot)

        let surface = try #require(PenggieTerminalBehaviorZoner.classify(frame: frame, currentInput: "/model"))

        #expect(surface.kind == .slashContinuation)
        #expect(surface.frameID == 57)
        #expect(surface.candidates.contains { $0.text.contains("1. gpt-5.5 high") })
        #expect(surface.selectionConfidence == .reliable)
    }

    @Test
    func terminalFrameIdentityIsCarriedByEverySupportedSurfaceProjection() throws {
        let fixtures: [(Int, PenggieTerminalFrame, String?, PenggieTerminalInteractionSurfaceKind)] = [
            (61, PenggieTerminalFrame(
                id: 61,
                observedAt: Date(timeIntervalSince1970: 1_800_000_061),
                visibleText: """
                Resume a previous session
                Type to search
                › 1h ago    对比一下伦敦和巴黎
                enter resume  esc exit
                """,
                screenText: "",
                screenModelJSON: nil,
                processExited: false
            ), nil, .resumePicker),
            (62, PenggieTerminalFrame(
                id: 62,
                observedAt: Date(timeIntervalSince1970: 1_800_000_062),
                visibleText: """
                Approve command?
                › Allow once
                  Deny
                """,
                screenText: "",
                screenModelJSON: nil,
                processExited: false
            ), nil, .approvalPrompt),
            (63, PenggieTerminalFrame(
                id: 63,
                observedAt: Date(timeIntervalSince1970: 1_800_000_063),
                visibleText: """
                Permission required
                › Allow once
                  Deny
                """,
                screenText: "",
                screenModelJSON: nil,
                processExited: false
            ), nil, .permissionPrompt),
            (64, PenggieTerminalFrame(
                id: 64,
                observedAt: Date(timeIntervalSince1970: 1_800_000_064),
                visibleText: """
                Select Model and Effort
                › 1. gpt-5.5
                  2. gpt-5.4
                """,
                screenText: "",
                screenModelJSON: nil,
                processExited: false
            ), nil, .modelPicker),
            (65, PenggieTerminalFrame(
                id: 65,
                observedAt: Date(timeIntervalSince1970: 1_800_000_065),
                visibleText: """
                Select Reasoning Level
                › 1. Low
                  2. High
                """,
                screenText: "",
                screenModelJSON: nil,
                processExited: false
            ), nil, .effortPicker),
            (66, PenggieTerminalFrame(
                id: 66,
                observedAt: Date(timeIntervalSince1970: 1_800_000_066),
                visibleText: """
                › /
                › /model        choose what model and reasoning effort to use
                  /permissions  choose what Codex is allowed to do
                """,
                screenText: "",
                screenModelJSON: nil,
                processExited: false
            ), "/", .slashSuggestions)
        ]

        for (frameID, frame, currentInput, expectedKind) in fixtures {
            let surface = try #require(PenggieTerminalBehaviorZoner.classify(
                frame: frame,
                currentInput: currentInput
            ))
            #expect(surface.frameID == frameID)
            #expect(surface.kind == expectedKind)
            #expect(surface.evidence.contains("frame=\(frameID)"))
        }
    }

    @Test
    func terminalInteractionFixtureCatalogClassifiesSupportedSurfacesAndNegativeTranscript() throws {
        let cases: [(String, String?, PenggieTerminalInteractionSurfaceKind, PenggieTerminalSelectionConfidence)] = [
            ("resume-filter-sort-pager-selected", nil, .resumePicker, .reliable),
            ("resume-unselected", nil, .resumePicker, .low),
            ("resume-ambiguous", nil, .resumePicker, .ambiguous),
            ("slash-suggestions", "/", .slashSuggestions, .reliable),
            ("slash-continuation", "/model", .slashContinuation, .reliable),
            ("model-picker", nil, .modelPicker, .reliable),
            ("effort-picker", nil, .effortPicker, .reliable),
            ("approval-prompt", nil, .approvalPrompt, .reliable),
            ("permission-prompt", nil, .permissionPrompt, .reliable)
        ]

        for (index, currentInput, expectedKind, expectedConfidence) in cases {
            let snapshot = try loadSurfaceFixtureSnapshot(named: index)
            let frame = terminalFrame(id: 100 + cases.firstIndex(where: { $0.0 == index })!, snapshot: snapshot)
            let surface = try #require(PenggieTerminalBehaviorZoner.classify(
                frame: frame,
                currentInput: currentInput
            ))

            #expect(surface.kind == expectedKind)
            #expect(surface.selectionConfidence == expectedConfidence)
            #expect(surface.frameID == frame.id)
            #expect(!surface.candidates.isEmpty)
        }

        let negativeText = try loadSurfaceFixtureText(named: "negative-historical-transcript")
        let negativeFrame = PenggieTerminalFrame(
            id: 199,
            observedAt: Date(timeIntervalSince1970: 1_800_000_199),
            visibleText: negativeText,
            screenText: negativeText,
            screenModelJSON: nil,
            processExited: false
        )
        #expect(PenggieTerminalBehaviorZoner.classify(frame: negativeFrame) == nil)
    }

    @Test
    func slashSurfaceUsesCentralStyleSelectionWhenMarkerIsMissing() throws {
        let style = selectedStyle(textCellCount: 61)
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 90,
            rows: 24,
            cursor: nil,
            lines: [
                .init(index: 0, text: "› /", selected: false),
                .init(
                    index: 1,
                    text: "/model        choose what model and reasoning effort to use",
                    selected: false,
                    styleSummary: style
                ),
                .init(index: 2, text: "/permissions  choose what Codex is allowed to do", selected: false)
            ]
        )
        let frame = terminalFrame(id: 41, snapshot: snapshot)

        let surface = try #require(PenggieTerminalBehaviorZoner.classify(frame: frame, currentInput: "/"))

        #expect(surface.kind == .slashSuggestions)
        #expect(surface.candidates.count == 2)
        #expect(surface.hasFreshConfirmableSelection == true)
        guard case let .single(rowID, source, _) = surface.selection else {
            Issue.record("Expected style-backed slash selection")
            return
        }
        #expect(source == .explicitSelectedCells)
        #expect(rowID == surface.candidates[0].id)
    }

    @Test
    func modelPickerUsesCentralCursorFallbackWhenNoMarkerOrStyleExists() throws {
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 80,
            rows: 24,
            cursor: .init(x: 0, y: 4, visible: true),
            lines: [
                .init(index: 0, text: "Select Model and Effort", selected: false),
                .init(index: 1, text: "", selected: false),
                .init(index: 2, text: "  1. gpt-5.5 (current)", selected: false),
                .init(index: 3, text: "  2. gpt-5.4", selected: false),
                .init(index: 4, text: "  3. gpt-5.4-mini", selected: false),
                .init(index: 5, text: "", selected: false),
                .init(index: 6, text: "Press enter to confirm or esc to go back", selected: false)
            ]
        )
        let frame = terminalFrame(id: 42, snapshot: snapshot)

        let surface = try #require(PenggieTerminalBehaviorZoner.classify(frame: frame))

        #expect(surface.kind == .modelPicker)
        #expect(surface.hasFreshConfirmableSelection == true)
        guard case let .single(rowID, source, _) = surface.selection else {
            Issue.record("Expected cursor-backed model picker selection")
            return
        }
        #expect(source == .cursorRow)
        #expect(rowID == surface.candidates[2].id)
    }
}

private func terminalFrame(
    id: Int,
    snapshot: PenggieTerminalScreenSnapshot
) -> PenggieTerminalFrame {
    let jsonData = try! JSONEncoder().encode(snapshot)
    let json = String(data: jsonData, encoding: .utf8)!
    let visibleText = snapshot.lines
        .sorted { $0.index < $1.index }
        .map(\.text)
        .joined(separator: "\n")

    return PenggieTerminalFrame(
        id: id,
        observedAt: Date(timeIntervalSince1970: TimeInterval(1_800_000_000 + id)),
        visibleText: visibleText,
        screenText: visibleText,
        screenModelJSON: json,
        processExited: false
    )
}

private func selectedStyle(textCellCount: Int) -> PenggieTerminalScreenSnapshot.Line.StyleSummary {
    PenggieTerminalScreenSnapshot.Line.StyleSummary(
        textCellCount: textCellCount,
        selectedCellCount: textCellCount,
        selectedTextCellCount: textCellCount,
        boldTextCellCount: 0,
        faintTextCellCount: 0,
        inverseTextCellCount: 0,
        backgroundTextCellCount: textCellCount,
        foregroundTextCellCount: 0,
        backgroundCellCount: textCellCount,
        backgroundOnlyCellCount: 0
    )
}

private func loadSurfaceFixtureSnapshot(named name: String) throws -> PenggieTerminalScreenSnapshot {
    let url = surfaceFixtureURL(named: name, pathExtension: "json")
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(PenggieTerminalScreenSnapshot.self, from: data)
}

private func loadSurfaceFixtureText(named name: String) throws -> String {
    try String(contentsOf: surfaceFixtureURL(named: name, pathExtension: "txt"), encoding: .utf8)
}

private func surfaceFixtureURL(named name: String, pathExtension: String) -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures")
        .appendingPathComponent("terminal-interaction-surfaces")
        .appendingPathComponent("\(name).\(pathExtension)")
}
