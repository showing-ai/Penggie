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
    let createdAt: Date
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

        guard !blocks.isEmpty, !previousBlocks.isEmpty else {
            return blocks
        }

        let previousIDs = stableIDMap(for: previousBlocks)
        var occurrenceCounts: [String: Int] = [:]

        for index in blocks.indices {
            let base = stableIdentityBase(for: blocks[index])
            let occurrence = (occurrenceCounts[base] ?? 0) + 1
            occurrenceCounts[base] = occurrence

            if let stableID = previousIDs[stableIdentityKey(base: base, occurrence: occurrence)] {
                blocks[index].id = stableID
            }
        }

        return blocks
    }

    private static func stableIDMap(for blocks: [PenggieReadingBlock]) -> [String: UUID] {
        var occurrenceCounts: [String: Int] = [:]
        var output: [String: UUID] = [:]

        for block in blocks {
            let base = stableIdentityBase(for: block)
            let occurrence = (occurrenceCounts[base] ?? 0) + 1
            occurrenceCounts[base] = occurrence
            output[stableIdentityKey(base: base, occurrence: occurrence)] = block.id
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
            guard block.kind == .output,
                  block.variant == .prompt else {
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

        if !info.hintIDs.isEmpty,
           !info.isChild,
           previous?.isBlank == true {
            return true
        }

        return false
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

        return (.unknown, .low)
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
    static func visibleBlocks(
        from blocks: [PenggieReadingBlock],
        nativeInteractionIsActive: Bool
    ) -> [PenggieReadingBlock] {
        blocks.filter { block in
            guard !isHiddenChromeBlock(block) else { return false }
            guard !isStartupChromeBlock(block) else { return false }
            guard nativeInteractionIsActive else { return true }
            return !isNativeInteractionChromeBlock(block)
        }
    }

    static func isHiddenChromeBlock(_ block: PenggieReadingBlock) -> Bool {
        guard block.kind == .output else { return false }
        return isDividerOnlyText(block.displayText)
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
