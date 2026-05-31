import Testing
@testable import PenggieCore

@Suite
struct PenggieDisplayASTRendererTests {
    @Test
    func rendersCellAwareTableFallbackAsPreformattedReadingSegment() throws {
        let snapshot = snapshot([
            "┌──────┬────────────┬────────────┐",
            "│ 维度 │ 伦敦       │ 巴黎       │",
            "├──────┼────────────┼────────────┤",
            "│ 天气 │ 晴到多云   │ 阴天       │",
            "└──────┴────────────┴────────────┘"
        ])

        let document = GenericAnsiAdapter().compile(snapshot: snapshot)
        let segments = PenggieDisplayASTRenderer().segments(from: document)
        let segment = try #require(segments.first)

        #expect(segments.count == 1)
        #expect(segment.kind == .preformatted)
        #expect(segment.renderHints.cellAware)
        #expect(segment.renderHints.monospace)
        #expect(segment.renderHints.horizontalScroll)
        #expect(segment.renderHints.preserveWhitespace)
        #expect(segment.text.contains("│ 天气 │ 晴到多云   │ 阴天       │"))
    }

    @Test
    func rendersParagraphBlocksAsProseWithoutCellAwareHints() throws {
        let block = DisplayBlock(
            id: "paragraph.0",
            kind: .paragraph,
            role: .assistant,
            spans: [.init(kind: .text, text: "Plain answer text")],
            sourceRange: nil,
            sourceFingerprint: nil,
            confidence: .init(level: .heuristic, score: 0.86),
            ruleHits: [],
            isLive: false,
            isSealed: true,
            renderHints: .init(),
            fallback: nil
        )
        let document = DisplayDocument(
            turns: [
                DisplayTurn(
                    id: "turn.0",
                    role: .assistant,
                    blocks: [block],
                    sourceFingerprint: nil,
                    isLive: false,
                    isSealed: true
                )
            ],
            metadata: .init(source: .terminalProjection, terminalColumns: 80, terminalRows: 24)
        )

        let segment = try #require(PenggieDisplayASTRenderer().segments(from: document).first)

        #expect(segment.kind == .prose)
        #expect(segment.text == "Plain answer text")
        #expect(!segment.renderHints.cellAware)
        #expect(!segment.renderHints.monospace)
    }

    @Test
    func keepsStatusActivityToolAndAnswerSegmentsVisible() {
        let document = CodexAdapter().compile(
            snapshot: snapshot([
                "Working... 2s ›",
                "Searching the web",
                "Searched weather: London, UK",
                "Final answer text"
            ])
        )

        let segments = PenggieDisplayASTRenderer().segments(from: document)

        #expect(segments.map(\.displayBlockKind) == [.status, .activity, .toolEvent, .rawFallback])
        #expect(segments.map(\.text).contains("Working... 2s ›"))
        #expect(segments.map(\.text).contains("Searching the web"))
        #expect(segments.map(\.text).contains("Searched weather: London, UK"))
        #expect(segments.map(\.text).contains("Final answer text"))
        #expect(segments.last?.kind == .prose)
    }

    @Test
    func doesNotRenderOverlayBlocksIntoTranscriptSegments() {
        let document = DisplayDocument(
            turns: [
                DisplayTurn(
                    id: "turn.0",
                    role: .assistant,
                    blocks: [
                        block(id: "paragraph.before", kind: .paragraph, text: "Answer before overlay"),
                        block(id: "overlay.menu", kind: .overlay, text: "/model choose what model to use"),
                        block(id: "paragraph.after", kind: .paragraph, text: "Answer after overlay")
                    ],
                    sourceFingerprint: nil,
                    isLive: false,
                    isSealed: true
                )
            ],
            metadata: .init(source: .terminalProjection, terminalColumns: 80, terminalRows: 24)
        )

        let segments = PenggieDisplayASTRenderer().segments(from: document)

        #expect(segments.map(\.text) == ["Answer before overlay", "Answer after overlay"])
        #expect(!segments.contains { $0.displayBlockKind == .overlay })
    }

    private func snapshot(_ rows: [String]) -> TerminalStyledSnapshot {
        TerminalStyledSnapshot(
            columns: 100,
            rows: 32,
            cursor: nil,
            lines: rows.enumerated().map { rowIndex, text in
                TerminalStyledSnapshot.Line(
                    rowIndex: rowIndex,
                    cells: cells(from: text),
                    isWrapped: false
                )
            }
        )
    }

    private func block(id: String, kind: DisplayBlock.Kind, text: String) -> DisplayBlock {
        DisplayBlock(
            id: id,
            kind: kind,
            role: .assistant,
            spans: [.init(kind: .text, text: text)],
            sourceRange: nil,
            sourceFingerprint: nil,
            confidence: .init(level: .heuristic, score: 0.86),
            ruleHits: [],
            isLive: false,
            isSealed: true,
            renderHints: .init(),
            fallback: nil
        )
    }

    private func cells(from text: String) -> [TerminalStyledCell] {
        var column = 0
        return text.map { character in
            let width = displayWidth(of: character)
            defer { column += width }
            return TerminalStyledCell(
                column: column,
                text: String(character),
                displayWidth: width,
                style: .init()
            )
        }
    }

    private func displayWidth(of character: Character) -> Int {
        character.unicodeScalars.contains { scalar in
            scalar.value >= 0x1100
        } ? 2 : 1
    }
}
