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

        let finalRow = PenggieTerminalInteractionCandidateViewport.derive(
            candidates: candidates,
            selectedRowID: "row-11",
            maxVisibleCount: 5
        )
        #expect(finalRow.candidates.map(\.id) == ["row-7", "row-8", "row-9", "row-10", "row-11"])
        #expect(finalRow.hasLeadingOverflow == true)
        #expect(finalRow.hasTrailingOverflow == false)

        let missingSelection = PenggieTerminalInteractionCandidateViewport.derive(
            candidates: candidates,
            selectedRowID: nil,
            maxVisibleCount: 5
        )
        #expect(missingSelection.candidates.map(\.id) == ["row-0", "row-1", "row-2", "row-3", "row-4"])
    }

    @Test
    func candidateListGeometryBudgetsOnlyWholeRows() {
        let empty = PenggieTerminalInteractionCandidateListGeometry.derive(
            candidateCount: 0,
            maxVisibleCount: 7,
            rowHeight: 38,
            rowSpacing: 6,
            verticalPadding: 10
        )
        #expect(empty.visibleRowCount == 0)
        #expect(empty.viewportHeight == 0)

        let shortList = PenggieTerminalInteractionCandidateListGeometry.derive(
            candidateCount: 3,
            maxVisibleCount: 7,
            rowHeight: 38,
            rowSpacing: 6,
            verticalPadding: 10
        )
        #expect(shortList.visibleRowCount == 3)
        #expect(shortList.viewportHeight == 146)

        let clippedList = PenggieTerminalInteractionCandidateListGeometry.derive(
            candidateCount: 12,
            maxVisibleCount: 5,
            rowHeight: 38,
            rowSpacing: 2,
            verticalPadding: 10
        )
        #expect(clippedList.visibleRowCount == 5)
        #expect(clippedList.viewportHeight == 218)
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
            ("resume-scrolled-selected", nil, .resumePicker, .reliable),
            ("resume-unselected", nil, .resumePicker, .low),
            ("resume-ambiguous", nil, .resumePicker, .ambiguous),
            ("resume-low-confidence", nil, .resumePicker, .low),
            ("slash-suggestions", "/", .slashSuggestions, .reliable),
            ("slash-style-selected", "/", .slashSuggestions, .reliable),
            ("slash-ambiguous", "/", .slashSuggestions, .ambiguous),
            ("slash-stale-unselected", "/", .slashSuggestions, .low),
            ("slash-continuation", "/model", .slashContinuation, .reliable),
            ("model-picker", nil, .modelPicker, .reliable),
            ("model-cursor-fallback", nil, .modelPicker, .reliable),
            ("model-stale-unselected", nil, .modelPicker, .low),
            ("effort-picker", nil, .effortPicker, .reliable),
            ("effort-cursor-fallback", nil, .effortPicker, .reliable),
            ("effort-stale-unselected", nil, .effortPicker, .low),
            ("approval-prompt", nil, .approvalPrompt, .reliable),
            ("approval-cancel-selected", nil, .approvalPrompt, .reliable),
            ("approval-style-selected", nil, .approvalPrompt, .reliable),
            ("approval-ambiguous", nil, .approvalPrompt, .ambiguous),
            ("approval-reject-selected", nil, .approvalPrompt, .reliable),
            ("approval-missing-selection", nil, .approvalPrompt, .low),
            ("permission-prompt", nil, .permissionPrompt, .reliable),
            ("permission-cancel-selected", nil, .permissionPrompt, .reliable),
            ("permission-allow-this-selected", nil, .permissionPrompt, .reliable),
            ("permission-missing-selection", nil, .permissionPrompt, .low)
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
            if expectedConfidence == .reliable {
                #expect(surface.hasFreshConfirmableSelection)
            } else {
                #expect(!surface.hasFreshConfirmableSelection)
            }
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
    func resumeFixtureCoversFilterSortPagerAndFooterEvidence() throws {
        let snapshot = try loadSurfaceFixtureSnapshot(named: "resume-filter-sort-pager-selected")
        let frame = terminalFrame(id: 250, snapshot: snapshot)
        let surface = try #require(PenggieTerminalBehaviorZoner.classify(frame: frame))

        #expect(surface.kind == .resumePicker)
        #expect(surface.metadata["filter"] == "[Cwd] All")
        #expect(surface.metadata["sort"] == "[Updated] Created")
        #expect(surface.metadata["pager"] == "1 / 16 · 100%")
        #expect(surface.zones.contains(where: { $0.kind == .header }))
        #expect(surface.zones.contains(where: { $0.kind == .footerHelp }))
        #expect(surface.zones.contains(where: { $0.kind == .pagerViewport }))
        #expect(surface.hasFreshConfirmableSelection)
    }

    @Test
    func resumeScrolledFixturePreservesPagerMetadataAndFooterZones() throws {
        let snapshot = try loadSurfaceFixtureSnapshot(named: "resume-scrolled-selected")
        let frame = terminalFrame(id: 251, snapshot: snapshot)
        let surface = try #require(PenggieTerminalBehaviorZoner.classify(frame: frame))

        #expect(surface.kind == .resumePicker)
        #expect(surface.metadata["filter"] == "[Cwd] All")
        #expect(surface.metadata["sort"] == "[Updated] Created")
        #expect(surface.metadata["pager"] == "8 / 16 · 100%")
        #expect(surface.zones.contains(where: { $0.kind == .footerHelp }))
        #expect(surface.zones.contains(where: { $0.kind == .pagerViewport }))
        #expect(surface.hasFreshConfirmableSelection)
    }

    @Test
    func slashModelAndEffortFixturesCoverMarkerStyleCursorAmbiguousAndStaleSelection() throws {
        let markerSlash = try surfaceFixture(named: "slash-suggestions", currentInput: "/")
        #expect(markerSlash.kind == .slashSuggestions)
        #expect(markerSlash.hasFreshConfirmableSelection)

        let styleSlash = try surfaceFixture(named: "slash-style-selected", currentInput: "/")
        #expect(styleSlash.kind == .slashSuggestions)
        #expect(styleSlash.hasFreshConfirmableSelection)

        let ambiguousSlash = try surfaceFixture(named: "slash-ambiguous", currentInput: "/")
        #expect(ambiguousSlash.selectionConfidence == .ambiguous)
        #expect(!ambiguousSlash.hasFreshConfirmableSelection)

        let staleSlash = try surfaceFixture(named: "slash-stale-unselected", currentInput: "/")
        #expect(staleSlash.selectionConfidence == .low)
        #expect(!staleSlash.hasFreshConfirmableSelection)

        let continuation = try surfaceFixture(named: "slash-continuation", currentInput: "/model")
        #expect(continuation.kind == .slashContinuation)
        #expect(continuation.hasFreshConfirmableSelection)

        let modelCursor = try surfaceFixture(named: "model-cursor-fallback")
        #expect(modelCursor.kind == .modelPicker)
        #expect(modelCursor.hasFreshConfirmableSelection)

        let effortCursor = try surfaceFixture(named: "effort-cursor-fallback")
        #expect(effortCursor.kind == .effortPicker)
        #expect(effortCursor.hasFreshConfirmableSelection)

        for fixture in ["model-stale-unselected", "effort-stale-unselected"] {
            let surface = try surfaceFixture(named: fixture)
            #expect(surface.selectionConfidence == .low)
            #expect(!surface.hasFreshConfirmableSelection)
        }
    }

    @Test
    func terminalInteractionFixturesCoverScrolledAmbiguousLowConfidenceAndBlockedConfirmationStates() throws {
        let scrolledResume = try surfaceFixture(named: "resume-scrolled-selected")
        #expect(scrolledResume.kind == .resumePicker)
        #expect(scrolledResume.hasFreshConfirmableSelection)
        #expect(scrolledResume.candidates.count >= 7)
        guard case let .single(selectedID, _, _) = scrolledResume.selection else {
            Issue.record("Expected scrolled resume fixture to carry one selected row")
            return
        }
        let viewport = PenggieTerminalInteractionCandidateViewport.derive(
            candidates: scrolledResume.candidates,
            selectedRowID: selectedID,
            maxVisibleCount: 5
        )
        #expect(viewport.candidates.contains { $0.id == selectedID })
        #expect(viewport.hasLeadingOverflow)

        let ambiguousSlash = try surfaceFixture(named: "slash-ambiguous", currentInput: "/")
        #expect(ambiguousSlash.kind == .slashSuggestions)
        #expect(ambiguousSlash.selectionConfidence == .ambiguous)
        #expect(!ambiguousSlash.hasFreshConfirmableSelection)
        guard case .blocked = PenggieTerminalInputPolicy.commandDecision(.enter, surface: ambiguousSlash) else {
            Issue.record("Expected ambiguous slash fixture to block Enter")
            return
        }

        let missingApproval = try surfaceFixture(named: "approval-missing-selection")
        #expect(missingApproval.kind == .approvalPrompt)
        #expect(missingApproval.selectionConfidence == .low)
        #expect(!missingApproval.hasFreshConfirmableSelection)
        guard case .blocked = PenggieTerminalInputPolicy.commandDecision(.enter, surface: missingApproval) else {
            Issue.record("Expected missing approval selection to block Enter")
            return
        }

        let missingPermission = try surfaceFixture(named: "permission-missing-selection")
        #expect(missingPermission.kind == .permissionPrompt)
        #expect(missingPermission.selectionConfidence == .low)
        #expect(!missingPermission.hasFreshConfirmableSelection)
        guard case .blocked = PenggieTerminalInputPolicy.commandDecision(.enter, surface: missingPermission) else {
            Issue.record("Expected missing permission selection to block Enter")
            return
        }
    }

    @Test
    func modalChoiceFixturesPreserveTerminalEvidenceAndRawParity() throws {
        let styleApproval = try surfaceFixture(named: "approval-style-selected")
        #expect(styleApproval.kind == .approvalPrompt)
        #expect(styleApproval.candidates.map(\.text) == ["Allow once", "Deny"])
        #expect(styleApproval.hasFreshConfirmableSelection)
        #expect(styleApproval.zones.contains { $0.kind == .modalChoice })
        #expect(styleApproval.zones.contains { $0.kind == .keyboardSelectableList })
        #expect(styleApproval.evidence.contains("frame=300"))
        guard case let .single(styleRowID, styleSource, styleEvidence) = styleApproval.selection else {
            Issue.record("Expected style-backed approval fixture to carry one selected row")
            return
        }
        #expect(styleSource == .explicitSelectedCells)
        #expect(styleRowID == styleApproval.candidates[0].id)
        #expect(styleEvidence.contains { $0.contains("line=1") })
        #expect(styleApproval.candidates[0].sourceLineIndex == 1)
        #expect(styleApproval.candidates[1].sourceLineIndex == 2)

        let allowThisPermission = try surfaceFixture(named: "permission-allow-this-selected")
        #expect(allowThisPermission.kind == .permissionPrompt)
        #expect(allowThisPermission.candidates.map(\.text) == ["Allow once", "Deny"])
        #expect(allowThisPermission.hasFreshConfirmableSelection)
        guard case let .single(permissionRowID, permissionSource, permissionEvidence) = allowThisPermission.selection else {
            Issue.record("Expected allow-this permission fixture to carry one selected row")
            return
        }
        #expect(permissionSource == .screenModelMarker)
        #expect(permissionRowID == allowThisPermission.candidates[0].id)
        #expect(permissionEvidence.contains { $0.contains("line=1") })

        let rejectApproval = try surfaceFixture(named: "approval-reject-selected")
        #expect(rejectApproval.kind == .approvalPrompt)
        #expect(rejectApproval.candidates.map(\.text) == ["Approve", "Reject"])
        guard case let .single(rejectRowID, rejectSource, rejectEvidence) = rejectApproval.selection else {
            Issue.record("Expected reject approval fixture to carry one selected row")
            return
        }
        #expect(rejectSource == .screenModelMarker)
        #expect(rejectRowID == rejectApproval.candidates[1].id)
        #expect(rejectEvidence.contains { $0.contains("line=2") })
        #expect(PenggieTerminalInputPolicy.commandDecision(.enter, surface: rejectApproval) == .unhandled)
    }

    @Test
    func modalChoiceConfirmationGateBlocksUnsafeEnterAndRoutesCancelToPTY() throws {
        let ambiguousApproval = try surfaceFixture(named: "approval-ambiguous")
        #expect(ambiguousApproval.kind == .approvalPrompt)
        #expect(ambiguousApproval.selectionConfidence == .ambiguous)
        #expect(!ambiguousApproval.hasFreshConfirmableSelection)
        guard case .blocked = PenggieTerminalInputPolicy.commandDecision(.enter, surface: ambiguousApproval) else {
            Issue.record("Expected ambiguous approval fixture to block Enter")
            return
        }
        #expect(PenggieTerminalInputPolicy.commandDecision(.escape, surface: ambiguousApproval) == .unhandled)
        #expect(PenggieTerminalInputPolicy.commandDecision(.arrowDown, surface: ambiguousApproval) == .unhandled)

        let approval = try surfaceFixture(named: "approval-prompt")
        #expect(PenggieTerminalInputPolicy.commandDecision(.enter, surface: approval) == .unhandled)
        for freshness in [PenggieTerminalSurfaceFreshness.stale, .waitingForTerminalFrame] {
            let unsafeSurface = approval.withFreshness(freshness)
            #expect(unsafeSurface.candidates == approval.candidates)
            #expect(unsafeSurface.selection == approval.selection)
            guard case .blocked = PenggieTerminalInputPolicy.commandDecision(.enter, surface: unsafeSurface) else {
                Issue.record("Expected \(freshness.rawValue) approval fixture to block Enter")
                return
            }
            #expect(PenggieTerminalInputPolicy.commandDecision(.escape, surface: unsafeSurface) == .unhandled)
        }

        let permission = try surfaceFixture(named: "permission-allow-this-selected")
        #expect(PenggieTerminalInputPolicy.commandDecision(.enter, surface: permission) == .unhandled)
        let waitingPermission = permission.withFreshness(.waitingForTerminalFrame)
        guard case .blocked = PenggieTerminalInputPolicy.commandDecision(.enter, surface: waitingPermission) else {
            Issue.record("Expected waiting-for-frame permission fixture to block Enter")
            return
        }
        #expect(PenggieTerminalInputPolicy.commandDecision(.escape, surface: waitingPermission) == .unhandled)

        for cancelFixture in ["approval-cancel-selected", "permission-cancel-selected"] {
            let surface = try surfaceFixture(named: cancelFixture)
            #expect(surface.hasFreshConfirmableSelection)
            #expect(PenggieTerminalInputPolicy.commandDecision(.enter, surface: surface) == .unhandled)
            #expect(PenggieTerminalInputPolicy.commandDecision(.escape, surface: surface) == .unhandled)
        }
    }

    @Test
    func staleSelectedRowsAreNotConfirmableEvenWhenRowIDStillExists() {
        let surface = PenggieTerminalInteractionSurface(
            id: "fixture.stale",
            kind: .resumePicker,
            frameID: 700,
            zones: [
                PenggieTerminalScreenZone(kind: .keyboardSelectableList, lineRange: 1...2)
            ],
            candidates: [
                PenggieTerminalInteractionCandidate(
                    id: "resume:1:first",
                    sourceLineIndex: 1,
                    text: "1h ago    First session",
                    isConfirmable: true
                )
            ],
            selection: .single(
                rowID: "resume:1:first",
                source: .visibleMarker,
                evidence: ["previous-frame-marker"]
            ),
            selectionConfidence: .reliable,
            freshness: .stale,
            evidence: ["frame=700", "stale"]
        )

        #expect(!surface.hasFreshConfirmableSelection)
        let decision = PenggieTerminalInputPolicy.commandDecision(.enter, surface: surface)
        guard case .blocked = decision else {
            Issue.record("Expected stale selected row to block confirmation")
            return
        }
        #expect(decision.consumesEvent)
    }

    @Test
    func waitingForTerminalFrameBlocksEnterWhileKeepingRowsVisible() {
        let freshSurface = PenggieTerminalInteractionSurface(
            id: "fixture.waiting",
            kind: .resumePicker,
            frameID: 701,
            zones: [
                PenggieTerminalScreenZone(kind: .keyboardSelectableList, lineRange: 1...2)
            ],
            candidates: [
                PenggieTerminalInteractionCandidate(
                    id: "resume:1:first",
                    sourceLineIndex: 1,
                    text: "1h ago    First session",
                    isConfirmable: true
                )
            ],
            selection: .single(
                rowID: "resume:1:first",
                source: .visibleMarker,
                evidence: ["current-frame-marker"]
            ),
            selectionConfidence: .reliable,
            freshness: .fresh,
            evidence: ["frame=701"]
        )

        #expect(freshSurface.hasFreshConfirmableSelection)

        let waitingSurface = freshSurface.withFreshness(.waitingForTerminalFrame)
        #expect(waitingSurface.candidates.map(\.id) == freshSurface.candidates.map(\.id))
        #expect(waitingSurface.selection == freshSurface.selection)
        #expect(!waitingSurface.hasFreshConfirmableSelection)

        let decision = PenggieTerminalInputPolicy.commandDecision(.enter, surface: waitingSurface)
        guard case .blocked = decision else {
            Issue.record("Expected waiting-for-frame selected row to block confirmation")
            return
        }
        #expect(decision.consumesEvent)
    }

    @Test
    func freshnessGateWaitsForChangedTerminalContentBeforeAcceptingFreshSurface() {
        let baselineFrame = PenggieTerminalFrame(
            id: 710,
            observedAt: Date(timeIntervalSince1970: 1_800_000_710),
            visibleText: """
            Resume a previous session
            › 1h ago    First session
              2h ago    Second session
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )
        let baselineSurface = try! #require(PenggieTerminalBehaviorZoner.classify(frame: baselineFrame))
        let baseline = PenggieTerminalFrameContentSignature(frame: baselineFrame)

        let unchangedFrame = PenggieTerminalFrame(
            id: 711,
            observedAt: Date(timeIntervalSince1970: 1_800_000_711),
            visibleText: baselineFrame.visibleText,
            screenText: baselineFrame.screenText,
            screenModelJSON: baselineFrame.screenModelJSON,
            processExited: false
        )
        let unchangedSurface = PenggieTerminalBehaviorZoner.classify(frame: unchangedFrame)
        let unchanged = PenggieTerminalSurfaceFreshnessGate.resolve(
            pendingBaseline: baseline,
            previousSurface: baselineSurface.withFreshness(.waitingForTerminalFrame),
            currentSurface: unchangedSurface,
            currentSignature: PenggieTerminalFrameContentSignature(frame: unchangedFrame)
        )

        #expect(unchanged.pendingBaseline == baseline)
        #expect(unchanged.surface?.freshness == .waitingForTerminalFrame)
        #expect(unchanged.surface?.selection == baselineSurface.selection)

        let changedFrame = PenggieTerminalFrame(
            id: 712,
            observedAt: Date(timeIntervalSince1970: 1_800_000_712),
            visibleText: """
            Resume a previous session
              1h ago    First session
            › 2h ago    Second session
            """,
            screenText: "",
            screenModelJSON: nil,
            processExited: false
        )
        let changedSurface = try! #require(PenggieTerminalBehaviorZoner.classify(frame: changedFrame))
        let changed = PenggieTerminalSurfaceFreshnessGate.resolve(
            pendingBaseline: unchanged.pendingBaseline,
            previousSurface: unchanged.surface,
            currentSurface: changedSurface,
            currentSignature: PenggieTerminalFrameContentSignature(frame: changedFrame)
        )

        #expect(changed.pendingBaseline == nil)
        #expect(changed.surface?.freshness == .fresh)
        #expect(changed.surface?.selection == changedSurface.selection)
        #expect(changed.surface?.selection != baselineSurface.selection)
    }

    @Test
    func nonConfirmingNavigationStaysPTYRoutedAndDoesNotMutateSelectionPolicy() throws {
        let surface = try surfaceFixture(named: "resume-low-confidence")
        #expect(surface.selectionConfidence == .low)
        #expect(!surface.hasFreshConfirmableSelection)

        let navigationCommands: [PenggieInteractionCommand] = [
            .arrowUp,
            .arrowDown,
            .arrowLeft,
            .arrowRight,
            .tab,
            .backspace,
            .delete,
            .escape
        ]

        for command in navigationCommands {
            #expect(PenggieTerminalInputPolicy.commandDecision(command, surface: surface) == .unhandled)
        }

        guard case let .none(evidence) = surface.selection else {
            Issue.record("Expected low-confidence navigation fixture to preserve no terminal-owned selection")
            return
        }
        #expect(evidence.contains { $0.contains("selected=0") })
        #expect(!surface.hasFreshConfirmableSelection)
    }

    @Test
    func lowConfidenceSurfaceKeepsRowsVisibleBlocksEnterAndExplainsRefresh() throws {
        let surface = try surfaceFixture(named: "resume-low-confidence")

        #expect(!surface.candidates.isEmpty)
        #expect(surface.candidates.contains { $0.isConfirmable })
        #expect(surface.selectionConfidence == .low)
        #expect(surface.selection.confirmableRowID == nil)
        #expect(!surface.hasFreshConfirmableSelection)

        let decision = PenggieTerminalInputPolicy.commandDecision(.enter, surface: surface)
        guard case let .blocked(reason) = decision else {
            Issue.record("Expected low-confidence surface to block unsafe Enter confirmation")
            return
        }

        #expect(decision.consumesEvent)
        #expect(reason.contains("confirmation requires one fresh terminal-owned selected row"))
        #expect(PenggieTerminalSurfaceStatusCopy.syncingSelection.contains("Syncing selection"))
        #expect(PenggieTerminalSurfaceStatusCopy.syncingSelection.contains("↑/↓"))
        #expect(PenggieTerminalSurfaceStatusCopy.syncingSelection.contains("selected row"))
    }

    @Test
    func candidateAccessibilityValuesDescribeSelectionConfirmabilityAndSyncing() throws {
        let selectedValue = PenggieTerminalSurfaceCandidateAccessibility.value(
            isSelected: true,
            isConfirmable: true,
            surfaceIsSyncing: false
        )
        let syncingUnavailableValue = PenggieTerminalSurfaceCandidateAccessibility.value(
            isSelected: false,
            isConfirmable: false,
            surfaceIsSyncing: true
        )

        #expect(selectedValue == "Selected, Confirmable")
        #expect(syncingUnavailableValue == "Not selected, Unavailable, Selection syncing")
        #expect(PenggieTerminalSurfaceCandidateAccessibility.hint(
            isSelected: true,
            isConfirmable: true,
            surfaceIsSyncing: false
        ).contains("Press Enter"))
        #expect(PenggieTerminalSurfaceCandidateAccessibility.hint(
            isSelected: false,
            isConfirmable: true,
            surfaceIsSyncing: true
        ).contains("syncing with the terminal"))
        #expect(PenggieTerminalSurfaceCandidateAccessibility.hint(
            isSelected: false,
            isConfirmable: false,
            surfaceIsSyncing: false
        ).contains("not currently available"))

        let lowConfidenceSurface = try surfaceFixture(named: "resume-low-confidence")
        let candidate = try #require(lowConfidenceSurface.candidates.first)
        let value = PenggieTerminalSurfaceCandidateAccessibility.value(
            isSelected: lowConfidenceSurface.selection.confirmableRowID == candidate.id,
            isConfirmable: candidate.isConfirmable,
            surfaceIsSyncing: !lowConfidenceSurface.hasFreshConfirmableSelection
        )

        #expect(value.contains("Selection syncing"))
    }

    @Test
    func unsafeEnterConsumesEventInsteadOfFallingThroughToComposerSubmission() throws {
        let ambiguousSlash = try surfaceFixture(named: "slash-ambiguous", currentInput: "/")
        let decision = PenggieTerminalInputPolicy.commandDecision(.enter, surface: ambiguousSlash)

        guard case .blocked(let reason) = decision else {
            Issue.record("Expected ambiguous terminal-owned selection to block Enter")
            return
        }

        #expect(reason.contains("confirmation requires one fresh terminal-owned selected row"))
        #expect(decision.consumesEvent)
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

private func surfaceFixture(
    named name: String,
    currentInput: String? = nil
) throws -> PenggieTerminalInteractionSurface {
    let snapshot = try loadSurfaceFixtureSnapshot(named: name)
    let frame = terminalFrame(id: 300, snapshot: snapshot)
    return try #require(PenggieTerminalBehaviorZoner.classify(
        frame: frame,
        currentInput: currentInput
    ))
}

private func surfaceFixtureURL(named name: String, pathExtension: String) -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures")
        .appendingPathComponent("terminal-interaction-surfaces")
        .appendingPathComponent("\(name).\(pathExtension)")
}
