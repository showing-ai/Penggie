import Foundation

struct PenggieDisplayASTRenderer {
    func segments(from document: DisplayDocument) -> [PenggieReadingDisplaySegment] {
        document.turns.flatMap { turn in
            segments(from: turn.blocks)
        }
    }

    func segments(from blocks: [DisplayBlock]) -> [PenggieReadingDisplaySegment] {
        blocks.compactMap { block in
            guard block.kind != .overlay else {
                return nil
            }

            let text = block.spans.map(\.text).joined()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }

            return PenggieReadingDisplaySegment(
                kind: segmentKind(for: block),
                text: text,
                renderHints: block.renderHints,
                sourceRange: block.sourceRange,
                displayBlockKind: block.kind
            )
        }
    }

    private func segmentKind(for block: DisplayBlock) -> PenggieReadingDisplaySegment.Kind {
        if block.renderHints.cellAware || block.renderHints.horizontalScroll {
            return .preformatted
        }

        switch block.kind {
        case .codeBlock, .preformatted, .table:
            return .preformatted
        case .userPrompt,
             .paragraph,
             .list,
             .listItem,
             .warning,
             .status,
             .activity,
             .toolEvent,
             .disclosure,
             .overlay,
             .divider,
             .rawFallback:
            return .prose
        }
    }
}
