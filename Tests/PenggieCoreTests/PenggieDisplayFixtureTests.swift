import Foundation
import Testing
@testable import PenggieCore

@Suite
struct PenggieDisplayFixtureTests {
    @Test
    func tableBoxCJKFixtureMatchesDisplayASTSnapshot() throws {
        let actual = try displayASTSnapshot(fixture: "table-box-cjk")
        let expected = try expectedDisplayAST(fixture: "table-box-cjk")

        #expect(actual == expected)
        #expect(actual.blocks.contains { $0.kind == "preformatted" && $0.cellAware && $0.horizontalScroll })
        #expect(actual.blocks.contains { $0.ruleIDs.contains("generic.preformatted.table_shape") })
    }

    @Test
    func tableBoxCJKGhosttyScreenFixtureMatchesDisplayASTSnapshot() throws {
        let actual = try displayASTSnapshotFromGhosttyScreen(fixture: "table-box-cjk")
        let expected = try expectedDisplayAST(fixture: "table-box-cjk")

        #expect(actual == expected)
        #expect(actual.blocks.contains { $0.kind == "preformatted" && $0.cellAware && $0.horizontalScroll })
        #expect(actual.blocks.contains { $0.ruleIDs.contains("generic.preformatted.table_shape") })
    }

    @Test
    func tableBoxCJKFixtureUsesCellAwareReadingFallback() throws {
        let actual = try renderedSegments(fixture: "table-box-cjk")
        let expected = try expectedSegments(fixture: "table-box-cjk")

        #expect(actual == expected)
        #expect(actual.contains { $0.kind == "preformatted" && $0.cellAware && $0.horizontalScroll })
    }

    @Test
    func tableBoxCJKDisplayASTFixtureRendersToReadingSnapshot() throws {
        let actual = try renderedSegmentsFromDisplayAST(fixture: "table-box-cjk")
        let expected = try expectedSegments(fixture: "table-box-cjk")

        #expect(actual == expected)
        #expect(actual.contains { $0.kind == "preformatted" && $0.cellAware && $0.horizontalScroll })
    }

    @Test
    func tableBoxCJKVisualSnapshotPreservesTerminalCellWidths() throws {
        let expected = try expectedDisplayAST(fixture: "table-box-cjk")
        let tableBlock = try #require(expected.blocks.first { $0.kind == "preformatted" })
        let rows = tableBlock.text.components(separatedBy: .newlines)

        #expect(tableBlock.cellAware)
        #expect(tableBlock.horizontalScroll)
        let rowWidths = rows.map(terminalCellWidth)
        #expect(rowWidths.allSatisfy { $0 == rowWidths.first })
        #expect(rows.contains { $0.contains("维度") && $0.contains("伦敦") && $0.contains("巴黎") })
    }

    @Test
    func markdownProseFixturePreservesVisibleMarkers() throws {
        let actual = try displayASTSnapshot(fixture: "markdown-prose")
        let expected = try expectedDisplayAST(fixture: "markdown-prose")
        let visibleText = actual.blocks.map(\.text).joined(separator: "\n")

        #expect(actual == expected)
        #expect(visibleText.contains("`Reading`"))
        #expect(visibleText.contains("**visible markers**"))
        #expect(visibleText.contains("/commands"))
        #expect(actual.blocks.allSatisfy { $0.kind == "rawFallback" })
    }

    @Test
    func markdownProseFixtureRendersAsProseWithoutInventingMarkdownSemantics() throws {
        let actual = try renderedSegmentsFromDisplayAST(fixture: "markdown-prose")
        let expected = try expectedSegments(fixture: "markdown-prose")

        #expect(actual == expected)
        #expect(actual.allSatisfy { $0.kind == "prose" })
        #expect(actual.allSatisfy { !$0.cellAware && !$0.horizontalScroll })
        #expect(actual.map(\.text).joined(separator: "\n").contains("**visible markers**"))
    }

    @Test
    func themeStyleFixtureMatchesRawAndStyledScreens() throws {
        let rawProjection = try displayASTSnapshot(fixture: "theme-style")
        let styledProjection = try displayASTSnapshotFromGhosttyScreen(fixture: "theme-style")
        let expected = try expectedDisplayAST(fixture: "theme-style")

        #expect(rawProjection == expected)
        #expect(styledProjection == expected)
    }

    @Test
    func themeStyleFixtureKeepsStyleOutOfSemantics() throws {
        let actual = try renderedSegmentsFromDisplayAST(fixture: "theme-style")
        let expected = try expectedSegments(fixture: "theme-style")

        #expect(actual == expected)
        #expect(actual.map(\.displayBlockKind) == ["status", nil, "status"])
        #expect(actual.contains { $0.text == "Styled answer text must stay visible." })
    }

    @Test
    func slashNegativeFixtureMatchesDisplayASTSnapshot() throws {
        let actual = try displayASTSnapshot(fixture: "slash-negative")
        let expected = try expectedDisplayAST(fixture: "slash-negative")

        #expect(actual == expected)
        #expect(actual.blocks.allSatisfy { $0.kind == "rawFallback" })
        #expect(actual.blocks.allSatisfy { !$0.cellAware && !$0.horizontalScroll })
    }

    @Test
    func slashNegativeDisplayASTFixtureRendersAsVisibleProse() throws {
        let actual = try renderedSegmentsFromDisplayAST(fixture: "slash-negative")
        let visibleText = actual.map(\.text).joined(separator: "\n")

        #expect(actual.allSatisfy { $0.kind == "prose" })
        #expect(actual.allSatisfy { $0.displayBlockKind == nil })
        #expect(visibleText.contains("/model"))
        #expect(visibleText.contains("/fast"))
        #expect(visibleText.contains("/permissions"))
    }

    @Test
    func historicalInlineAndIndentedSlashTextStayInTranscript() throws {
        let actual = try renderedSegments(fixture: "slash-negative")
        let expected = try expectedSegments(fixture: "slash-negative")

        #expect(actual == expected)
        #expect(actual.allSatisfy { $0.kind == "prose" })
        #expect(!actual.contains { $0.displayBlockKind == "overlay" })
        #expect(actual.map(\.text).joined(separator: "\n").contains("/model"))
        #expect(actual.map(\.text).joined(separator: "\n").contains("/fast"))
        #expect(actual.map(\.text).joined(separator: "\n").contains("/permissions"))
    }

    @Test
    func warningStatusAndToolRowsDoNotHideAnswerText() throws {
        let actual = try displayASTSnapshot(fixture: "warning-status-tools")
        let expected = try expectedDisplayAST(fixture: "warning-status-tools")

        #expect(actual == expected)
        #expect(actual.blocks.contains { $0.kind == "status" && $0.ruleIDs.contains("codex.status.working") })
        #expect(actual.blocks.contains { $0.kind == "warning" && $0.ruleIDs.contains("codex.warning.visible_text") })
        #expect(actual.blocks.contains { $0.kind == "activity" && $0.ruleIDs.contains("codex.activity.searching_web") })
        #expect(actual.blocks.contains { $0.kind == "toolEvent" && $0.ruleIDs.contains("codex.tool.searched") })
        #expect(actual.blocks.contains { $0.text == "最终答案不会被隐藏。" })
    }

    @Test
    func warningStatusAndToolRowsRenderWithoutDroppingVisibleAnswer() throws {
        let actual = try renderedSegmentsFromDisplayAST(fixture: "warning-status-tools")
        let expected = try expectedSegments(fixture: "warning-status-tools")
        let visibleText = actual.map(\.text).joined(separator: "\n")

        #expect(actual == expected)
        #expect(visibleText.contains("Working... 2s"))
        #expect(visibleText.contains("Skill descriptions were shortened"))
        #expect(visibleText.contains("Searched weather: London, UK"))
        #expect(visibleText.contains("今天伦敦天气大致是晴到多云。"))
        #expect(visibleText.contains("最终答案不会被隐藏。"))
    }

    @Test
    func approvalPromptAndChoicesStayVisibleAsFallbackText() throws {
        let actual = try displayASTSnapshot(fixture: "approval-prompt")
        let expected = try expectedDisplayAST(fixture: "approval-prompt")

        #expect(actual == expected)
        #expect(actual.blocks.allSatisfy { $0.kind == "rawFallback" })
        #expect(actual.blocks.map(\.text).joined(separator: "\n").contains("Approve command?"))
        #expect(actual.blocks.map(\.text).joined(separator: "\n").contains("Allow once"))
        #expect(actual.blocks.map(\.text).joined(separator: "\n").contains("Deny"))
    }

    @Test
    func longSessionFixtureKeepsCompletedAnswerAndClassifiesLaterStatusRows() throws {
        let actual = try displayASTSnapshot(fixture: "long-session-stable")
        let expected = try expectedDisplayAST(fixture: "long-session-stable")
        let rendered = PenggieDisplayASTRenderer()
            .segments(from: displayDocument(from: expected))
            .map(FixtureReadingSegment.init(segment:))

        #expect(actual == expected)
        #expect(actual.blocks.first?.kind == "status")
        #expect(actual.blocks.contains { $0.text == "Here is the completed answer." })
        #expect(actual.blocks.contains { $0.kind == "status" && $0.ruleIDs.contains("codex.status.working") })
        #expect(rendered.map(\.text).joined(separator: "\n").contains("Ready for the next request."))
    }

    @Test
    func cjkTableCodeFixturePreservesTerminalSensitiveOutput() throws {
        let actual = try displayASTSnapshot(fixture: "cjk-table-code")
        let expected = try expectedDisplayAST(fixture: "cjk-table-code")
        let visibleText = actual.blocks.map(\.text).joined(separator: "\n")

        #expect(actual == expected)
        #expect(actual.blocks.contains { $0.kind == "preformatted" && $0.cellAware && $0.horizontalScroll })
        #expect(visibleText.contains("下面是一个包含中文、表格和代码的终端输出："))
        #expect(visibleText.contains("const city = \"伦敦\";"))
        #expect(visibleText.contains("│ 天气   │ 多云       │ 小雨       │"))
    }

    @Test
    func toolHeavyWarningFixtureMaintainsFinalAnswerHierarchy() throws {
        let actual = try displayASTSnapshot(fixture: "tool-heavy-warning-hierarchy")
        let expected = try expectedDisplayAST(fixture: "tool-heavy-warning-hierarchy")

        #expect(actual == expected)
        #expect(actual.blocks.map(\.kind).contains("activity"))
        #expect(actual.blocks.map(\.kind).contains("toolEvent"))
        #expect(actual.blocks.map(\.kind).contains("warning"))
        #expect(actual.blocks.contains { $0.text == "最终答案：" })
        #expect(actual.blocks.contains { $0.text == "- Chat UI should preserve visible evidence." })
        #expect(actual.blocks.last?.ruleIDs.contains("codex.status.worked_for") == true)
    }

    @Test
    func lowConfidenceDisplayFixtureUsesFallbackWithoutInventingMarkdown() throws {
        let actual = try displayASTSnapshot(fixture: "low-confidence-fallback")
        let expected = try expectedDisplayAST(fixture: "low-confidence-fallback")
        let rendered = PenggieDisplayASTRenderer()
            .segments(from: displayDocument(from: expected))
            .map(FixtureReadingSegment.init(segment:))
        let visibleText = rendered.map(\.text).joined(separator: "\n")

        #expect(actual == expected)
        #expect(actual.blocks.allSatisfy { $0.confidenceLevel == "fallback" })
        #expect(!actual.blocks.contains { $0.kind == "overlay" || $0.kind == "paragraph" })
        #expect(visibleText.contains("inline /model text and › marker are transcript evidence"))
        #expect(rendered.contains { $0.kind == "preformatted" && $0.cellAware })
    }

    private func renderedSegments(fixture: String) throws -> [FixtureReadingSegment] {
        let rawText = try fixtureText(fixture: fixture, filename: "raw-text.txt")
        let block = PenggieReadingBlock(
            kind: .output,
            text: rawText,
            displayText: rawText,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            variant: .unknown
        )

        return PenggieReadingPresentation.displaySegments(for: block).map(FixtureReadingSegment.init(segment:))
    }

    private func displayASTSnapshot(fixture: String) throws -> FixtureDisplayAST {
        let rawText = try fixtureText(fixture: fixture, filename: "raw-text.txt")
        let snapshot = terminalSnapshot(from: rawText, columns: 120)
        let document = CodexAdapter().compile(snapshot: snapshot)
        return FixtureDisplayAST(document: document)
    }

    private func displayASTSnapshotFromGhosttyScreen(fixture: String) throws -> FixtureDisplayAST {
        let snapshot = try ghosttyScreenSnapshot(fixture: fixture)
        let document = CodexAdapter().compile(snapshot: snapshot)
        return FixtureDisplayAST(document: document)
    }

    private func renderedSegmentsFromDisplayAST(fixture: String) throws -> [FixtureReadingSegment] {
        let fixtureAST = try expectedDisplayAST(fixture: fixture)
        let document = displayDocument(from: fixtureAST)
        return PenggieDisplayASTRenderer()
            .segments(from: document)
            .map(FixtureReadingSegment.init(segment:))
    }

    private func displayDocument(from fixtureAST: FixtureDisplayAST) -> DisplayDocument {
        let blocks = fixtureAST.blocks.enumerated().map { index, fixtureBlock in
            displayBlock(from: fixtureBlock, index: index)
        }

        return DisplayDocument(
            turns: [
                DisplayTurn(
                    id: "fixture.turn.0",
                    role: .assistant,
                    blocks: blocks,
                    sourceFingerprint: nil,
                    isLive: false,
                    isSealed: true
                ),
            ],
            metadata: DisplayDocument.Metadata(
                source: DisplayDocument.Metadata.Source(rawValue: fixtureAST.source) ?? .terminalProjection,
                terminalColumns: fixtureAST.terminalColumns,
                terminalRows: fixtureAST.terminalRows
            )
        )
    }

    private func displayBlock(from fixtureBlock: FixtureDisplayBlock, index: Int) -> DisplayBlock {
        let confidence = displayConfidence(from: fixtureBlock.confidenceLevel)
        let kind = DisplayBlock.Kind(rawValue: fixtureBlock.kind) ?? .rawFallback

        return DisplayBlock(
            id: "fixture.block.\(index)",
            kind: kind,
            role: DisplayRole(rawValue: fixtureBlock.role) ?? .unknown,
            spans: [
                DisplaySpan(kind: .text, text: fixtureBlock.text),
            ],
            sourceRange: nil,
            sourceFingerprint: nil,
            confidence: confidence,
            ruleHits: fixtureBlock.ruleIDs.map {
                DisplayRuleHit(
                    ruleID: $0,
                    mode: displayRuleMode(for: confidence.level),
                    reason: "Fixture snapshot rule"
                )
            },
            isLive: false,
            isSealed: true,
            renderHints: displayRenderHints(for: fixtureBlock, kind: kind),
            fallback: fixtureBlock.fallbackCode.map {
                DisplayFallback(code: $0, message: "Fixture snapshot fallback")
            }
        )
    }

    private func displayConfidence(from level: String) -> DisplayConfidence {
        let confidenceLevel = DisplayConfidence.Level(rawValue: level) ?? .fallback
        let score: Double = switch confidenceLevel {
        case .hard: 1
        case .heuristic: 0.75
        case .fallback: 0.3
        }
        return DisplayConfidence(level: confidenceLevel, score: score)
    }

    private func displayRuleMode(for level: DisplayConfidence.Level) -> DisplayRuleHit.Mode {
        switch level {
        case .hard: .hard
        case .heuristic: .heuristic
        case .fallback: .fallback
        }
    }

    private func displayRenderHints(
        for fixtureBlock: FixtureDisplayBlock,
        kind: DisplayBlock.Kind
    ) -> DisplayRenderHints {
        let isPreformatted = kind == .preformatted || kind == .table || kind == .codeBlock
        return DisplayRenderHints(
            preserveWhitespace: fixtureBlock.cellAware || fixtureBlock.horizontalScroll || isPreformatted,
            monospace: fixtureBlock.cellAware || fixtureBlock.horizontalScroll || isPreformatted,
            horizontalScroll: fixtureBlock.horizontalScroll,
            cellAware: fixtureBlock.cellAware,
            softWrap: !(fixtureBlock.cellAware || fixtureBlock.horizontalScroll)
        )
    }

    private func expectedSegments(fixture: String) throws -> [FixtureReadingSegment] {
        let data = try Data(contentsOf: fixtureURL(fixture: fixture, filename: "reading-snapshot.json"))
        return try JSONDecoder().decode([FixtureReadingSegment].self, from: data)
    }

    private func expectedDisplayAST(fixture: String) throws -> FixtureDisplayAST {
        let data = try Data(contentsOf: fixtureURL(fixture: fixture, filename: "display-ast.json"))
        return try JSONDecoder().decode(FixtureDisplayAST.self, from: data)
    }

    private func ghosttyScreenSnapshot(fixture: String) throws -> TerminalStyledSnapshot {
        let data = try Data(contentsOf: fixtureURL(fixture: fixture, filename: "ghostty-screen.json"))
        return try JSONDecoder().decode(TerminalStyledSnapshot.self, from: data)
    }

    private func fixtureText(fixture: String, filename: String) throws -> String {
        try String(contentsOf: fixtureURL(fixture: fixture, filename: filename), encoding: .utf8)
            .trimmingCharacters(in: .newlines)
    }

    private func fixtureURL(fixture: String, filename: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/agent-terminal-display")
            .appendingPathComponent(fixture)
            .appendingPathComponent(filename)
    }

    private func terminalSnapshot(from text: String, columns: Int) -> TerminalStyledSnapshot {
        let lines = text.components(separatedBy: .newlines).enumerated().map { rowIndex, line in
            var column = 0
            let cells = line.map { character in
                let width = terminalDisplayWidth(for: character)
                defer { column += width }
                return TerminalStyledCell(
                    column: column,
                    text: String(character),
                    displayWidth: width,
                    style: TerminalCellStyle()
                )
            }
            return TerminalStyledSnapshot.Line(rowIndex: rowIndex, cells: cells, isWrapped: false)
        }

        return TerminalStyledSnapshot(
            columns: columns,
            rows: lines.count,
            cursor: nil,
            lines: lines
        )
    }

    private func terminalDisplayWidth(for character: Character) -> Int {
        guard let scalar = character.unicodeScalars.first else {
            return 1
        }
        if scalar.properties.isEmojiPresentation || scalar.properties.isIdeographic {
            return 2
        }
        if (0x1100...0x115F).contains(Int(scalar.value))
            || (0x2E80...0xA4CF).contains(Int(scalar.value))
            || (0xAC00...0xD7A3).contains(Int(scalar.value))
            || (0xF900...0xFAFF).contains(Int(scalar.value))
            || (0xFE10...0xFE19).contains(Int(scalar.value))
            || (0xFE30...0xFE6F).contains(Int(scalar.value))
            || (0xFF00...0xFF60).contains(Int(scalar.value))
            || (0xFFE0...0xFFE6).contains(Int(scalar.value)) {
            return 2
        }
        return 1
    }

    private func terminalCellWidth(_ text: String) -> Int {
        text.reduce(0) { partialResult, character in
            partialResult + terminalDisplayWidth(for: character)
        }
    }
}

private struct FixtureReadingSegment: Codable, Equatable {
    var kind: String
    var text: String
    var cellAware: Bool
    var horizontalScroll: Bool
    var displayBlockKind: String?

    init(
        kind: String,
        text: String,
        cellAware: Bool,
        horizontalScroll: Bool,
        displayBlockKind: String?
    ) {
        self.kind = kind
        self.text = text
        self.cellAware = cellAware
        self.horizontalScroll = horizontalScroll
        self.displayBlockKind = displayBlockKind
    }

    init(segment: PenggieReadingDisplaySegment) {
        self.kind = switch segment.kind {
        case .prose: "prose"
        case .preformatted: "preformatted"
        }
        self.text = segment.text
        self.cellAware = segment.renderHints.cellAware
        self.horizontalScroll = segment.renderHints.horizontalScroll
        self.displayBlockKind = segment.displayBlockKind == .rawFallback ? nil : segment.displayBlockKind?.rawValue
    }
}

private struct FixtureDisplayAST: Codable, Equatable {
    var source: String
    var terminalColumns: Int?
    var terminalRows: Int?
    var blocks: [FixtureDisplayBlock]

    init(source: String, terminalColumns: Int?, terminalRows: Int?, blocks: [FixtureDisplayBlock]) {
        self.source = source
        self.terminalColumns = terminalColumns
        self.terminalRows = terminalRows
        self.blocks = blocks
    }

    init(document: DisplayDocument) {
        self.source = document.metadata.source.rawValue
        self.terminalColumns = document.metadata.terminalColumns
        self.terminalRows = document.metadata.terminalRows
        self.blocks = document.turns.flatMap(\.blocks).map(FixtureDisplayBlock.init(block:))
    }
}

private struct FixtureDisplayBlock: Codable, Equatable {
    var kind: String
    var role: String
    var text: String
    var confidenceLevel: String
    var ruleIDs: [String]
    var cellAware: Bool
    var horizontalScroll: Bool
    var fallbackCode: String?

    init(
        kind: String,
        role: String,
        text: String,
        confidenceLevel: String,
        ruleIDs: [String],
        cellAware: Bool,
        horizontalScroll: Bool,
        fallbackCode: String?
    ) {
        self.kind = kind
        self.role = role
        self.text = text
        self.confidenceLevel = confidenceLevel
        self.ruleIDs = ruleIDs
        self.cellAware = cellAware
        self.horizontalScroll = horizontalScroll
        self.fallbackCode = fallbackCode
    }

    init(block: DisplayBlock) {
        self.kind = block.kind.rawValue
        self.role = block.role.rawValue
        self.text = block.spans.map(\.text).joined()
        self.confidenceLevel = block.confidence.level.rawValue
        self.ruleIDs = block.ruleHits.map(\.ruleID)
        self.cellAware = block.renderHints.cellAware
        self.horizontalScroll = block.renderHints.horizontalScroll
        self.fallbackCode = block.fallback?.code
    }
}
