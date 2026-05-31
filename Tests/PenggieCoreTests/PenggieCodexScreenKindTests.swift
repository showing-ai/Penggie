import Foundation
import Testing
@testable import PenggieCore

@Suite
struct PenggieCodexScreenKindTests {
    @Test
    func detectsShellStartupChromeAsTerminalOwnedScreen() {
        let projection = """
        Last login: Sat May 30 02:26:44 on ttys001
        """

        #expect(PenggieCodexScreenKind.detect(in: projection) == .startupShell)
        #expect(PenggieCodexScreenKind.detect(in: projection).isLaunchBlockingScreen)
    }

    @Test
    func keepsShellLoginBlockingEvenWhenPromptEchoAppears() {
        let projection = """
        Last login: Sat May 30 03:31:36 on ttys001
        showing@TestSpace % codex
        """

        #expect(PenggieCodexScreenKind.detect(in: projection) == .startupShell)
        #expect(PenggieCodexScreenKind.detect(in: projection).isTerminalOwnedInteraction)
    }

    @Test
    func currentViewportResumePickerOverridesShellHistory() {
        let currentProjection = """
        Resume a previous session

        Type to search
        """
        let backingProjection = """
        Last login: Sat May 30 03:31:36 on ttys001

        Resume a previous session

        Type to search
        """

        #expect(PenggieCodexScreenKind.detect(
            currentProjection: currentProjection,
            backingProjection: backingProjection
        ) == .resumePicker)
    }

    @Test
    func currentViewportChatOverridesShellHistory() {
        let currentProjection = """
        › 今天伦敦天气怎么样?

        伦敦今天多云。
        """
        let backingProjection = """
        Last login: Sat May 30 03:31:36 on ttys001

        › 今天伦敦天气怎么样?

        伦敦今天多云。
        """

        #expect(PenggieCodexScreenKind.detect(
            currentProjection: currentProjection,
            backingProjection: backingProjection
        ) == .chat)
    }

    @Test
    func shellLoginDoesNotBlockFullScrollbackWithChatTranscript() {
        let projection = """
        Last login: Sat May 30 03:31:36 on ttys001

        › 今天伦敦天气怎么样?

        伦敦今天多云。
        """

        #expect(PenggieCodexScreenKind.detect(in: projection) == .chat)
    }

    @Test
    func detectsResumePickerAsTerminalOwnedScreen() {
        let projection = """
        Resume a previous session

        Type to search

        › 15m ago    对比一下伦敦和巴黎
          16m ago    对比一下伦敦和巴黎

        enter resume  esc exit  ctrl+c exit  tab focus sort/filter  ←/→ change option
        """

        #expect(PenggieCodexScreenKind.detect(in: projection) == .resumePicker)
    }

    @Test
    func detectsPartialResumePickerBeforeFooterArrives() {
        let projection = """
        Resume a previous session

        Type to search
        """

        #expect(PenggieCodexScreenKind.detect(in: projection) == .resumePicker)
    }

    @Test
    func detectsCodexStartupStatusAsLaunchBlockingScreen() {
        let projection = """
        Starting MCP servers (2/3): figma (2s • esc to interrupt) ›
        """

        let screenKind = PenggieCodexScreenKind.detect(in: projection)

        #expect(screenKind == .codexStartupStatus)
        #expect(screenKind.isLaunchBlockingScreen)
        #expect(screenKind.isTerminalOwnedInteraction)
        #expect(PenggieCodexDisplayReadiness.target(
            screenKind: screenKind,
            visibleText: projection,
            backingText: projection,
            resumePickerProjection: .empty,
            hasObservedCodexScreen: true
        ) == nil)
    }

    @Test
    func genericNonEmptyProjectionDoesNotUnlockInitialReadingSurface() {
        let projection = """
        arbitrary terminal output
        """

        #expect(PenggieCodexScreenKind.detect(in: projection) == .chat)
        #expect(PenggieCodexDisplayReadiness.target(
            screenKind: .chat,
            visibleText: projection,
            backingText: projection,
            resumePickerProjection: .empty,
            hasObservedCodexScreen: true
        ) == nil)
    }

    @Test
    func emptyProjectionAfterCodexWasObservedCanUnlockReadingSurface() {
        #expect(PenggieCodexDisplayReadiness.target(
            screenKind: .unknown,
            visibleText: "",
            backingText: "",
            resumePickerProjection: .empty,
            hasObservedCodexScreen: true
        ) == .reading)
    }

    @Test
    func resumePickerDisplayReadinessRequiresRowsButNotSelection() {
        let missingRows = PenggieCodexResumePickerProjection.empty
        let noSelection = PenggieCodexResumePickerProjection(
            rows: [
                .init(sourceLineIndex: 2, age: "1h ago", title: "对比一下伦敦和巴黎", isSelected: false),
                .init(sourceLineIndex: 3, age: "2h ago", title: "伦敦天气怎么样?", isSelected: false)
            ],
            filterText: nil,
            sortText: nil
        )
        let oneSelection = PenggieCodexResumePickerProjection(
            rows: [
                .init(sourceLineIndex: 2, age: "1h ago", title: "对比一下伦敦和巴黎", isSelected: true),
                .init(sourceLineIndex: 3, age: "2h ago", title: "伦敦天气怎么样?", isSelected: false)
            ],
            filterText: nil,
            sortText: nil
        )

        #expect(PenggieCodexDisplayReadiness.target(
            screenKind: .resumePicker,
            visibleText: "",
            backingText: "",
            resumePickerProjection: missingRows,
            hasObservedCodexScreen: true
        ) == nil)
        #expect(PenggieCodexDisplayReadiness.target(
            screenKind: .resumePicker,
            visibleText: "",
            backingText: "",
            resumePickerProjection: noSelection,
            hasObservedCodexScreen: true
        ) == .resumePicker)
        #expect(PenggieCodexDisplayReadiness.target(
            screenKind: .resumePicker,
            visibleText: "",
            backingText: "",
            resumePickerProjection: oneSelection,
            hasObservedCodexScreen: true
        ) == .resumePicker)
    }

    @Test
    func displayReadinessCanUseFrameBoundTerminalFacts() {
        let frame = PenggieTerminalFrame(
            id: 7,
            observedAt: Date(timeIntervalSince1970: 1_800_000_001),
            visibleText: "Resume a previous session\n1h ago    对比一下伦敦和巴黎",
            screenText: "Last login: old shell scrollback",
            screenModelJSON: nil,
            processExited: false
        )
        let projection = PenggieCodexResumePickerProjection(
            rows: [
                .init(sourceLineIndex: 1, age: "1h ago", title: "对比一下伦敦和巴黎", isSelected: false)
            ],
            filterText: nil,
            sortText: nil
        )

        #expect(PenggieCodexDisplayReadiness.target(
            screenKind: .resumePicker,
            frame: frame,
            resumePickerProjection: projection,
            hasObservedCodexScreen: true
        ) == .resumePicker)
    }

    @Test
    func parsesResumePickerRowsFromTerminalProjection() {
        let projection = """
        Resume a previous session

        Type to search

        Filter: [Cwd] All     Sort: [Updated] Created

        › 15m ago    对比一下伦敦和巴黎
          16m ago    对比一下伦敦和巴黎
          18m ago    对比一下伦敦和巴黎

        enter resume  esc exit  ctrl+c exit  tab focus sort/filter  ←/→ change option
        """

        let picker = PenggieCodexResumePickerProjection.parse(from: projection)

        #expect(picker.rows.count == 3)
        #expect(picker.rows[0].isSelected)
        #expect(picker.rows[0].age == "15m ago")
        #expect(picker.rows[0].title == "对比一下伦敦和巴黎")
        #expect(!picker.rows[1].isSelected)
        #expect(picker.rows[1].age == "16m ago")
        #expect(picker.rows[1].title == "对比一下伦敦和巴黎")
        #expect(picker.filterText == "[Cwd] All")
        #expect(picker.sortText == "[Updated] Created")
    }

    @Test
    func parsesHeavyChevronResumePickerMarkerFromTerminalProjection() {
        let projection = """
        Resume a previous session
        Type to search
        ❯ 6h ago    对比一下伦敦和巴黎
          1d ago    伦敦今天的天气怎么样?
        enter resume  esc exit
        """

        let picker = PenggieCodexResumePickerProjection.parse(from: projection)

        #expect(picker.rows.count == 2)
        #expect(picker.rows[0].isSelected)
        #expect(!picker.rows[1].isSelected)
        #expect(picker.selectionState.isSingle)
    }

    @Test
    func textResumePickerProjectionDoesNotInventSelectionWhenMarkersConflict() {
        let projection = """
        Resume a previous session
        Type to search
        › 1h ago    对比一下伦敦和巴黎
          1h ago    对比一下伦敦和巴黎
        › 9h ago    伦敦今天天气怎么样?
        › 1d ago    今天伦敦天气怎么样?
        enter resume  esc exit
        """

        let picker = PenggieCodexResumePickerProjection.parse(from: projection)

        #expect(picker.rows.count == 4)
        #expect(picker.rows.allSatisfy { !$0.isSelected })
        #expect(!picker.selectionState.isSingle)
        if case .none = picker.selectionState {} else {
            Issue.record("Expected conflicting text markers to produce no reliable selection")
        }
    }

    @Test
    func resumePickerSelectionStateReportsSingleSelectedRow() {
        let picker = PenggieCodexResumePickerProjection(
            rows: [
                .init(sourceLineIndex: 2, age: "1h ago", title: "对比一下伦敦和巴黎", isSelected: true),
                .init(sourceLineIndex: 3, age: "9h ago", title: "伦敦今天天气怎么样?", isSelected: false)
            ],
            filterText: nil,
            sortText: nil
        )

        guard case let .single(rowID, _, evidence) = picker.selectionState else {
            Issue.record("Expected exactly one terminal-owned selected row")
            return
        }

        #expect(rowID == picker.rows[0].id)
        #expect(!evidence.isEmpty)
        #expect(picker.hasExactlyOneSelectedRow)
    }

    @Test
    func resumePickerSelectionStateReportsAmbiguousSelectedRows() {
        let picker = PenggieCodexResumePickerProjection(
            rows: [
                .init(sourceLineIndex: 2, age: "1h ago", title: "对比一下伦敦和巴黎", isSelected: true),
                .init(sourceLineIndex: 3, age: "9h ago", title: "伦敦今天天气怎么样?", isSelected: true)
            ],
            filterText: nil,
            sortText: nil
        )

        guard case let .ambiguous(evidence) = picker.selectionState else {
            Issue.record("Expected multiple selected rows to be ambiguous")
            return
        }

        #expect(evidence.count == 2)
        #expect(!picker.hasExactlyOneSelectedRow)
    }

    @Test
    func resumePickerInputPolicyBlocksAmbiguousEnterWithoutFallthrough() {
        let picker = PenggieCodexResumePickerProjection(
            rows: [
                .init(sourceLineIndex: 2, age: "1h ago", title: "对比一下伦敦和巴黎", isSelected: false),
                .init(sourceLineIndex: 3, age: "9h ago", title: "伦敦今天天气怎么样?", isSelected: false)
            ],
            filterText: nil,
            sortText: nil
        )

        let decision = PenggieTerminalInputPolicy.resumePickerCommandDecision(
            .enter,
            projection: picker
        )

        #expect(decision.consumesEvent)
        if case .blocked = decision {} else {
            Issue.record("Expected Enter to be blocked when resume selection is not reliable")
        }
    }

    @Test
    func resumePickerInputPolicyAllowsReliableEnterToRouteToPTY() {
        let picker = PenggieCodexResumePickerProjection(
            rows: [
                .init(sourceLineIndex: 2, age: "1h ago", title: "对比一下伦敦和巴黎", isSelected: true),
                .init(sourceLineIndex: 3, age: "9h ago", title: "伦敦今天天气怎么样?", isSelected: false)
            ],
            filterText: nil,
            sortText: nil
        )

        #expect(PenggieTerminalInputPolicy.resumePickerCommandDecision(
            .enter,
            projection: picker
        ) == .unhandled)
        #expect(PenggieTerminalInputPolicy.resumePickerCommandDecision(
            .arrowDown,
            projection: picker
        ) == .unhandled)
    }

    @Test
    func parsesResumePickerSelectionFromScreenModelStyle() {
        let projection = """
        Resume a previous session
        Type to search
        1h ago    对比一下伦敦和巴黎
        1h ago    伦敦今天天气怎么样?
        enter resume  esc exit
        """
        let selectedStyle = PenggieTerminalScreenSnapshot.Line.StyleSummary(
            textCellCount: 22,
            selectedCellCount: 80,
            selectedTextCellCount: 22,
            boldTextCellCount: 0,
            faintTextCellCount: 0,
            inverseTextCellCount: 0,
            backgroundTextCellCount: 22,
            foregroundTextCellCount: 0,
            backgroundCellCount: 80,
            backgroundOnlyCellCount: 58
        )
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: nil,
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "1h ago    对比一下伦敦和巴黎", selected: false, styleSummary: selectedStyle),
                .init(index: 3, text: "1h ago    伦敦今天天气怎么样?", selected: false)
            ]
        )

        let picker = PenggieCodexResumePickerProjection.parse(from: projection, snapshot: snapshot)

        #expect(picker.rows.count == 2)
        #expect(picker.rows[0].isSelected)
        #expect(!picker.rows[1].isSelected)
    }

    @Test
    func doesNotTreatForegroundOnlyResumeStyleAsReliableSelection() {
        let projection = """
        Resume a previous session
        Type to search
        2h ago    对比一下伦敦和巴黎
        2h ago    对比一下伦敦和巴黎
        9h ago    伦敦今天的天气怎么样?
        enter resume  esc exit
        """
        let selectedAgeStyle = PenggieTerminalScreenSnapshot.Line.StyleSummary(
            textCellCount: 22,
            selectedCellCount: 0,
            selectedTextCellCount: 0,
            boldTextCellCount: 0,
            faintTextCellCount: 0,
            inverseTextCellCount: 0,
            backgroundTextCellCount: 22,
            foregroundTextCellCount: 6
        )
        let backgroundStyle = PenggieTerminalScreenSnapshot.Line.StyleSummary(
            textCellCount: 22,
            selectedCellCount: 0,
            selectedTextCellCount: 0,
            boldTextCellCount: 0,
            faintTextCellCount: 0,
            inverseTextCellCount: 0,
            backgroundTextCellCount: 22,
            foregroundTextCellCount: 0
        )
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: nil,
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "2h ago    对比一下伦敦和巴黎", selected: false, styleSummary: backgroundStyle),
                .init(index: 3, text: "2h ago    对比一下伦敦和巴黎", selected: false, styleSummary: selectedAgeStyle),
                .init(index: 4, text: "9h ago    伦敦今天的天气怎么样?", selected: false, styleSummary: backgroundStyle)
            ]
        )

        let picker = PenggieCodexResumePickerProjection.parse(from: projection, snapshot: snapshot)

        #expect(picker.rows.count == 3)
        #expect(!picker.rows[0].isSelected)
        #expect(!picker.rows[1].isSelected)
        #expect(!picker.rows[2].isSelected)
    }

    @Test
    func screenModelMarkerBeatsWeakForegroundStyleWhenVisibleTextDropsMarker() {
        let visibleProjection = """
        Resume a previous session
        Type to search
        3h ago    对比一下伦敦和巴黎
        3h ago    对比一下伦敦和巴黎
        12h ago   伦敦今天天气怎么样?
        enter resume  esc exit
        """
        let weakForegroundStyle = PenggieTerminalScreenSnapshot.Line.StyleSummary(
            textCellCount: 22,
            selectedCellCount: 0,
            selectedTextCellCount: 0,
            boldTextCellCount: 0,
            faintTextCellCount: 0,
            inverseTextCellCount: 0,
            backgroundTextCellCount: 0,
            foregroundTextCellCount: 6
        )
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: nil,
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "3h ago    对比一下伦敦和巴黎", selected: false, styleSummary: weakForegroundStyle),
                .init(index: 3, text: "› 3h ago    对比一下伦敦和巴黎", selected: false),
                .init(index: 4, text: "12h ago   伦敦今天天气怎么样?", selected: false)
            ]
        )

        let picker = PenggieCodexResumePickerProjection.parse(
            from: visibleProjection,
            snapshot: snapshot
        )

        #expect(picker.rows.count == 3)
        #expect(!picker.rows[0].isSelected)
        #expect(picker.rows[1].isSelected)
        #expect(!picker.rows[2].isSelected)
    }

    @Test
    func backingMarkerBeatsWeakSnapshotForegroundStyle() {
        let visibleProjection = """
        Resume a previous session
        Type to search
        1d ago    对比一下伦敦和巴黎
        1d ago    伦敦今天的天气怎么样?
        8d ago    伦敦天气怎么样?
        enter resume  esc exit
        """
        let backingProjection = """
        Resume a previous session
        Type to search
        1d ago    对比一下伦敦和巴黎
        › 1d ago    伦敦今天的天气怎么样?
        8d ago    伦敦天气怎么样?
        enter resume  esc exit
        """
        let weakForegroundStyle = PenggieTerminalScreenSnapshot.Line.StyleSummary(
            textCellCount: 22,
            selectedCellCount: 0,
            selectedTextCellCount: 0,
            boldTextCellCount: 0,
            faintTextCellCount: 0,
            inverseTextCellCount: 0,
            backgroundTextCellCount: 0,
            foregroundTextCellCount: 6
        )
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: nil,
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "1d ago    对比一下伦敦和巴黎", selected: false, styleSummary: weakForegroundStyle),
                .init(index: 3, text: "1d ago    伦敦今天的天气怎么样?", selected: false),
                .init(index: 4, text: "8d ago    伦敦天气怎么样?", selected: false)
            ]
        )

        let picker = PenggieCodexResumePickerProjection.parse(
            from: visibleProjection,
            backingProjection: backingProjection,
            snapshot: snapshot
        )

        #expect(picker.rows.count == 3)
        #expect(!picker.rows[0].isSelected)
        #expect(picker.rows[1].isSelected)
        #expect(!picker.rows[2].isSelected)
    }

    @Test
    func visibleResumeMarkerProjectsRowsFromSameTerminalRegion() {
        let visibleProjection = """
        Resume a previous session
        Type to search
        2h ago    对比一下伦敦和巴黎
        › 2h ago    对比一下伦敦和巴黎
          9h ago    伦敦今天的天气怎么样?
        enter resume  esc exit
        """
        let misleadingStyle = PenggieTerminalScreenSnapshot.Line.StyleSummary(
            textCellCount: 22,
            selectedCellCount: 0,
            selectedTextCellCount: 0,
            boldTextCellCount: 0,
            faintTextCellCount: 0,
            inverseTextCellCount: 0,
            backgroundTextCellCount: 22,
            foregroundTextCellCount: 6
        )
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: nil,
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "2h ago    对比一下伦敦和巴黎", selected: false, styleSummary: misleadingStyle),
                .init(index: 3, text: "2h ago    对比一下伦敦和巴黎", selected: false),
                .init(index: 4, text: "9h ago    伦敦今天的天气怎么样?", selected: false)
            ]
        )

        let picker = PenggieCodexResumePickerProjection.parse(
            from: visibleProjection,
            snapshot: snapshot
        )

        #expect(picker.rows.count == 3)
        #expect(!picker.rows[0].isSelected)
        #expect(picker.rows[1].isSelected)
        #expect(!picker.rows[2].isSelected)
    }

    @Test
    func visibleResumeRowsArePreferredWhenSnapshotCannotRecoverSelection() {
        let visibleProjection = """
        Resume a previous session
        Type to search
        › 3h ago    对比一下伦敦和巴黎
          3h ago    对比一下伦敦和巴黎
          12h ago   伦敦今天天气怎么样?
        enter resume  esc exit
        """
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: nil,
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "3h ago    对比一下伦敦和巴黎（截断）", selected: false),
                .init(index: 3, text: "3h ago    对比一下伦敦和巴黎（截断）", selected: false),
                .init(index: 4, text: "12h ago   伦敦今天天气怎么样?", selected: false)
            ]
        )

        let picker = PenggieCodexResumePickerProjection.parse(
            from: visibleProjection,
            snapshot: snapshot
        )

        #expect(picker.rows.count == 3)
        #expect(picker.rows[0].isSelected)
        #expect(!picker.rows[1].isSelected)
        #expect(!picker.rows[2].isSelected)
        #expect(picker.rows[0].title == "对比一下伦敦和巴黎")
    }

    @Test
    func backingResumeMarkerRestoresSelectionWhenViewportMarkerIsMissing() {
        let visibleProjection = """
        Resume a previous session
        Type to search
        1d ago    对比一下伦敦和巴黎
        1d ago    伦敦今天的天气怎么样?
        8d ago    伦敦天气怎么样?
        enter resume  esc exit
        """
        let backingProjection = """
        Resume a previous session
        Type to search
        1d ago    对比一下伦敦和巴黎
        › 1d ago    伦敦今天的天气怎么样?
        8d ago    伦敦天气怎么样?
        enter resume  esc exit
        """
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: nil,
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "1d ago    对比一下伦敦和巴黎", selected: false),
                .init(index: 3, text: "1d ago    伦敦今天的天气怎么样?", selected: false),
                .init(index: 4, text: "8d ago    伦敦天气怎么样?", selected: false)
            ]
        )

        let picker = PenggieCodexResumePickerProjection.parse(
            from: visibleProjection,
            backingProjection: backingProjection,
            snapshot: snapshot
        )

        #expect(picker.rows.count == 3)
        #expect(!picker.rows[0].isSelected)
        #expect(picker.rows[1].isSelected)
        #expect(!picker.rows[2].isSelected)
    }

    @Test
    func snapshotSelectionBeatsStaleBackingMarker() {
        let visibleProjection = """
        Resume a previous session
        Type to search
        1d ago    对比一下伦敦和巴黎
        1d ago    伦敦今天的天气怎么样?
        8d ago    伦敦天气怎么样?
        enter resume  esc exit
        """
        let staleBackingProjection = """
        Resume a previous session
        Type to search
        › 1d ago    对比一下伦敦和巴黎
        1d ago    伦敦今天的天气怎么样?
        8d ago    伦敦天气怎么样?
        enter resume  esc exit
        """
        let selectedRowStyle = PenggieTerminalScreenSnapshot.Line.StyleSummary(
            textCellCount: 22,
            selectedCellCount: 0,
            selectedTextCellCount: 0,
            boldTextCellCount: 0,
            faintTextCellCount: 0,
            inverseTextCellCount: 0,
            backgroundTextCellCount: 22,
            foregroundTextCellCount: 0,
            backgroundCellCount: 80,
            backgroundOnlyCellCount: 58
        )
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: nil,
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "1d ago    对比一下伦敦和巴黎", selected: false),
                .init(index: 3, text: "1d ago    伦敦今天的天气怎么样?", selected: false, styleSummary: selectedRowStyle),
                .init(index: 4, text: "8d ago    伦敦天气怎么样?", selected: false)
            ]
        )

        let picker = PenggieCodexResumePickerProjection.parse(
            from: visibleProjection,
            backingProjection: staleBackingProjection,
            snapshot: snapshot
        )

        #expect(picker.rows.count == 3)
        #expect(!picker.rows[0].isSelected)
        #expect(picker.rows[1].isSelected)
        #expect(!picker.rows[2].isSelected)
    }

    @Test
    func visibleCursorBeatsStaleBackingMarkerWhenStyleIsUnavailable() {
        let visibleProjection = """
        Resume a previous session
        Type to search
        1d ago    对比一下伦敦和巴黎
        1d ago    伦敦今天的天气怎么样?
        8d ago    伦敦天气怎么样?
        enter resume  esc exit
        """
        let staleBackingProjection = """
        Resume a previous session
        Type to search
        › 1d ago    对比一下伦敦和巴黎
        1d ago    伦敦今天的天气怎么样?
        8d ago    伦敦天气怎么样?
        enter resume  esc exit
        """
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: .init(x: 0, y: 3, visible: true),
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "1d ago    对比一下伦敦和巴黎", selected: false),
                .init(index: 3, text: "1d ago    伦敦今天的天气怎么样?", selected: false),
                .init(index: 4, text: "8d ago    伦敦天气怎么样?", selected: false)
            ]
        )

        let picker = PenggieCodexResumePickerProjection.parse(
            from: visibleProjection,
            backingProjection: staleBackingProjection,
            snapshot: snapshot
        )

        #expect(picker.rows.count == 3)
        #expect(!picker.rows[0].isSelected)
        #expect(picker.rows[1].isSelected)
        #expect(!picker.rows[2].isSelected)
    }

    @Test
    func resumePickerUsesUniqueExplicitSnapshotStyleAsSelectionFallback() {
        let projection = """
        Resume a previous session
        Type to search
        1d ago    对比一下伦敦和巴黎
        1d ago    伦敦今天的天气怎么样?
        8d ago    伦敦天气怎么样?
        enter resume  esc exit
        """
        let selectedRowStyle = PenggieTerminalScreenSnapshot.Line.StyleSummary(
            textCellCount: 22,
            selectedCellCount: 22,
            selectedTextCellCount: 0,
            boldTextCellCount: 0,
            faintTextCellCount: 0,
            inverseTextCellCount: 0,
            backgroundTextCellCount: 22,
            foregroundTextCellCount: 0
        )
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: nil,
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "1d ago    对比一下伦敦和巴黎", selected: false),
                .init(index: 3, text: "1d ago    伦敦今天的天气怎么样?", selected: false, styleSummary: selectedRowStyle),
                .init(index: 4, text: "8d ago    伦敦天气怎么样?", selected: false)
            ]
        )

        let picker = PenggieCodexResumePickerProjection.parse(from: projection, snapshot: snapshot)

        #expect(picker.rows.count == 3)
        #expect(!picker.rows[0].isSelected)
        #expect(picker.rows[1].isSelected)
        #expect(!picker.rows[2].isSelected)
    }

    @Test
    func resumePickerUsesWideBackgroundStyleRunAsSelectionFallback() {
        let projection = """
        Resume a previous session
        Type to search
        1d ago    对比一下伦敦和巴黎
        1d ago    伦敦今天的天气怎么样?
        8d ago    伦敦天气怎么样?
        enter resume  esc exit
        """
        let plainStyle = PenggieTerminalScreenSnapshot.Line.StyleSummary(
            textCellCount: 22,
            selectedCellCount: 0,
            selectedTextCellCount: 0,
            boldTextCellCount: 0,
            faintTextCellCount: 0,
            inverseTextCellCount: 0,
            backgroundTextCellCount: 0,
            foregroundTextCellCount: 0
        )
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: nil,
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "1d ago    对比一下伦敦和巴黎", selected: false, styleSummary: plainStyle),
                .init(
                    index: 3,
                    text: "1d ago    伦敦今天的天气怎么样?",
                    selected: false,
                    styleSummary: plainStyle,
                    styleRuns: [
                        .init(
                            startColumn: 0,
                            endColumn: 80,
                            foreground: nil,
                            background: .init(kind: "palette", value: "8"),
                            bold: false,
                            faint: false,
                            inverse: false,
                            textCellCount: 22,
                            backgroundCellCount: 80
                        )
                    ]
                ),
                .init(index: 4, text: "8d ago    伦敦天气怎么样?", selected: false, styleSummary: plainStyle)
            ]
        )

        let picker = PenggieCodexResumePickerProjection.parse(from: projection, snapshot: snapshot)

        #expect(picker.rows.count == 3)
        #expect(!picker.rows[0].isSelected)
        #expect(picker.rows[1].isSelected)
        #expect(!picker.rows[2].isSelected)
    }

    @Test
    func doesNotTreatResumePickerBackgroundRowsAsMultipleSelections() {
        let projection = """
        Resume a previous session
        Type to search
        1h ago    对比一下伦敦和巴黎
        1h ago    对比一下伦敦和巴黎
        9h ago    伦敦今天天气怎么样?
        enter resume  esc exit
        """
        let backgroundStyle = PenggieTerminalScreenSnapshot.Line.StyleSummary(
            textCellCount: 22,
            selectedCellCount: 0,
            selectedTextCellCount: 0,
            boldTextCellCount: 0,
            faintTextCellCount: 0,
            inverseTextCellCount: 0,
            backgroundTextCellCount: 22,
            foregroundTextCellCount: 0
        )
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: .init(x: 0, y: 1, visible: false),
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "1h ago    对比一下伦敦和巴黎", selected: false, styleSummary: backgroundStyle),
                .init(index: 3, text: "1h ago    对比一下伦敦和巴黎", selected: false),
                .init(index: 4, text: "9h ago    伦敦今天天气怎么样?", selected: false, styleSummary: backgroundStyle)
            ]
        )

        let picker = PenggieCodexResumePickerProjection.parse(from: projection, snapshot: snapshot)

        #expect(picker.rows.count == 3)
        #expect(picker.rows.filter(\.isSelected).isEmpty)
    }

    @Test
    func doesNotTreatUniqueTextBackgroundAsResumeSelection() {
        let projection = """
        Resume a previous session
        Type to search
        1h ago    对比一下伦敦和巴黎
        9h ago    伦敦今天天气怎么样?
        enter resume  esc exit
        """
        let textBackgroundStyle = PenggieTerminalScreenSnapshot.Line.StyleSummary(
            textCellCount: 22,
            selectedCellCount: 0,
            selectedTextCellCount: 0,
            boldTextCellCount: 0,
            faintTextCellCount: 0,
            inverseTextCellCount: 0,
            backgroundTextCellCount: 22,
            foregroundTextCellCount: 0,
            backgroundCellCount: 22,
            backgroundOnlyCellCount: 0
        )
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: nil,
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "1h ago    对比一下伦敦和巴黎", selected: false, styleSummary: textBackgroundStyle),
                .init(index: 3, text: "9h ago    伦敦今天天气怎么样?", selected: false)
            ]
        )

        let picker = PenggieCodexResumePickerProjection.parse(from: projection, snapshot: snapshot)

        #expect(picker.rows.count == 2)
        #expect(picker.rows.filter(\.isSelected).isEmpty)
    }

    @Test
    func doesNotTreatTerminalTextSelectionAsResumePickerSelection() {
        let projection = """
        Resume a previous session
        Type to search
        1h ago    对比一下伦敦和巴黎
        9h ago    伦敦今天天气怎么样?
        enter resume  esc exit
        """
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 100,
            rows: 30,
            cursor: nil,
            lines: [
                .init(index: 0, text: "Resume a previous session", selected: false),
                .init(index: 1, text: "Type to search", selected: false),
                .init(index: 2, text: "1h ago    对比一下伦敦和巴黎", selected: true),
                .init(index: 3, text: "9h ago    伦敦今天天气怎么样?", selected: false)
            ]
        )

        let picker = PenggieCodexResumePickerProjection.parse(from: projection, snapshot: snapshot)

        #expect(picker.rows.count == 2)
        #expect(picker.rows.filter(\.isSelected).isEmpty)
    }

    @Test
    func ignoresResumePickerChromeWhenParsingRows() {
        let projection = """
        Resume a previous session
        Type to search
        Filter: [Cwd] All     Sort: [Updated] Created
        ─────────────────────────────────────────────────────────────
        enter resume  esc exit  ctrl+c exit
        """

        let picker = PenggieCodexResumePickerProjection.parse(from: projection)

        #expect(picker.rows.isEmpty)
    }

    @Test
    func doesNotTreatNormalChatTranscriptAsTerminalOwnedScreen() {
        let projection = """
        › 今天伦敦天气怎么样?

        伦敦今天多云，最高气温约 18°C。
        """

        #expect(PenggieCodexScreenKind.detect(in: projection) == .chat)
    }
}
