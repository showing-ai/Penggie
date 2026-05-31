import Testing
@testable import PenggieCore

@Suite
struct PenggieDisplayRuleEngineTests {
    @Test
    func genericAdapterPreservesBoxDrawingTablesAsCellAwareFallback() {
        let snapshot = snapshot([
            "┌──────┬────────────┬────────────┐",
            "│ 维度 │ 伦敦       │ 巴黎       │",
            "├──────┼────────────┼────────────┤",
            "│ 天气 │ 晴到多云   │ 阴天       │",
            "└──────┴────────────┴────────────┘"
        ])

        let document = GenericAnsiAdapter().compile(snapshot: snapshot)
        let blocks = document.turns.flatMap(\.blocks)

        #expect(blocks.count == 1)
        #expect(blocks[0].kind == .preformatted)
        #expect(blocks[0].renderHints.cellAware)
        #expect(blocks[0].renderHints.monospace)
        #expect(blocks[0].renderHints.horizontalScroll)
        #expect(blocks[0].renderHints.preserveWhitespace)
        #expect(blocks[0].confidence.level == .fallback)
        #expect(blocks[0].ruleHits.contains { $0.ruleID == "generic.preformatted.table_shape" })
        #expect(blocks[0].spans.map(\.text).joined().contains("│ 天气 │ 晴到多云   │ 阴天       │"))
    }

    @Test
    func genericAdapterDoesNotKnowCodexSpecificWorkedForStatus() throws {
        let document = GenericAnsiAdapter().compile(snapshot: snapshot(["Worked for 24s ›"]))
        let block = try #require(document.turns.first?.blocks.first)

        #expect(block.kind != .status)
        #expect(!block.ruleHits.contains { $0.ruleID.hasPrefix("codex.") })
        #expect(block.spans.map(\.text).joined() == "Worked for 24s ›")
    }

    @Test
    func codexAdapterClassifiesWorkedForAndWebSearchRows() throws {
        let document = CodexAdapter().compile(
            snapshot: snapshot([
                "Worked for 24s ›",
                "Working... 2s ›",
                "Working (2s • esc to interrupt)",
                "Searching the web",
                "Searched weather: London, UK"
            ])
        )
        let blocks = document.turns.flatMap(\.blocks)

        #expect(blocks.map(\.kind) == [.status, .status, .status, .activity, .toolEvent])
        #expect(blocks.allSatisfy { $0.sourceRange != nil })
        #expect(blocks.allSatisfy { !$0.ruleHits.isEmpty })
        #expect(blocks[0].ruleHits.contains { $0.ruleID == "codex.status.worked_for" })
        #expect(blocks[1].ruleHits.contains { $0.ruleID == "codex.status.working" })
        #expect(blocks[2].ruleHits.contains { $0.ruleID == "codex.status.working" })
        #expect(blocks[3].ruleHits.contains { $0.ruleID == "codex.activity.searching_web" })
        #expect(blocks[4].ruleHits.contains { $0.ruleID == "codex.tool.searched" })
    }

    @Test
    func codexAdapterDoesNotClassifyAnswerPhrasesAsStatusChrome() {
        let document = CodexAdapter().compile(
            snapshot: snapshot([
                "Worked for years on compiler systems before this answer.",
                "Working memory is different from a Codex status row."
            ])
        )
        let blocks = document.turns.flatMap(\.blocks)

        #expect(blocks.map(\.kind) == [.rawFallback, .rawFallback])
        #expect(blocks.allSatisfy { block in
            !block.ruleHits.contains { hit in
                hit.ruleID.hasPrefix("codex.status.")
            }
        })
        #expect(blocks.map { $0.spans.map(\.text).joined() }.joined(separator: "\n").contains("Worked for years"))
        #expect(blocks.map { $0.spans.map(\.text).joined() }.joined(separator: "\n").contains("Working memory"))
    }

    @Test
    func terminalThemeStylesDoNotChangeCodexAdapterSemantics() {
        let plain = CodexAdapter().compile(
            snapshot: snapshot([
                "Worked for 24s ›",
                "今天继续保留为正文。"
            ])
        )
        let themed = CodexAdapter().compile(
            snapshot: snapshot(
                [
                    "Worked for 24s ›",
                    "今天继续保留为正文。"
                ],
                style: TerminalCellStyle(
                    foreground: "#aabbcc",
                    background: "#112233",
                    bold: true,
                    faint: true,
                    italic: true,
                    underline: true
                )
            )
        )

        #expect(semanticFingerprint(plain) == semanticFingerprint(themed))
    }

    @Test
    func codexAdapterDoesNotTurnHistoricalSlashTextIntoOverlay() {
        let document = CodexAdapter().compile(
            snapshot: snapshot([
                "/model      choose what model and reasoning effort to use",
                "/fast       1.5x speed, increased usage",
                "/permissions choose what Codex is allowed to do"
            ])
        )
        let blocks = document.turns.flatMap(\.blocks)

        #expect(!blocks.contains { $0.kind == .overlay })
        #expect(blocks.map { $0.spans.map(\.text).joined() }.joined(separator: "\n").contains("/model"))
        #expect(blocks.map { $0.spans.map(\.text).joined() }.joined(separator: "\n").contains("/permissions"))
    }

    @Test
    func unknownRowsFallbackPreservesVisibleContent() {
        let document = GenericAnsiAdapter().compile(
            snapshot: snapshot([
                "╳ unusual terminal row",
                "   with spacing and symbols  123"
            ])
        )
        let text = document.turns.flatMap(\.blocks).flatMap(\.spans).map(\.text).joined(separator: "\n")

        #expect(text.contains("╳ unusual terminal row"))
        #expect(text.contains("   with spacing and symbols  123"))
        #expect(document.turns.flatMap(\.blocks).allSatisfy { $0.fallback != nil })
    }

    private func snapshot(_ rows: [String], style: TerminalCellStyle = .init()) -> TerminalStyledSnapshot {
        TerminalStyledSnapshot(
            columns: 100,
            rows: 32,
            cursor: nil,
            lines: rows.enumerated().map { rowIndex, text in
                TerminalStyledSnapshot.Line(
                    rowIndex: rowIndex,
                    cells: cells(from: text, style: style),
                    isWrapped: false
                )
            }
        )
    }

    private func cells(from text: String, style: TerminalCellStyle = .init()) -> [TerminalStyledCell] {
        var column = 0
        return text.map { character in
            let width = displayWidth(of: character)
            defer { column += width }
            return TerminalStyledCell(
                column: column,
                text: String(character),
                displayWidth: width,
                style: style
            )
        }
    }

    private func semanticFingerprint(_ document: DisplayDocument) -> [SemanticBlock] {
        document.turns.flatMap(\.blocks).map { block in
            SemanticBlock(
                kind: block.kind,
                text: block.spans.map(\.text).joined(),
                ruleIDs: block.ruleHits.map(\.ruleID),
                preserveWhitespace: block.renderHints.preserveWhitespace,
                monospace: block.renderHints.monospace,
                horizontalScroll: block.renderHints.horizontalScroll,
                cellAware: block.renderHints.cellAware,
                softWrap: block.renderHints.softWrap,
                confidence: block.confidence.level
            )
        }
    }

    private struct SemanticBlock: Equatable {
        var kind: DisplayBlock.Kind
        var text: String
        var ruleIDs: [String]
        var preserveWhitespace: Bool
        var monospace: Bool
        var horizontalScroll: Bool
        var cellAware: Bool
        var softWrap: Bool
        var confidence: DisplayConfidence.Level
    }

    private func displayWidth(of character: Character) -> Int {
        character.unicodeScalars.contains { scalar in
            scalar.value >= 0x1100 || (0x2500...0x257F).contains(Int(scalar.value))
        } ? 2 : 1
    }
}
