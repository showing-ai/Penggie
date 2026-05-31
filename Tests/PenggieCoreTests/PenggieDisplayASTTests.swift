import Foundation
import Testing
@testable import PenggieCore

@Suite
struct PenggieDisplayASTTests {
    @Test
    func displayASTSerializesTraceableRawFallbackBlocks() throws {
        let block = DisplayBlock(
            id: "block-1",
            kind: .rawFallback,
            role: .assistant,
            spans: [
                .init(kind: .text, text: "visible terminal text"),
                .init(kind: .lineBreak, text: "\n"),
                .init(kind: .terminalStyled, text: "styled", style: .init(foreground: "#333333", bold: true))
            ],
            sourceRange: .init(startRow: 4, startColumn: 0, endRow: 5, endColumn: 6),
            sourceFingerprint: "terminal-visible-text",
            confidence: .init(level: .fallback, score: 0.1),
            ruleHits: [
                .init(ruleID: "generic.raw-fallback", mode: .fallback, reason: "low-confidence terminal projection")
            ],
            isLive: true,
            isSealed: false,
            renderHints: .init(preserveWhitespace: true, monospace: true, horizontalScroll: true),
            fallback: .init(code: "low-confidence", message: "Preserve visible text.")
        )
        let document = DisplayDocument(
            turns: [
                .init(
                    id: "turn-1",
                    role: .assistant,
                    blocks: [block],
                    sourceFingerprint: "turn-fingerprint",
                    isLive: true,
                    isSealed: false
                )
            ],
            metadata: .init(source: .terminalProjection, terminalColumns: 80, terminalRows: 24)
        )

        let encoded = try JSONEncoder.sortedPrettyPrinted.encode(document)
        let decoded = try JSONDecoder().decode(DisplayDocument.self, from: encoded)

        #expect(decoded == document)
        #expect(decoded.turns[0].blocks[0].kind == .rawFallback)
        #expect(decoded.turns[0].blocks[0].sourceRange?.startRow == 4)
        #expect(decoded.turns[0].blocks[0].ruleHits[0].mode == .fallback)
        #expect(decoded.turns[0].blocks[0].renderHints.monospace)
        #expect(String(data: encoded, encoding: .utf8)?.contains("\"rawFallback\"") == true)
    }

    @Test
    func displayASTCoversRequiredBlockAndSpanKinds() {
        let requiredBlockKinds: Set<DisplayBlock.Kind> = [
            .userPrompt,
            .paragraph,
            .list,
            .listItem,
            .codeBlock,
            .preformatted,
            .table,
            .warning,
            .status,
            .activity,
            .toolEvent,
            .disclosure,
            .overlay,
            .divider,
            .rawFallback
        ]
        let requiredSpanKinds: Set<DisplaySpan.Kind> = [
            .text,
            .lineBreak,
            .softBreak,
            .code,
            .emphasis,
            .strong,
            .link,
            .path,
            .command,
            .statusToken,
            .terminalStyled
        ]

        #expect(Set(DisplayBlock.Kind.allCases).isSuperset(of: requiredBlockKinds))
        #expect(Set(DisplaySpan.Kind.allCases).isSuperset(of: requiredSpanKinds))
    }
}

private extension JSONEncoder {
    static var sortedPrettyPrinted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
