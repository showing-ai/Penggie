import Foundation

struct PenggieComposerSubmission: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let submittedAt: Date
}

enum PenggieReadingBlockKind: String {
    case input
    case output
}

enum PenggieTranscriptVariant: String {
    case startup
    case prompt
    case proseLike = "prose_like"
    case toolLike = "tool_like"
    case activity
    case menu
    case status
    case unknown
}

enum PenggieTranscriptConfidence: String {
    case high
    case medium
    case low
}

enum PenggieTranscriptMarkerKind: String {
    case none
    case itemMarker = "item_marker"
    case promptMarker = "prompt_marker"
}

struct PenggieTranscriptMarker: Equatable {
    var text: String
    var kind: PenggieTranscriptMarkerKind

    var isPresent: Bool {
        kind != .none
    }

    static let none = PenggieTranscriptMarker(text: "", kind: .none)
}

struct PenggieTranscriptFeatures: Equatable {
    var marker: PenggieTranscriptMarker
    var indentLevel: Int
    var dividerBefore: Bool
    var dividerAfter: Bool
    var wrapDetected: Bool
    var hintIDs: [String]
    var lineCount: Int
    var containsBlankRows: Bool
}

struct PenggieReadingBlock: Identifiable, Equatable {
    var id: UUID
    let kind: PenggieReadingBlockKind
    var text: String
    var displayText: String
    var createdAt: Date
    var updatedAt: Date
    var variant: PenggieTranscriptVariant
    var confidence: PenggieTranscriptConfidence
    var transcriptFeatures: PenggieTranscriptFeatures
    var isLiveProjection: Bool
    var composerSubmissionID: UUID?

    init(
        id: UUID = UUID(),
        kind: PenggieReadingBlockKind,
        text: String,
        displayText: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        variant: PenggieTranscriptVariant? = nil,
        confidence: PenggieTranscriptConfidence = .medium,
        transcriptFeatures: PenggieTranscriptFeatures? = nil,
        isLiveProjection: Bool = false,
        composerSubmissionID: UUID? = nil
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.displayText = displayText ?? text
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.variant = variant ?? (kind == .input ? .prompt : .unknown)
        self.confidence = confidence
        self.transcriptFeatures = transcriptFeatures ?? .init(
            marker: .none,
            indentLevel: 0,
            dividerBefore: false,
            dividerAfter: false,
            wrapDetected: false,
            hintIDs: [],
            lineCount: max(1, text.components(separatedBy: .newlines).count),
            containsBlankRows: text.components(separatedBy: .newlines).contains { $0.isEmpty }
        )
        self.isLiveProjection = isLiveProjection
        self.composerSubmissionID = composerSubmissionID
    }
}

struct PenggieReadingDisclosureBlock: Identifiable, Equatable {
    var id: String
    var summary: String
    var blocks: [PenggieReadingBlock]
    var isCollapsedByDefault = true

    var detailText: String {
        blocks
            .map { PenggieReadingPresentation.terminalText(for: $0) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    var hasDetails: Bool {
        !detailText.isEmpty
    }
}

enum PenggieReadingVisibleItem: Identifiable, Equatable {
    case block(PenggieReadingBlock)
    case disclosure(PenggieReadingDisclosureBlock)

    var id: String {
        switch self {
        case .block(let block):
            return "block-\(block.id.uuidString)"
        case .disclosure(let disclosure):
            return "disclosure-\(disclosure.id)"
        }
    }

    var block: PenggieReadingBlock? {
        guard case .block(let block) = self else { return nil }
        return block
    }

    var disclosure: PenggieReadingDisclosureBlock? {
        guard case .disclosure(let disclosure) = self else { return nil }
        return disclosure
    }
}

struct PenggieReadingTurn: Identifiable, Equatable {
    enum Status: Equatable {
        case running
        case completed
    }

    var id: UUID
    var promptBlock: PenggieReadingBlock
    var outputBlocks: [PenggieReadingBlock]
    var status: Status
    var completedAt: Date?
    var latestObservedAt: Date
    var idleCandidateObservedAt: Date?
    var idleStableFrameCount: Int
    var lastOutputFingerprint: String
    var localStatusBlockID: UUID
    var isSealed: Bool

    var blocks: [PenggieReadingBlock] {
        [promptBlock] + presentedOutputBlocks
    }

    private var presentedOutputBlocks: [PenggieReadingBlock] {
        var blocks = outputBlocks

        if status == .running,
           !blocks.contains(where: Self.isAnswerBlock),
           !blocks.contains(where: Self.isActiveWorkingBlock) {
            blocks.append(localWorkingBlock)
        }

        if status == .completed,
           !blocks.contains(where: Self.isWorkedForBlock) {
            blocks.insert(localWorkedForBlock, at: 0)
        }

        return blocks
    }

    private var localWorkingBlock: PenggieReadingBlock {
        let elapsed = max(0, Int(latestObservedAt.timeIntervalSince(promptBlock.createdAt)))
        return PenggieReadingBlock(
            id: localStatusBlockID,
            kind: .output,
            text: "Working (\(elapsed)s)",
            createdAt: promptBlock.createdAt,
            updatedAt: latestObservedAt,
            variant: .activity,
            confidence: .high,
            isLiveProjection: false
        )
    }

    private var localWorkedForBlock: PenggieReadingBlock {
        let end = completedAt ?? latestObservedAt
        let elapsed = max(1, Int(end.timeIntervalSince(promptBlock.createdAt).rounded()))
        return PenggieReadingBlock(
            id: localStatusBlockID,
            kind: .output,
            text: "Worked for \(elapsed)s",
            createdAt: end,
            updatedAt: end,
            variant: .status,
            confidence: .high,
            isLiveProjection: false
        )
    }

    private static func isAnswerBlock(_ block: PenggieReadingBlock) -> Bool {
        block.kind == .output && !PenggieReadingPresentation.isDisclosureDetailBlock(block)
    }

    private static func isActiveWorkingBlock(_ block: PenggieReadingBlock) -> Bool {
        let text = PenggieReadingPresentation.terminalText(for: block)
        return text.hasPrefix("Working") && !text.hasPrefix("Worked for")
    }

    private static func isWorkedForBlock(_ block: PenggieReadingBlock) -> Bool {
        PenggieReadingPresentation.terminalText(for: block).hasPrefix("Worked for")
    }
}

struct PenggieReadingTurnStore: Equatable {
    private(set) var turns: [PenggieReadingTurn] = []

    var blocks: [PenggieReadingBlock] {
        turns.flatMap(\.blocks)
    }

    var canSubmitPrompt: Bool {
        !turns.contains { $0.status == .running }
    }

    mutating func reset() {
        turns = []
    }

    mutating func submitPrompt(_ text: String, submittedAt: Date = Date()) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard canSubmitPrompt else { return }

        sealCompletedTurns()

        let id = UUID()
        let promptBlock = PenggieReadingBlock(
            id: id,
            kind: .input,
            text: trimmed,
            displayText: trimmed,
            createdAt: submittedAt,
            variant: .prompt,
            confidence: .high,
            isLiveProjection: false,
            composerSubmissionID: id
        )

        turns.append(
            PenggieReadingTurn(
                id: id,
                promptBlock: promptBlock,
                outputBlocks: [],
                status: .running,
                completedAt: nil,
                latestObservedAt: submittedAt,
                idleCandidateObservedAt: nil,
                idleStableFrameCount: 0,
                lastOutputFingerprint: "",
                localStatusBlockID: UUID(),
                isSealed: false
            )
        )
    }

    mutating func updateActiveTurn(
        from projection: String,
        terminalColumns: Int?,
        createdAt: Date = Date(),
        nativeInteractionIsActive: Bool = false
    ) {
        guard !nativeInteractionIsActive,
              let activeIndex = turns.lastIndex(where: { !$0.isSealed }) else {
            return
        }
        turns[activeIndex].latestObservedAt = createdAt

        let parsedBlocks = PenggieTranscriptBlockizer.blockizeOutput(
            projection,
            terminalColumns: terminalColumns,
            createdAt: createdAt
        )
        let activeProjectionBlocks = activeProjectionBlocks(
            from: parsedBlocks,
            activeIndex: activeIndex
        )
        let visibleBlocks = PenggieReadingPresentation.visibleBlocks(
            from: activeProjectionBlocks,
            nativeInteractionIsActive: false
        )
        let outputBlocks = activeOutputBlocks(
            from: visibleBlocks.filter { $0.kind == .output },
            activeIndex: activeIndex
        ).compactMap(strippingCodexSessionMetadataLines)
        let mergedOutputBlocks = mergingActiveOutputBlocks(
            previousBlocks: turns[activeIndex].outputBlocks,
            projectedBlocks: outputBlocks
        )
        turns[activeIndex].outputBlocks = preservingStableOutputMetadata(
            mergedOutputBlocks,
            previousBlocks: turns[activeIndex].outputBlocks
        )

        updateActiveTurnCompletion(
            at: activeIndex,
            createdAt: createdAt,
            parsedBlocks: parsedBlocks,
            outputBlocks: turns[activeIndex].outputBlocks
        )
    }

    private mutating func sealCompletedTurns() {
        for index in turns.indices where turns[index].status == .completed {
            turns[index].isSealed = true
        }
    }

    private func activeProjectionBlocks(
        from parsedBlocks: [PenggieReadingBlock],
        activeIndex: Array<PenggieReadingTurn>.Index
    ) -> [PenggieReadingBlock] {
        guard let promptEchoIndex = latestPromptEchoIndex(
            in: parsedBlocks,
            matching: turns[activeIndex].promptBlock
        ) else {
            return parsedBlocks
        }

        let startIndex = parsedBlocks.index(after: promptEchoIndex)
        guard startIndex < parsedBlocks.endIndex else { return [] }
        return Array(parsedBlocks[startIndex..<parsedBlocks.endIndex])
    }

    private func latestPromptEchoIndex(
        in blocks: [PenggieReadingBlock],
        matching promptBlock: PenggieReadingBlock
    ) -> Array<PenggieReadingBlock>.Index? {
        let promptText = normalizedTurnText(promptBlock.displayText)
        guard !promptText.isEmpty else { return nil }

        return blocks.indices.reversed().first { index in
            let block = blocks[index]
            guard PenggieReadingPresentation.isTerminalPromptEchoBlock(block) else {
                return false
            }

            return normalizedTurnText(PenggieReadingPresentation.promptText(for: block)) == promptText
        }
    }

    private func activeOutputBlocks(
        from visibleOutputBlocks: [PenggieReadingBlock],
        activeIndex: Array<PenggieReadingTurn>.Index
    ) -> [PenggieReadingBlock] {
        let completedOutputBlocks = turns[..<activeIndex].flatMap(\.outputBlocks)
        guard !completedOutputBlocks.isEmpty else {
            return visibleOutputBlocks
        }

        let visibleOutputBlocks = strippingLeadingCompletedOverlap(
            from: visibleOutputBlocks,
            completedOutputBlocks: completedOutputBlocks
        )
        var remainingCompletedBlocks = completedOutputBlocks
        return visibleOutputBlocks.compactMap { block in
            strippingCompletedPrefixes(
                from: block,
                completedOutputBlocks: &remainingCompletedBlocks
            )
        }
    }

    private func mergingActiveOutputBlocks(
        previousBlocks: [PenggieReadingBlock],
        projectedBlocks: [PenggieReadingBlock]
    ) -> [PenggieReadingBlock] {
        let previousBlocks = pruningStaleLiveActivity(
            from: previousBlocks,
            projectedBlocks: projectedBlocks
        )

        guard !previousBlocks.isEmpty else { return projectedBlocks }
        guard !projectedBlocks.isEmpty else { return previousBlocks }

        let projectedTail = strippingLeadingCompletedOverlap(
            from: projectedBlocks,
            completedOutputBlocks: previousBlocks
        )
        var remainingPreviousBlocks = previousBlocks
        let newTailBlocks = projectedTail.compactMap { block in
            strippingCompletedPrefixes(
                from: block,
                completedOutputBlocks: &remainingPreviousBlocks
            )
        }

        guard !newTailBlocks.isEmpty else { return previousBlocks }
        return previousBlocks + newTailBlocks
    }

    private func pruningStaleLiveActivity(
        from previousBlocks: [PenggieReadingBlock],
        projectedBlocks: [PenggieReadingBlock]
    ) -> [PenggieReadingBlock] {
        guard projectedBlocks.contains(where: isAnswerBlock),
              !projectedBlocks.contains(where: isActiveWorkingBlock) else {
            return previousBlocks
        }

        return previousBlocks.filter { !isActiveWorkingBlock($0) }
    }

    private func isAnswerBlock(_ block: PenggieReadingBlock) -> Bool {
        block.kind == .output && !PenggieReadingPresentation.isDisclosureDetailBlock(block)
    }

    private func isActiveWorkingBlock(_ block: PenggieReadingBlock) -> Bool {
        let text = PenggieReadingPresentation.terminalText(for: block)
        return text.hasPrefix("Working") && !text.hasPrefix("Worked for")
    }

    private mutating func updateActiveTurnCompletion(
        at activeIndex: Array<PenggieReadingTurn>.Index,
        createdAt: Date,
        parsedBlocks: [PenggieReadingBlock],
        outputBlocks: [PenggieReadingBlock]
    ) {
        let fingerprint = outputFingerprint(for: outputBlocks)
        let outputChanged = fingerprint != turns[activeIndex].lastOutputFingerprint
        turns[activeIndex].lastOutputFingerprint = fingerprint

        if turns[activeIndex].status == .completed {
            if outputChanged {
                turns[activeIndex].status = .running
                turns[activeIndex].completedAt = nil
                turns[activeIndex].idleCandidateObservedAt = nil
                turns[activeIndex].idleStableFrameCount = 0
            } else {
                return
            }
        }

        let hasAnswer = outputBlocks.contains(where: isAnswerBlock)
        let hasActiveWorking = outputBlocks.contains(where: isActiveWorkingBlock)
        let hasCompletionSignal = parsedBlocks.contains(where: containsCodexIdleMetadataLine) ||
            outputBlocks.contains(where: isWorkedForBlock)

        guard hasAnswer, !hasActiveWorking, hasCompletionSignal else {
            turns[activeIndex].idleCandidateObservedAt = nil
            turns[activeIndex].idleStableFrameCount = 0
            return
        }

        if turns[activeIndex].idleCandidateObservedAt == nil || outputChanged {
            turns[activeIndex].idleCandidateObservedAt = createdAt
            turns[activeIndex].idleStableFrameCount = 0
            return
        }

        turns[activeIndex].idleStableFrameCount += 1
        if turns[activeIndex].idleStableFrameCount >= 1 {
            turns[activeIndex].status = .completed
            turns[activeIndex].completedAt = createdAt
        }
    }

    private func containsCodexIdleMetadataLine(_ block: PenggieReadingBlock) -> Bool {
        PenggieReadingPresentation.normalizedLines(from: block.displayText)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .contains { PenggieReadingPresentation.isCodexSessionMetadataLine($0) }
    }

    private func strippingCodexSessionMetadataLines(from block: PenggieReadingBlock) -> PenggieReadingBlock? {
        let textLines = PenggieReadingPresentation.normalizedLines(from: block.text)
            .filter { !PenggieReadingPresentation.isCodexSessionMetadataLine($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        let displayLines = PenggieReadingPresentation.normalizedLines(from: block.displayText)
            .filter { !PenggieReadingPresentation.isCodexSessionMetadataLine($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

        let text = textLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        let displayText = displayLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || !displayText.isEmpty else { return nil }

        var stripped = block
        stripped.text = text.isEmpty ? displayText : text
        stripped.displayText = displayText.isEmpty ? stripped.text : displayText
        stripped.transcriptFeatures.lineCount = max(1, stripped.displayText.components(separatedBy: .newlines).count)
        stripped.transcriptFeatures.containsBlankRows = stripped.displayText.components(separatedBy: .newlines).contains { $0.isEmpty }
        return stripped
    }

    private func isWorkedForBlock(_ block: PenggieReadingBlock) -> Bool {
        PenggieReadingPresentation.terminalText(for: block).hasPrefix("Worked for")
    }

    private func outputFingerprint(for blocks: [PenggieReadingBlock]) -> String {
        blocks
            .map { block in
                [
                    block.kind.rawValue,
                    block.variant.rawValue,
                    PenggieReadingPresentation.terminalText(for: block)
                ].joined(separator: "\u{1F}")
            }
            .joined(separator: "\u{1E}")
    }

    private func strippingLeadingCompletedOverlap(
        from blocks: [PenggieReadingBlock],
        completedOutputBlocks: [PenggieReadingBlock]
    ) -> [PenggieReadingBlock] {
        var output = blocks

        while let first = output.first,
              let stripped = strippingLeadingCompletedSuffix(
                  from: first,
                  completedOutputBlocks: completedOutputBlocks
              ) {
            if stripped.text.isEmpty {
                output.removeFirst()
            } else {
                output[0] = stripped
                break
            }
        }

        return output
    }

    private func strippingLeadingCompletedSuffix(
        from block: PenggieReadingBlock,
        completedOutputBlocks: [PenggieReadingBlock]
    ) -> PenggieReadingBlock? {
        let blockText = normalizedTurnText(block.text)
        guard !blockText.isEmpty else { return nil }

        guard let matchedPrefix = completedOverlapPrefixes(from: completedOutputBlocks)
            .filter({ prefix in
                blockText == prefix || blockText.hasPrefix(prefix)
            })
            .max(by: { $0.count < $1.count }) else {
            return nil
        }

        if blockText == matchedPrefix {
            var empty = block
            empty.text = ""
            empty.displayText = ""
            return empty
        }

        guard let suffix = Self.suffixAfterTextPrefix(in: block.text, prefix: matchedPrefix) else {
            return nil
        }

        var stripped = block
        stripped.id = UUID()
        stripped.text = suffix
        stripped.displayText = suffix
        stripped.transcriptFeatures.lineCount = max(1, suffix.components(separatedBy: .newlines).count)
        stripped.transcriptFeatures.containsBlankRows = suffix.components(separatedBy: .newlines).contains { $0.isEmpty }
        return stripped
    }

    private func completedOverlapPrefixes(from completedOutputBlocks: [PenggieReadingBlock]) -> [String] {
        completedOutputBlocks.flatMap { block in
            let text = normalizedTurnText(block.text)
            guard !text.isEmpty else { return [String]() }

            var suffixes = [text]
            let paragraphs = text.components(separatedBy: "\n\n")
            if paragraphs.count > 1 {
                for index in paragraphs.indices.dropFirst() {
                    suffixes.append(paragraphs[index...].joined(separator: "\n\n"))
                }
            }

            return suffixes
        }
    }

    private func strippingCompletedPrefixes(
        from block: PenggieReadingBlock,
        completedOutputBlocks: inout [PenggieReadingBlock]
    ) -> PenggieReadingBlock? {
        var current = block

        while let match = firstCompletedPrefixMatch(
            in: current,
            completedOutputBlocks: completedOutputBlocks
        ) {
            completedOutputBlocks.removeFirst(match.index + 1)

            guard !match.suffix.text.isEmpty else {
                return nil
            }

            current.id = UUID()
            current.text = match.suffix.text
            current.displayText = match.suffix.displayText
            current.transcriptFeatures.lineCount = max(1, match.suffix.displayText.components(separatedBy: .newlines).count)
            current.transcriptFeatures.containsBlankRows = match.suffix.displayText.components(separatedBy: .newlines).contains { $0.isEmpty }
        }

        return current
    }

    private func firstCompletedPrefixMatch(
        in block: PenggieReadingBlock,
        completedOutputBlocks: [PenggieReadingBlock]
    ) -> (index: Int, suffix: (text: String, displayText: String))? {
        for index in completedOutputBlocks.indices {
            if let suffix = Self.suffixAfterCompletedPrefix(
                in: block.text,
                displayText: block.displayText,
                completed: completedOutputBlocks[index]
            ) {
                return (index, suffix)
            }

            if !completedOutputBlocks[index].text.isEmpty,
               block.text.trimmingCharacters(in: .whitespacesAndNewlines) == completedOutputBlocks[index].text.trimmingCharacters(in: .whitespacesAndNewlines) {
                break
            }
        }

        return nil
    }

    private static func suffixAfterTextPrefix(in text: String, prefix: String) -> String? {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedText.hasPrefix(prefix) else { return nil }

        let suffix = normalizedText.dropFirst(prefix.count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String(suffix)
    }

    private static func suffixAfterCompletedPrefix(
        in text: String,
        displayText: String,
        completed: PenggieReadingBlock
    ) -> (text: String, displayText: String)? {
        let completedText = completed.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !completedText.isEmpty else { return nil }

        if text.trimmingCharacters(in: .whitespacesAndNewlines) == completedText {
            return ("", "")
        }

        guard text.hasPrefix(completedText) else {
            return nil
        }

        let textSuffix = text.dropFirst(completedText.count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let displaySuffix = displayText.hasPrefix(completed.displayText)
            ? displayText.dropFirst(completed.displayText.count).trimmingCharacters(in: .whitespacesAndNewlines)
            : textSuffix

        return (String(textSuffix), String(displaySuffix))
    }

    private func preservingStableOutputMetadata(
        _ blocks: [PenggieReadingBlock],
        previousBlocks: [PenggieReadingBlock]
    ) -> [PenggieReadingBlock] {
        let previousBlocksByIdentity = stableBlockMap(for: previousBlocks)
        var occurrenceCounts: [String: Int] = [:]

        return blocks.map { block in
            var block = block
            let base = stableIdentityBase(for: block)
            let occurrence = (occurrenceCounts[base] ?? 0) + 1
            occurrenceCounts[base] = occurrence

            if let previous = previousBlocksByIdentity[stableIdentityKey(base: base, occurrence: occurrence)] {
                block.id = previous.id
                block.createdAt = previous.createdAt
            }

            return block
        }
    }

    private func stableBlockMap(for blocks: [PenggieReadingBlock]) -> [String: PenggieReadingBlock] {
        var occurrenceCounts: [String: Int] = [:]
        var output: [String: PenggieReadingBlock] = [:]

        for block in blocks {
            let base = stableIdentityBase(for: block)
            let occurrence = (occurrenceCounts[base] ?? 0) + 1
            occurrenceCounts[base] = occurrence
            output[stableIdentityKey(base: base, occurrence: occurrence)] = block
        }

        return output
    }

    private func stableIdentityBase(for block: PenggieReadingBlock) -> String {
        [
            block.kind.rawValue,
            block.variant.rawValue,
            block.text
        ].joined(separator: "\u{1F}")
    }

    private func stableIdentityKey(base: String, occurrence: Int) -> String {
        "\(base)\u{1E}\(occurrence)"
    }

    private func normalizedTurnText(_ text: String) -> String {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum PenggieReadingProjectionModel {
    static func blocks(
        from projection: String,
        terminalColumns: Int?,
        previousBlocks: [PenggieReadingBlock] = [],
        composerSubmissions: [PenggieComposerSubmission] = [],
        consumedComposerSubmissionIDs: Set<UUID> = [],
        createdAt: Date = Date()
    ) -> [PenggieReadingBlock] {
        var blocks = PenggieTranscriptBlockizer.blockizeOutput(
            projection,
            terminalColumns: terminalColumns,
            createdAt: createdAt
        )
        blocks = promoteComposerOwnedPromptBlocks(
            blocks,
            previousBlocks: previousBlocks,
            composerSubmissions: composerSubmissions,
            consumedComposerSubmissionIDs: consumedComposerSubmissionIDs
        )

        if !previousBlocks.isEmpty {
            blocks = splittingBlocksWithStablePreviousPrefix(blocks, previousBlocks: previousBlocks)

            let previousBlocksByIdentity = stableBlockMap(for: previousBlocks)
            var occurrenceCounts: [String: Int] = [:]

            for index in blocks.indices {
                let base = stableIdentityBase(for: blocks[index])
                let occurrence = (occurrenceCounts[base] ?? 0) + 1
                occurrenceCounts[base] = occurrence

                if let previous = previousBlocksByIdentity[stableIdentityKey(base: base, occurrence: occurrence)] {
                    blocks[index].id = previous.id
                    blocks[index].createdAt = previous.createdAt
                }
            }
        }

        return keepingComposerInputBlocks(
            in: blocks,
            previousBlocks: previousBlocks,
            composerSubmissions: composerSubmissions
        )
    }

    private static func splittingBlocksWithStablePreviousPrefix(
        _ blocks: [PenggieReadingBlock],
        previousBlocks: [PenggieReadingBlock]
    ) -> [PenggieReadingBlock] {
        let previousOutputBlocks = previousBlocks.filter { $0.kind == .output && !$0.text.isEmpty }
        guard !previousOutputBlocks.isEmpty else { return blocks }

        return blocks.flatMap { block in
            splitBlockWithStablePreviousPrefixes(block, previousOutputBlocks: previousOutputBlocks)
        }
    }

    private static func splitBlockWithStablePreviousPrefixes(
        _ block: PenggieReadingBlock,
        previousOutputBlocks: [PenggieReadingBlock]
    ) -> [PenggieReadingBlock] {
        guard block.kind == .output else { return [block] }

        var output: [PenggieReadingBlock] = []
        var remaining = block

        while let prefix = longestPreviousOutputPrefix(in: remaining, previousOutputBlocks: previousOutputBlocks),
              let split = split(remaining, afterPrefixFrom: prefix) {
            output.append(split.prefixBlock)
            remaining = split.suffixBlock
        }

        output.append(remaining)
        return output
    }

    private static func longestPreviousOutputPrefix(
        in block: PenggieReadingBlock,
        previousOutputBlocks: [PenggieReadingBlock]
    ) -> PenggieReadingBlock? {
        previousOutputBlocks
            .filter { previous in
                guard previous.text != block.text else { return false }
                return block.text.hasPrefix(previous.text)
                    && suffixAfterPrefix(in: block.text, prefix: previous.text) != nil
            }
            .max { lhs, rhs in
                lhs.text.count < rhs.text.count
            }
    }

    private static func split(
        _ block: PenggieReadingBlock,
        afterPrefixFrom previousBlock: PenggieReadingBlock
    ) -> (prefixBlock: PenggieReadingBlock, suffixBlock: PenggieReadingBlock)? {
        guard let suffix = suffixAfterPrefix(in: block.text, prefix: previousBlock.text) else {
            return nil
        }

        var prefixBlock = block
        prefixBlock.id = previousBlock.id
        prefixBlock.text = previousBlock.text
        prefixBlock.displayText = previousBlock.displayText
        prefixBlock.createdAt = previousBlock.createdAt
        prefixBlock.updatedAt = previousBlock.updatedAt
        prefixBlock.variant = previousBlock.variant
        prefixBlock.confidence = previousBlock.confidence
        prefixBlock.transcriptFeatures = previousBlock.transcriptFeatures
        prefixBlock.isLiveProjection = previousBlock.isLiveProjection
        prefixBlock.composerSubmissionID = previousBlock.composerSubmissionID

        var suffixBlock = block
        suffixBlock.id = UUID()
        suffixBlock.text = suffix
        suffixBlock.displayText = suffix
        suffixBlock.transcriptFeatures.lineCount = max(1, suffix.components(separatedBy: .newlines).count)
        suffixBlock.transcriptFeatures.containsBlankRows = suffix.components(separatedBy: .newlines).contains { $0.isEmpty }

        return (prefixBlock, suffixBlock)
    }

    private static func suffixAfterPrefix(in text: String, prefix: String) -> String? {
        guard text.hasPrefix(prefix) else { return nil }
        let suffix = text.dropFirst(prefix.count)
            .trimmingCharacters(in: .newlines)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return suffix.isEmpty ? nil : String(suffix)
    }

    private static func keepingComposerInputBlocks(
        in blocks: [PenggieReadingBlock],
        previousBlocks: [PenggieReadingBlock],
        composerSubmissions: [PenggieComposerSubmission]
    ) -> [PenggieReadingBlock] {
        guard !composerSubmissions.isEmpty else { return blocks }

        var representedSubmissionIDs = Set(blocks.compactMap(\.composerSubmissionID))
        let previousInputBySubmissionID: [UUID: PenggieReadingBlock] = Dictionary(
            uniqueKeysWithValues: previousBlocks.compactMap { block -> (UUID, PenggieReadingBlock)? in
                guard block.kind == .input,
                      let id = block.composerSubmissionID else { return nil }
                return (id, block)
            }
        )

        var persistentInputs: [PenggieReadingBlock] = []
        for submission in composerSubmissions where !representedSubmissionIDs.contains(submission.id) {
            if let previous = previousInputBySubmissionID[submission.id] {
                persistentInputs.append(previous)
            } else {
                persistentInputs.append(composerSubmissionBlock(from: submission))
            }
            representedSubmissionIDs.insert(submission.id)
        }

        guard !persistentInputs.isEmpty else { return blocks }
        return mergeByCreationTime(blocks: blocks, insertedInputs: persistentInputs)
    }

    private static func mergeByCreationTime(
        blocks: [PenggieReadingBlock],
        insertedInputs: [PenggieReadingBlock]
    ) -> [PenggieReadingBlock] {
        let orderedBlocks = blocks.enumerated().map { order, block in
            OrderedBlock(block: block, sourceOrder: order, prefersInsertionOnTie: false)
        }
        let orderedInputs = insertedInputs.enumerated().map { order, block in
            OrderedBlock(block: block, sourceOrder: order, prefersInsertionOnTie: true)
        }

        return (orderedBlocks + orderedInputs)
            .sorted { lhs, rhs in
                if lhs.block.createdAt != rhs.block.createdAt {
                    return lhs.block.createdAt < rhs.block.createdAt
                }

                if lhs.prefersInsertionOnTie != rhs.prefersInsertionOnTie {
                    return lhs.prefersInsertionOnTie
                }

                return lhs.sourceOrder < rhs.sourceOrder
            }
            .map(\.block)
    }

    private struct OrderedBlock {
        var block: PenggieReadingBlock
        var sourceOrder: Int
        var prefersInsertionOnTie: Bool
    }

    private static func stableBlockMap(for blocks: [PenggieReadingBlock]) -> [String: PenggieReadingBlock] {
        var occurrenceCounts: [String: Int] = [:]
        var output: [String: PenggieReadingBlock] = [:]

        for block in blocks {
            let base = stableIdentityBase(for: block)
            let occurrence = (occurrenceCounts[base] ?? 0) + 1
            occurrenceCounts[base] = occurrence
            output[stableIdentityKey(base: base, occurrence: occurrence)] = block
        }

        return output
    }

    private static func stableIdentityBase(for block: PenggieReadingBlock) -> String {
        [
            block.kind.rawValue,
            block.variant.rawValue,
            block.text,
            block.composerSubmissionID?.uuidString ?? ""
        ].joined(separator: "\u{1F}")
    }

    private static func stableIdentityKey(base: String, occurrence: Int) -> String {
        "\(base)\u{1E}\(occurrence)"
    }

    private static func promoteComposerOwnedPromptBlocks(
        _ blocks: [PenggieReadingBlock],
        previousBlocks: [PenggieReadingBlock],
        composerSubmissions: [PenggieComposerSubmission],
        consumedComposerSubmissionIDs: Set<UUID>
    ) -> [PenggieReadingBlock] {
        guard !composerSubmissions.isEmpty else { return blocks }

        var consumedSubmissionIDs = consumedComposerSubmissionIDs
        var previousPromotions = previousComposerPromotionsByRawText(previousBlocks)

        return blocks.map { block in
            guard canPromoteComposerOwnedBlock(block) else {
                return block
            }

            if var existingPromotions = previousPromotions[block.text],
               !existingPromotions.isEmpty {
                let previous = existingPromotions.removeFirst()
                previousPromotions[block.text] = existingPromotions

                if let composerSubmissionID = previous.composerSubmissionID {
                    consumedSubmissionIDs.insert(composerSubmissionID)
                }

                return composerPromptBlock(
                    from: block,
                    displayText: previous.displayText,
                    createdAt: previous.createdAt,
                    composerSubmissionID: previous.composerSubmissionID
                )
            }

            guard let matchIndex = matchingComposerSubmissionIndex(
                for: block,
                in: composerSubmissions,
                consumedSubmissionIDs: consumedSubmissionIDs
            ) else {
                return block
            }

            let submission = composerSubmissions[matchIndex]
            consumedSubmissionIDs.insert(submission.id)

            return composerPromptBlock(
                from: block,
                displayText: submission.text,
                createdAt: submission.submittedAt,
                composerSubmissionID: submission.id
            )
        }
    }

    private static func canPromoteComposerOwnedBlock(_ block: PenggieReadingBlock) -> Bool {
        guard block.kind == .output else { return false }

        switch block.variant {
        case .prompt:
            return true
        case .proseLike, .unknown:
            return hasOnlySessionMetadataAfterFirstContentLine(block)
        case .startup, .toolLike, .activity, .menu, .status:
            return false
        }
    }

    private static func hasOnlySessionMetadataAfterFirstContentLine(_ block: PenggieReadingBlock) -> Bool {
        let contentLines = block.displayText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard contentLines.count >= 1 else { return false }
        return contentLines.dropFirst().allSatisfy(isCodexSessionMetadataLine)
    }

    private static func isCodexSessionMetadataLine(_ line: String) -> Bool {
        let normalized = line.lowercased()
        return normalized.hasPrefix("gpt-") && (normalized.contains("·") || normalized.contains("~"))
    }

    private static func composerPromptBlock(
        from terminalBlock: PenggieReadingBlock,
        displayText: String,
        createdAt: Date,
        composerSubmissionID: UUID?
    ) -> PenggieReadingBlock {
        PenggieReadingBlock(
            id: terminalBlock.id,
            kind: .input,
            text: terminalBlock.text,
            displayText: displayText,
            createdAt: createdAt,
            updatedAt: terminalBlock.updatedAt,
            variant: .prompt,
            confidence: .high,
            transcriptFeatures: terminalBlock.transcriptFeatures,
            isLiveProjection: terminalBlock.isLiveProjection,
            composerSubmissionID: composerSubmissionID
        )
    }

    private static func composerSubmissionBlock(
        from submission: PenggieComposerSubmission
    ) -> PenggieReadingBlock {
        PenggieReadingBlock(
            id: submission.id,
            kind: .input,
            text: submission.text,
            displayText: submission.text,
            createdAt: submission.submittedAt,
            variant: .prompt,
            confidence: .high,
            isLiveProjection: false,
            composerSubmissionID: submission.id
        )
    }

    private static func previousComposerPromotionsByRawText(
        _ blocks: [PenggieReadingBlock]
    ) -> [String: [PenggieReadingBlock]] {
        blocks.reduce(into: [:]) { output, block in
            guard block.kind == .input,
                  block.variant == .prompt,
                  block.composerSubmissionID != nil else { return }

            output[block.text, default: []].append(block)
        }
    }

    private static func matchingComposerSubmissionIndex(
        for block: PenggieReadingBlock,
        in submissions: [PenggieComposerSubmission],
        consumedSubmissionIDs: Set<UUID>
    ) -> Int? {
        let promptText = normalizedPromptText(terminalPromptText(for: block))
        guard !promptText.isEmpty else { return nil }

        return submissions.indices.first { index in
            !consumedSubmissionIDs.contains(submissions[index].id) &&
                normalizedPromptText(submissions[index].text) == promptText
        }
    }

    private static func terminalPromptText(for block: PenggieReadingBlock) -> String {
        block.displayText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
    }

    private static func normalizedPromptText(_ text: String) -> String {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}

enum PenggieTranscriptBlockizer {
    private static let itemMarkers: Set<Character> = ["•", "●", "○", "◦", "∙", "·"]
    private static let promptMarkers: Set<Character> = ["›"]
    private static let diagnosticMarkers: Set<Character> = ["⚠"]
    private static let dividerScalars = CharacterSet(charactersIn: "─━-═")
    private static let boxStarts: Set<Character> = ["╭", "╰", "│", "┌", "└", "├", "┘", "┐", "┼", "┬", "┴"]
    private static let childStarts: Set<Character> = ["└", "├", "│"]

    private struct Hint {
        var id: String
        var label: String
        var variant: PenggieTranscriptVariant
    }

    private struct LineInfo {
        var index: Int
        var text: String
        var stripped: String
        var indent: Int
        var marker: PenggieTranscriptMarker
        var body: String
        var isBlank: Bool
        var isDivider: Bool
        var isBox: Bool
        var isChild: Bool
        var wrapDetected: Bool
        var hintIDs: [String]
        var hintVariants: [PenggieTranscriptVariant]
    }

    private static let hints: [Hint] = [
        .init(id: "codex.tool.ran", label: "Ran", variant: .toolLike),
        .init(id: "codex.tool.running", label: "Running", variant: .activity),
        .init(id: "codex.tool.explored", label: "Explored", variant: .toolLike),
        .init(id: "codex.tool.exploring", label: "Exploring", variant: .activity),
        .init(id: "codex.tool.read", label: "Read", variant: .toolLike),
        .init(id: "codex.tool.reading", label: "Reading", variant: .activity),
        .init(id: "codex.tool.edited", label: "Edited", variant: .toolLike),
        .init(id: "codex.tool.edited", label: "Added", variant: .toolLike),
        .init(id: "codex.tool.edited", label: "Deleted", variant: .toolLike),
        .init(id: "codex.tool.edited", label: "Updated", variant: .toolLike),
        .init(id: "codex.tool.edited", label: "Created", variant: .toolLike),
        .init(id: "codex.tool.editing", label: "Editing", variant: .activity),
        .init(id: "codex.tool.web_search", label: "Web Search", variant: .toolLike),
        .init(id: "codex.tool.web_search", label: "Searched", variant: .toolLike),
        .init(id: "codex.tool.searching", label: "Searching the web", variant: .activity),
        .init(id: "codex.tool.searching", label: "Searching", variant: .activity),
        .init(id: "codex.tool.viewed_image", label: "Viewed Image", variant: .toolLike),
        .init(id: "codex.tool.viewing", label: "Viewing", variant: .activity),
        .init(id: "codex.status.worked_for", label: "Worked for", variant: .status),
        .init(id: "codex.status.skill_context_budget", label: "Skill descriptions were shortened", variant: .status),
        .init(id: "codex.activity.working", label: "Working", variant: .activity),
        .init(id: "codex.activity.working", label: "Thinking", variant: .activity),
        .init(id: "codex.activity.working", label: "Waiting", variant: .activity),
        .init(id: "codex.activity.working", label: "Starting", variant: .activity),
    ].sorted { $0.label.count > $1.label.count }

    static func blockizeOutput(
        _ projection: String,
        terminalColumns: Int?,
        createdAt: Date = Date()
    ) -> [PenggieReadingBlock] {
        guard !projection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let lines = projection.components(separatedBy: "\n")
        let infos = lineInfos(for: lines, terminalColumns: terminalColumns)
        guard !infos.isEmpty else { return [] }

        let startupMode = hasStartupSignature(infos)
        let ranges = itemRanges(infos: infos, startupMode: startupMode)

        return ranges.map { range in
            let rawText = lines[range.lowerBound...range.upperBound].joined(separator: "\n")
            let first = infos[range.lowerBound]
            let itemInfos = Array(infos[range])
            let inferred = inferVariant(
                infos: itemInfos,
                first: first,
                startsAtZero: range.lowerBound == 0,
                startupMode: startupMode
            )

            return PenggieReadingBlock(
                kind: .output,
                text: rawText,
                displayText: displayText(rawText, removing: first.marker),
                createdAt: createdAt,
                variant: inferred.variant,
                confidence: inferred.confidence,
                transcriptFeatures: features(
                    infos: infos,
                    range: range,
                    itemInfos: itemInfos
                ),
                isLiveProjection: true
            )
        }
    }

    static func displayText(_ rawText: String, removing marker: PenggieTranscriptMarker) -> String {
        guard marker.isPresent else { return rawText }

        var lines = rawText.components(separatedBy: "\n")
        guard var first = lines.first else { return rawText }

        let leading = first.prefix { $0 == " " }
        let stripped = first.dropFirst(leading.count)
        guard stripped.first == Character(marker.text) else { return rawText }

        first = String(leading) + String(stripped.dropFirst()).dropLeadingSpaces()
        lines[0] = first
        return lines.joined(separator: "\n")
    }

    private static func lineInfos(
        for lines: [String],
        terminalColumns: Int?
    ) -> [LineInfo] {
        lines.enumerated().map { index, text in
            let stripped = text.trimmingCharacters(in: .whitespaces)
            let markerAndBody = markerAndBody(text)
            let bodyForHint = childStarts.contains(stripped.first ?? "\0")
                ? String(stripped.dropFirst()).dropLeadingSpaces()
                : markerAndBody.body
            let matchedHints = matchHints(normalizedHintBody(bodyForHint))

            return LineInfo(
                index: index,
                text: text,
                stripped: stripped,
                indent: text.prefix { $0 == " " }.count,
                marker: markerAndBody.marker,
                body: markerAndBody.body,
                isBlank: stripped.isEmpty,
                isDivider: isDividerLine(stripped, terminalColumns: terminalColumns),
                isBox: stripped.first.map { boxStarts.contains($0) } ?? false,
                isChild: stripped.first.map { childStarts.contains($0) } ?? false,
                wrapDetected: terminalColumns.map { text.count >= max(1, $0 - 2) } ?? false,
                hintIDs: matchedHints.map(\.id).deduplicated(),
                hintVariants: matchedHints.map(\.variant)
            )
        }
    }

    private static func markerAndBody(_ text: String) -> (marker: PenggieTranscriptMarker, body: String) {
        let trimmed = text.drop { $0 == " " }
        guard let first = trimmed.first else {
            return (.none, "")
        }

        if itemMarkers.contains(first) {
            return (
                .init(text: String(first), kind: .itemMarker),
                String(trimmed.dropFirst()).dropLeadingSpaces()
            )
        }

        if promptMarkers.contains(first) {
            return (
                .init(text: String(first), kind: .promptMarker),
                String(trimmed.dropFirst()).dropLeadingSpaces()
            )
        }

        return (.none, String(trimmed))
    }

    private static func matchHints(_ body: String) -> [Hint] {
        let normalized = body.trimmingCharacters(in: .whitespaces)
        return hints.filter { hint in
            guard normalized.hasPrefix(hint.label) else { return false }
            guard normalized.count > hint.label.count else { return true }
            let nextIndex = normalized.index(normalized.startIndex, offsetBy: hint.label.count)
            let next = normalized[nextIndex]
            return next.isWhitespace || "(:[{'\"`·-–—".contains(next)
        }
    }

    private static func normalizedHintBody(_ body: String) -> String {
        let trimmed = body.dropLeadingSpaces()
        guard let first = trimmed.first,
              diagnosticMarkers.contains(first) else {
            return trimmed
        }

        return String(trimmed.dropFirst()).dropLeadingSpaces()
    }

    private static func isDividerLine(_ stripped: String, terminalColumns: Int?) -> Bool {
        guard stripped.count >= 8 else { return false }
        guard stripped.unicodeScalars.allSatisfy({ dividerScalars.contains($0) }) else { return false }

        let threshold = max(8, Int(Double(terminalColumns ?? 80) * 0.35))
        return stripped.count >= threshold
    }

    private static func hasStartupSignature(_ infos: [LineInfo]) -> Bool {
        guard let firstBox = infos.prefix(12).first(where: { $0.isBox })?.index,
              firstBox <= 4 else {
            return false
        }

        var count = 0
        for info in infos.dropFirst(firstBox) {
            if info.isBlank { break }
            guard info.isBox else { return false }
            count += 1
        }

        return (4...8).contains(count)
    }

    private static func itemRanges(
        infos: [LineInfo],
        startupMode: Bool
    ) -> [ClosedRange<Int>] {
        guard !infos.isEmpty else { return [] }

        var ranges: [ClosedRange<Int>] = []
        var start = 0

        for index in infos.indices.dropFirst() {
            if shouldStartItem(
                infos: infos,
                index: index,
                currentStart: start,
                startupMode: startupMode
            ) {
                ranges.append(start...(index - 1))
                start = index
            }
        }

        ranges.append(start...(infos.count - 1))
        return ranges
    }

    private static func shouldStartItem(
        infos: [LineInfo],
        index: Int,
        currentStart: Int,
        startupMode: Bool
    ) -> Bool {
        let info = infos[index]
        let previous = index > 0 ? infos[index - 1] : nil

        if info.isBlank {
            return false
        }

        if startupMode && currentStart == 0 {
            return info.marker.isPresent || info.isDivider
        }

        if info.isDivider || previous?.isDivider == true || info.marker.isPresent {
            return true
        }

        if previous?.isBlank == true,
           index >= 2,
           infos[index - 2].isBlank,
           info.indent <= infos[currentStart].indent,
           !info.isChild {
            return true
        }

        if previous?.isBlank == true,
           infos[currentStart].marker.kind == .promptMarker,
           !info.isChild {
            return true
        }

        if !info.hintIDs.isEmpty,
           !info.isChild,
           previous?.isBlank == true {
            return true
        }

        if previous?.isBlank == true,
           info.hintIDs.isEmpty,
           currentRangeHasToolHint(infos: infos, start: currentStart, end: index),
           !info.isChild {
            return true
        }

        return false
    }

    private static func currentRangeHasToolHint(
        infos: [LineInfo],
        start: Int,
        end: Int
    ) -> Bool {
        guard start < end else { return false }
        return infos[start..<end]
            .flatMap(\.hintVariants)
            .contains { variant in
                switch variant {
                case .activity, .status, .toolLike:
                    return true
                case .startup, .prompt, .proseLike, .menu, .unknown:
                    return false
                }
            }
    }

    private static func inferVariant(
        infos: [LineInfo],
        first: LineInfo,
        startsAtZero: Bool,
        startupMode: Bool
    ) -> (variant: PenggieTranscriptVariant, confidence: PenggieTranscriptConfidence) {
        let hintIDs = infos.flatMap(\.hintIDs)
        let hintVariants = infos.flatMap(\.hintVariants)

        if startupMode && startsAtZero {
            return (.startup, .high)
        }

        if infos.allSatisfy(\.isBlank) {
            return (.unknown, .low)
        }

        if first.isDivider {
            return (.status, .medium)
        }

        if first.marker.kind == .promptMarker {
            return (.prompt, .high)
        }

        if hintVariants.contains(.activity) {
            return (.activity, .medium)
        }

        if hintVariants.contains(.toolLike) {
            return (.toolLike, .medium)
        }

        if hintVariants.contains(.status) {
            return (.status, .medium)
        }

        if hintVariants.contains(.menu) {
            return (.menu, .medium)
        }

        if first.marker.kind == .itemMarker {
            return (.proseLike, hintIDs.isEmpty ? .medium : .high)
        }

        let nonBlank = infos.map(\.stripped).filter { !$0.isEmpty }
        if !nonBlank.isEmpty,
           nonBlank.prefix(6).allSatisfy({ $0.hasPrefix("/") || $0.contains("  ") }) {
            return (.menu, .low)
        }

        if infos.contains(where: { $0.text.hasPrefix("  ") }) {
            return (.proseLike, .low)
        }

        return (.proseLike, .low)
    }

    private static func features(
        infos: [LineInfo],
        range: ClosedRange<Int>,
        itemInfos: [LineInfo]
    ) -> PenggieTranscriptFeatures {
        let first = infos[range.lowerBound]
        return .init(
            marker: first.marker,
            indentLevel: first.indent,
            dividerBefore: range.lowerBound > 0 && infos[range.lowerBound - 1].isDivider,
            dividerAfter: range.upperBound + 1 < infos.count && infos[range.upperBound + 1].isDivider,
            wrapDetected: itemInfos.contains(where: \.wrapDetected),
            hintIDs: itemInfos.flatMap(\.hintIDs).deduplicated(),
            lineCount: range.count,
            containsBlankRows: itemInfos.contains(where: \.isBlank)
        )
    }
}

enum PenggieReadingPresentation {
    static func visibleItems(
        from blocks: [PenggieReadingBlock],
        nativeInteractionIsActive: Bool
    ) -> [PenggieReadingVisibleItem] {
        let blocks = visibleBlocks(
            from: blocks,
            nativeInteractionIsActive: nativeInteractionIsActive
        )

        guard blocks.contains(where: { $0.kind == .input }) else {
            return legacyVisibleItems(from: blocks)
        }

        return turnVisibleItems(from: blocks)
    }

    private static func legacyVisibleItems(from blocks: [PenggieReadingBlock]) -> [PenggieReadingVisibleItem] {
        var items: [PenggieReadingVisibleItem] = []
        var pendingDisclosureBlocks: [PenggieReadingBlock] = []

        func flushDisclosure() {
            guard !pendingDisclosureBlocks.isEmpty else { return }
            items.append(.disclosure(disclosureBlock(from: pendingDisclosureBlocks)))
            pendingDisclosureBlocks = []
        }

        for block in blocks {
            if isDisclosureDetailBlock(block) {
                pendingDisclosureBlocks.append(block)
            } else {
                flushDisclosure()
                items.append(.block(block))
            }
        }

        flushDisclosure()
        return items
    }

    private static func turnVisibleItems(from blocks: [PenggieReadingBlock]) -> [PenggieReadingVisibleItem] {
        var items: [PenggieReadingVisibleItem] = []
        var index = blocks.startIndex

        while index < blocks.endIndex {
            let block = blocks[index]

            guard block.kind == .input else {
                let nextInputIndex = blocks[index...].firstIndex { $0.kind == .input } ?? blocks.endIndex
                items.append(contentsOf: legacyVisibleItems(from: Array(blocks[index..<nextInputIndex])))
                index = nextInputIndex
                continue
            }

            let nextIndex = blocks[blocks.index(after: index)...].firstIndex { $0.kind == .input } ?? blocks.endIndex
            let turnBlocks = Array(blocks[index..<nextIndex])
            items.append(contentsOf: visibleItemsForTurn(turnBlocks))
            index = nextIndex
        }

        return items
    }

    private static func visibleItemsForTurn(_ blocks: [PenggieReadingBlock]) -> [PenggieReadingVisibleItem] {
        guard let inputBlock = blocks.first, inputBlock.kind == .input else {
            return legacyVisibleItems(from: blocks)
        }

        let contentBlocks = Array(blocks.dropFirst())
        var items: [PenggieReadingVisibleItem] = [.block(inputBlock)]
        guard !contentBlocks.isEmpty else { return items }

        let workSplit = splitTurnWork(from: contentBlocks)

        if !workSplit.workBlocks.isEmpty {
            items.append(
                .disclosure(
                    disclosureBlock(
                        from: workSplit.workBlocks,
                        fallbackInputBlock: inputBlock,
                        fallbackOutputBlock: workSplit.answerBlocks.first
                    )
                )
            )
        } else if let firstAnswerBlock = workSplit.answerBlocks.first {
            items.append(.disclosure(localWorkSummaryDisclosure(from: inputBlock, to: firstAnswerBlock)))
        }

        items.append(contentsOf: workSplit.answerBlocks.map { .block($0) })
        return items
    }

    private struct TurnWorkSplit {
        var workBlocks: [PenggieReadingBlock]
        var answerBlocks: [PenggieReadingBlock]
    }

    private static func splitTurnWork(from contentBlocks: [PenggieReadingBlock]) -> TurnWorkSplit {
        guard !contentBlocks.isEmpty else {
            return .init(workBlocks: [], answerBlocks: [])
        }

        if containsActiveWorkingStatus(contentBlocks) {
            return .init(workBlocks: contentBlocks, answerBlocks: [])
        }

        guard contentBlocks.contains(where: isDisclosureDetailBlock) else {
            return .init(workBlocks: [], answerBlocks: contentBlocks)
        }

        guard let lastWorkIndex = contentBlocks.lastIndex(where: isDisclosureDetailBlock) else {
            return .init(workBlocks: [], answerBlocks: contentBlocks)
        }
        let workBlocks = Array(contentBlocks[...lastWorkIndex])
        let answerBlocks = lastWorkIndex < contentBlocks.index(before: contentBlocks.endIndex)
            ? Array(contentBlocks[contentBlocks.index(after: lastWorkIndex)..<contentBlocks.endIndex])
            : []

        return .init(workBlocks: workBlocks, answerBlocks: answerBlocks)
    }

    private static func containsActiveWorkingStatus(_ blocks: [PenggieReadingBlock]) -> Bool {
        blocks.contains { block in
            let text = terminalText(for: block)
            return text.hasPrefix("Working") && !text.hasPrefix("Worked for")
        }
    }

    static func visibleBlocks(
        from blocks: [PenggieReadingBlock],
        nativeInteractionIsActive: Bool
    ) -> [PenggieReadingBlock] {
        blocks.filter { block in
            guard !isHiddenChromeBlock(block) else { return false }
            guard !isStartupChromeBlock(block) else { return false }
            guard !isTerminalPromptEchoBlock(block) else { return false }
            guard nativeInteractionIsActive else { return true }
            return !isNativeInteractionChromeBlock(block)
        }
    }

    static func isHiddenChromeBlock(_ block: PenggieReadingBlock) -> Bool {
        guard block.kind == .output else { return false }
        return isDividerOnlyText(block.displayText) || isCodexSessionMetadataBlock(block)
    }

    static func isStartupChromeBlock(_ block: PenggieReadingBlock) -> Bool {
        block.kind == .output && block.variant == .startup
    }

    static func isNativeInteractionChromeBlock(_ block: PenggieReadingBlock) -> Bool {
        isToolChromeBlock(block)
    }

    static func isToolChromeBlock(_ block: PenggieReadingBlock) -> Bool {
        guard block.kind == .output else { return false }
        guard !isHiddenChromeBlock(block) else { return false }

        switch block.variant {
        case .activity, .menu, .status, .toolLike:
            return true
        case .startup:
            return true
        case .prompt:
            return true
        case .proseLike, .unknown:
            return false
        }
    }

    static func isDisclosureDetailBlock(_ block: PenggieReadingBlock) -> Bool {
        guard block.kind == .output else { return false }

        switch block.variant {
        case .activity, .status, .toolLike:
            return true
        case .startup, .prompt, .menu, .proseLike, .unknown:
            return false
        }
    }

    static func isTerminalPromptEchoBlock(_ block: PenggieReadingBlock) -> Bool {
        block.kind == .output && block.variant == .prompt
    }

    static func isPromptBlock(_ block: PenggieReadingBlock) -> Bool {
        block.kind == .input || block.variant == .prompt
    }

    static func isUserPromptBlock(_ block: PenggieReadingBlock) -> Bool {
        block.kind == .input
    }

    static func promptText(for block: PenggieReadingBlock) -> String {
        let source = block.displayText
        if block.kind == .input {
            return source.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let lines = normalizedLines(from: source)
        guard let firstContent = lines.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            return source.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return firstContent.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func chatText(for block: PenggieReadingBlock) -> String {
        if isPromptBlock(block) {
            return promptText(for: block)
        }

        let visibleLines = normalizedLines(from: block.displayText)
            .filter { !isDividerOnlyText($0) }
            .filter { !isCodexSessionMetadataLine($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

        return displayLines(from: visibleLines)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func terminalText(for block: PenggieReadingBlock) -> String {
        normalizedLines(from: block.displayText)
            .filter { !isDividerOnlyText($0) }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func disclosureBlock(
        from blocks: [PenggieReadingBlock],
        fallbackInputBlock: PenggieReadingBlock? = nil,
        fallbackOutputBlock: PenggieReadingBlock? = nil
    ) -> PenggieReadingDisclosureBlock {
        PenggieReadingDisclosureBlock(
            id: blocks.map { $0.id.uuidString }.joined(separator: "-"),
            summary: disclosureSummary(
                for: blocks,
                fallbackInputBlock: fallbackInputBlock,
                fallbackOutputBlock: fallbackOutputBlock
            ),
            blocks: blocks
        )
    }

    private static func localWorkSummaryDisclosure(
        from inputBlock: PenggieReadingBlock?,
        to outputBlock: PenggieReadingBlock
    ) -> PenggieReadingDisclosureBlock {
        PenggieReadingDisclosureBlock(
            id: "work-\(inputBlock?.id.uuidString ?? "session")-\(outputBlock.id.uuidString)",
            summary: localWorkedForSummary(from: inputBlock, to: outputBlock) ?? "Worked",
            blocks: []
        )
    }

    private static func disclosureSummary(
        for blocks: [PenggieReadingBlock],
        fallbackInputBlock: PenggieReadingBlock?,
        fallbackOutputBlock: PenggieReadingBlock?
    ) -> String {
        let texts = blocks.map { terminalText(for: $0) }.filter { !$0.isEmpty }
        let normalized = texts.map { $0.lowercased() }

        if let workedFor = texts.first(where: { $0.hasPrefix("Worked for") }) {
            return firstLine(of: workedFor)
        }

        if let working = texts.first(where: { $0.hasPrefix("Working") }) {
            return workingSummary(from: working)
        }

        if let fallback = localWorkedForSummary(from: fallbackInputBlock, to: fallbackOutputBlock) {
            return fallback
        }

        if !texts.isEmpty,
           normalized.allSatisfy({ $0.hasPrefix("searching the web") || $0.hasPrefix("searched ") }) {
            return texts.count == 1 ? "Searched the web" : "Searched the web \(texts.count) times"
        }

        if let firstActivity = texts.first(where: { $0.hasPrefix("Working") || $0.hasPrefix("Thinking") }) {
            return firstLine(of: firstActivity)
        }

        if blocks.count == 1, let only = texts.first {
            return firstLine(of: only)
        }

        return "Activity details \(blocks.count)"
    }

    private static func localWorkedForSummary(
        from inputBlock: PenggieReadingBlock?,
        to outputBlock: PenggieReadingBlock?
    ) -> String? {
        guard let inputBlock, let outputBlock else { return nil }
        let elapsed = max(1, Int(outputBlock.createdAt.timeIntervalSince(inputBlock.createdAt).rounded()))
        return "Worked for \(elapsed)s"
    }

    private static func firstLine(of text: String) -> String {
        normalizedLines(from: text)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "Activity details"
    }

    private static func workingSummary(from text: String) -> String {
        let line = firstLine(of: text)
        guard let open = line.firstIndex(of: "("),
              let close = line[open...].firstIndex(of: ")") else {
            return "Working..."
        }

        let content = line[line.index(after: open)..<close]
        let duration = content
            .split(separator: "•", maxSplits: 1)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let duration, !duration.isEmpty else {
            return "Working..."
        }

        return "Working... \(duration)"
    }

    static func isCodexSessionMetadataBlock(_ block: PenggieReadingBlock) -> Bool {
        let meaningfulLines = normalizedLines(from: block.displayText)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !meaningfulLines.isEmpty else { return false }
        return meaningfulLines.allSatisfy(isCodexSessionMetadataLine)
    }

    static func isCodexSessionMetadataLine(_ line: String) -> Bool {
        let normalized = line.lowercased()
        return normalized.hasPrefix("gpt-") && (normalized.contains("·") || normalized.contains("~"))
    }

    static func normalizedLines(from text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { trimmingTrailingWhitespace(from: $0) }
    }

    static func isDividerOnlyText(_ text: String) -> Bool {
        let meaningfulLines = normalizedLines(from: text)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !meaningfulLines.isEmpty else { return false }
        return meaningfulLines.allSatisfy(isDividerLine)
    }

    private static func isDividerLine(_ line: String) -> Bool {
        guard line.count >= 8 else { return false }

        let allowed = CharacterSet(charactersIn: "─━═-_=—– ")
        return line.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private static func displayLines(from lines: [String]) -> [String] {
        var output: [String] = []
        var current: String?
        var inCodeFence = false

        func flushCurrent() {
            guard let active = current, !active.isEmpty else { return }
            output.append(active)
            current = nil
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            guard !trimmed.isEmpty else {
                flushCurrent()
                if output.last != "" {
                    output.append("")
                }
                continue
            }

            let isFence = isCodeFenceLine(trimmed)
            if inCodeFence {
                flushCurrent()
                output.append(trimmed)
                if isFence {
                    inCodeFence = false
                }
                continue
            }

            if isFence {
                flushCurrent()
                output.append(trimmed)
                inCodeFence = true
                continue
            }

            guard let existing = current else {
                current = trimmed
                continue
            }

            if shouldStartNewDisplayLine(trimmed, after: existing) {
                flushCurrent()
                current = trimmed
            } else {
                current = existing + joinSeparator(previous: existing, next: trimmed) + trimmed
            }
        }

        flushCurrent()

        while output.last == "" {
            output.removeLast()
        }

        return output
    }

    private static func shouldStartNewDisplayLine(_ line: String, after previous: String) -> Bool {
        if isStructuralDisplayLine(line) {
            return true
        }

        return isStandaloneBoundaryLine(previous)
    }

    private static func isStandaloneBoundaryLine(_ line: String) -> Bool {
        line.hasPrefix("#") || isTableLine(line)
    }

    private static func isStructuralDisplayLine(_ line: String) -> Bool {
        if isCodeFenceLine(line) { return true }
        if line.hasPrefix("#") { return true }
        if line.hasPrefix(">") { return true }
        if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") || line.hasPrefix("• ") {
            return true
        }
        if isOrderedListLine(line) { return true }
        if isTableLine(line) { return true }
        if isLabelLikeLine(line) { return true }
        return false
    }

    private static func isCodeFenceLine(_ line: String) -> Bool {
        line.hasPrefix("```") || line.hasPrefix("~~~")
    }

    private static func isOrderedListLine(_ line: String) -> Bool {
        var index = line.startIndex
        var digitCount = 0

        while index < line.endIndex,
              let scalar = line[index].unicodeScalars.first,
              CharacterSet.decimalDigits.contains(scalar),
              digitCount < 3 {
            digitCount += 1
            index = line.index(after: index)
        }

        guard digitCount > 0, index < line.endIndex else { return false }
        let marker = line[index]
        guard marker == "." || marker == ")" || marker == "、" else { return false }

        let nextIndex = line.index(after: index)
        guard nextIndex < line.endIndex else { return false }
        return marker == "、" || line[nextIndex].isWhitespace
    }

    private static func isTableLine(_ line: String) -> Bool {
        line.first == "|" && line.last == "|"
    }

    private static func isLabelLikeLine(_ line: String) -> Bool {
        guard let punctuationIndex = line.firstIndex(where: { $0 == ":" || $0 == "：" }) else {
            return false
        }

        let prefix = line[..<punctuationIndex]
        guard !prefix.isEmpty, prefix.count <= 14 else { return false }
        return !prefix.contains(where: { $0.isWhitespace })
    }

    private static func joinSeparator(previous: String, next: String) -> String {
        guard let previousScalar = lastNonWhitespaceScalar(in: previous),
              let nextScalar = firstNonWhitespaceScalar(in: next) else {
            return ""
        }

        if isCJK(previousScalar) || isCJK(nextScalar) {
            return ""
        }

        let noSpaceAfter = CharacterSet(charactersIn: "([{/'\"“‘，、。；：！？")
        if noSpaceAfter.contains(previousScalar) {
            return ""
        }

        let noSpaceBefore = CharacterSet(charactersIn: ".,!?;:%)]}/'\"”’）】」』，。；：！？")
        if noSpaceBefore.contains(nextScalar) {
            return ""
        }

        if previousScalar == "-" || previousScalar == "/" {
            return ""
        }

        return " "
    }

    private static func firstNonWhitespaceScalar(in text: String) -> UnicodeScalar? {
        text.unicodeScalars.first { !CharacterSet.whitespacesAndNewlines.contains($0) }
    }

    private static func lastNonWhitespaceScalar(in text: String) -> UnicodeScalar? {
        text.unicodeScalars.reversed().first { !CharacterSet.whitespacesAndNewlines.contains($0) }
    }

    private static func isCJK(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x3400...0x4DBF,
             0x4E00...0x9FFF,
             0xF900...0xFAFF,
             0x3040...0x30FF,
             0xAC00...0xD7AF:
            return true
        default:
            return false
        }
    }

    private static func trimmingTrailingWhitespace(from line: String) -> String {
        var trimmed = line
        while let lastScalar = trimmed.unicodeScalars.last,
              CharacterSet.whitespaces.contains(lastScalar) {
            trimmed.removeLast()
        }
        return trimmed
    }
}

private extension String {
    func dropLeadingSpaces() -> String {
        String(drop { $0 == " " })
    }
}

private extension Array where Element: Hashable {
    func deduplicated() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
