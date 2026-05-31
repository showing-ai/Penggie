import Foundation

struct DisplayTranscriptReconciler: Sendable {
    private var turns: [DisplayTurn]
    private var metadata: DisplayDocument.Metadata
    private var activePrompt: SubmittedPrompt?

    init() {
        self.turns = []
        self.metadata = DisplayDocument.Metadata(
            source: .terminalProjection,
            terminalColumns: nil,
            terminalRows: nil
        )
        self.activePrompt = nil
    }

    var displayDocument: DisplayDocument {
        DisplayDocument(turns: turns, metadata: metadata)
    }

    mutating func submitPrompt(_ text: String, id: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        let block = DisplayBlock(
            id: "\(id).block",
            kind: .userPrompt,
            role: .user,
            spans: [.init(kind: .text, text: trimmed)],
            sourceRange: nil,
            sourceFingerprint: Self.fingerprint(trimmed),
            confidence: .init(level: .hard, score: 1),
            ruleHits: [
                DisplayRuleHit(
                    ruleID: "penggie.prompt.submitted",
                    mode: .hard,
                    reason: "Prompt submitted through Penggie composer."
                )
            ],
            isLive: false,
            isSealed: true,
            renderHints: .init(),
            fallback: nil
        )

        turns.append(
            DisplayTurn(
                id: id,
                role: .user,
                blocks: [block],
                sourceFingerprint: block.sourceFingerprint,
                isLive: false,
                isSealed: true
            )
        )
        activePrompt = SubmittedPrompt(id: id, text: trimmed)
    }

    mutating func updateActiveTurn(from document: DisplayDocument) {
        metadata = document.metadata

        var incoming = document.turns.flatMap(\.blocks)
            .filter { $0.kind != .overlay }

        incoming = stripProjectionBeforeCurrentPromptEcho(from: incoming)
        incoming = incoming.filter { !isEchoOfSubmittedPrompt($0) }
        incoming = stripSealedHistoryOverlap(from: incoming)

        guard !incoming.isEmpty else {
            return
        }

        incoming = incoming.map { block in
            var copy = block
            copy.isLive = true
            copy.isSealed = false
            return copy
        }

        if let activeIndex = turns.lastIndex(where: { $0.role == .assistant && !$0.isSealed }) {
            var activeTurn = turns[activeIndex]
            activeTurn.blocks = merge(existing: activeTurn.blocks, incoming: incoming)
            activeTurn.sourceFingerprint = Self.fingerprint(activeTurn.blocks.map(Self.visibleText).joined(separator: "\n"))
            activeTurn.isLive = true
            activeTurn.isSealed = false
            turns[activeIndex] = activeTurn
        } else {
            let text = incoming.map(Self.visibleText).joined(separator: "\n")
            turns.append(
                DisplayTurn(
                    id: "assistant.\(turns.count)",
                    role: .assistant,
                    blocks: incoming,
                    sourceFingerprint: Self.fingerprint(text),
                    isLive: true,
                    isSealed: false
                )
            )
        }
    }

    mutating func sealActiveTurn() {
        guard let activeIndex = turns.lastIndex(where: { $0.role == .assistant && !$0.isSealed }) else {
            activePrompt = nil
            return
        }

        var activeTurn = turns[activeIndex]
        activeTurn.blocks = activeTurn.blocks.map { block in
            var copy = block
            copy.isLive = false
            copy.isSealed = true
            return copy
        }
        activeTurn.isLive = false
        activeTurn.isSealed = true
        turns[activeIndex] = activeTurn
        activePrompt = nil
    }

    private mutating func stripProjectionBeforeCurrentPromptEcho(from blocks: [DisplayBlock]) -> [DisplayBlock] {
        guard let activePrompt else {
            return blocks
        }

        guard let echoIndex = blocks.lastIndex(where: { isPromptEcho($0, prompt: activePrompt.text) }) else {
            return blocks
        }

        let suffixStart = blocks.index(after: echoIndex)
        return Array(blocks[suffixStart...])
    }

    private func stripSealedHistoryOverlap(from blocks: [DisplayBlock]) -> [DisplayBlock] {
        let sealedBlocks = turns
            .filter { $0.role == .assistant && $0.isSealed }
            .flatMap(\.blocks)
            .filter { $0.kind != .overlay }

        return stripPrefixOverlap(prefixSource: sealedBlocks, candidate: blocks)
    }

    private func merge(existing: [DisplayBlock], incoming: [DisplayBlock]) -> [DisplayBlock] {
        guard !existing.isEmpty else {
            return incoming
        }
        guard !incoming.isEmpty else {
            return existing
        }

        if isPrefix(existing, of: incoming) {
            return incoming
        }

        if containsSubsequence(existing, incoming) {
            return existing
        }

        return stripPrefixOverlap(prefixSource: existing, candidate: incoming, thenAppendTo: existing)
    }

    private func stripPrefixOverlap(
        prefixSource: [DisplayBlock],
        candidate: [DisplayBlock],
        thenAppendTo base: [DisplayBlock]? = nil
    ) -> [DisplayBlock] {
        guard !prefixSource.isEmpty, !candidate.isEmpty else {
            return base.map { $0 + candidate } ?? candidate
        }

        let maxOverlap = min(prefixSource.count, candidate.count)
        var overlap = 0
        if maxOverlap > 0 {
            for count in stride(from: maxOverlap, through: 1, by: -1) {
                let suffix = prefixSource.suffix(count)
                let prefix = candidate.prefix(count)
                if zip(suffix, prefix).allSatisfy({ Self.sameVisibleContent($0, $1) }) {
                    overlap = count
                    break
                }
            }
        }

        let remaining = Array(candidate.dropFirst(overlap))
        if let base {
            return base + remaining
        }
        return remaining
    }

    private func isPrefix(_ prefix: [DisplayBlock], of blocks: [DisplayBlock]) -> Bool {
        guard prefix.count <= blocks.count else {
            return false
        }
        return zip(prefix, blocks).allSatisfy { Self.sameVisibleContent($0, $1) }
    }

    private func containsSubsequence(_ source: [DisplayBlock], _ candidate: [DisplayBlock]) -> Bool {
        guard !candidate.isEmpty, candidate.count <= source.count else {
            return false
        }

        let limit = source.count - candidate.count
        for start in 0...limit {
            let slice = source[start..<(start + candidate.count)]
            if zip(slice, candidate).allSatisfy({ Self.sameVisibleContent($0, $1) }) {
                return true
            }
        }
        return false
    }

    private func isEchoOfSubmittedPrompt(_ block: DisplayBlock) -> Bool {
        guard let activePrompt else {
            return false
        }
        return isPromptEcho(block, prompt: activePrompt.text)
    }

    private func isPromptEcho(_ block: DisplayBlock, prompt: String) -> Bool {
        switch block.kind {
        case .userPrompt:
            return Self.normalizedPromptEcho(Self.visibleText(block)) == Self.normalizedPromptEcho(prompt)
        default:
            return Self.normalizedPromptEcho(Self.visibleText(block)) == Self.normalizedPromptEcho(prompt)
        }
    }

    private static func sameVisibleContent(_ lhs: DisplayBlock, _ rhs: DisplayBlock) -> Bool {
        normalizedVisibleText(lhs) == normalizedVisibleText(rhs)
    }

    private static func normalizedVisibleText(_ block: DisplayBlock) -> String {
        visibleText(block)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\r\n", with: "\n")
    }

    private static func visibleText(_ block: DisplayBlock) -> String {
        block.spans.map(\.text).joined()
    }

    private static func normalizedPromptEcho(_ text: String) -> String {
        var normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        while let first = normalized.first, [">", "›", " "].contains(first) {
            normalized.removeFirst()
            normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return normalized
    }

    private static func fingerprint(_ text: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }

    private struct SubmittedPrompt: Sendable {
        var id: String
        var text: String
    }
}
