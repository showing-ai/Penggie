#if os(macOS)
import Foundation

enum ShowCLITranscriptVariant: String {
    case startup
    case prompt
    case proseLike = "prose_like"
    case toolLike = "tool_like"
    case activity
    case menu
    case status
    case unknown
}

enum ShowCLITranscriptConfidence: String {
    case high
    case medium
    case low
}

enum ShowCLITranscriptMarkerKind: String {
    case none
    case itemMarker = "item_marker"
    case promptMarker = "prompt_marker"
}

struct ShowCLITranscriptMarker: Equatable {
    var text: String
    var kind: ShowCLITranscriptMarkerKind

    var isPresent: Bool {
        kind != .none
    }

    static let none = ShowCLITranscriptMarker(text: "", kind: .none)
}

struct ShowCLITranscriptFeatures: Equatable {
    var marker: ShowCLITranscriptMarker
    var indentLevel: Int
    var dividerBefore: Bool
    var dividerAfter: Bool
    var wrapDetected: Bool
    var hintIDs: [String]
    var lineCount: Int
    var containsBlankRows: Bool
}

struct ShowCLITranscriptBlockizer {
    private static let itemMarkers: Set<Character> = ["•", "●", "○", "◦", "∙", "·"]
    private static let promptMarkers: Set<Character> = ["›"]
    private static let diagnosticMarkers: Set<Character> = ["⚠"]
    private static let dividerScalars = CharacterSet(charactersIn: "─━-═")
    private static let boxStarts: Set<Character> = ["╭", "╰", "│", "┌", "└", "├", "┘", "┐", "┼", "┬", "┴"]
    private static let childStarts: Set<Character> = ["└", "├", "│"]

    private struct Hint {
        var id: String
        var label: String
        var variant: ShowCLITranscriptVariant
    }

    private struct LineInfo {
        var index: Int
        var text: String
        var stripped: String
        var indent: Int
        var marker: ShowCLITranscriptMarker
        var body: String
        var isBlank: Bool
        var isDivider: Bool
        var isBox: Bool
        var isChild: Bool
        var wrapDetected: Bool
        var hintIDs: [String]
        var hintVariants: [ShowCLITranscriptVariant]
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
    ) -> [ShowCLIReadingBlock] {
        guard !projection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let lines = projection.components(separatedBy: "\n")
        let infos = lineInfos(for: lines, terminalColumns: terminalColumns)
        guard !infos.isEmpty else { return [] }

        let startupMode = hasStartupSignature(infos)
        let ranges = itemRanges(infos: infos, startupMode: startupMode)

        return ranges.enumerated().map { _, range in
            let rawText = lines[range.lowerBound...range.upperBound].joined(separator: "\n")
            let first = infos[range.lowerBound]
            let itemInfos = Array(infos[range])
            let variantAndConfidence = inferVariant(
                infos: itemInfos,
                first: first,
                startsAtZero: range.lowerBound == 0,
                startupMode: startupMode
            )

            return ShowCLIReadingBlock(
                kind: .output,
                text: rawText,
                displayText: displayText(rawText, removing: first.marker),
                createdAt: createdAt,
                variant: variantAndConfidence.variant,
                confidence: variantAndConfidence.confidence,
                transcriptFeatures: features(
                    infos: infos,
                    range: range,
                    itemInfos: itemInfos
                ),
                isLiveProjection: true
            )
        }
    }

    static func displayText(_ rawText: String, removing marker: ShowCLITranscriptMarker) -> String {
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

    static func appendingRawContinuation(
        to block: ShowCLIReadingBlock,
        rawText: String
    ) -> ShowCLIReadingBlock {
        var updated = block
        updated.text += rawText
        updated.displayText += rawText
        updated.updatedAt = Date()
        return updated
    }

    static func canMergeAsContinuation(_ block: ShowCLIReadingBlock) -> Bool {
        !block.transcriptFeatures.marker.isPresent &&
            (block.variant == .proseLike || block.variant == .unknown)
    }

    private static func lineInfos(
        for lines: [String],
        terminalColumns: Int?
    ) -> [LineInfo] {
        lines.enumerated().map { index, text in
            let stripped = text.trimmingCharacters(in: .whitespaces)
            let indent = text.prefix { $0 == " " }.count
            let marker = markerAndBody(text).marker
            let body = markerAndBody(text).body
            let bodyForHint = childStarts.contains(stripped.first ?? "\0")
                ? String(stripped.dropFirst()).dropLeadingSpaces()
                : body
            let matchedHints = matchHints(normalizedHintBody(bodyForHint))

            return LineInfo(
                index: index,
                text: text,
                stripped: stripped,
                indent: indent,
                marker: marker,
                body: body,
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

    private static func markerAndBody(_ text: String) -> (marker: ShowCLITranscriptMarker, body: String) {
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

        if info.isDivider {
            return true
        }

        if previous?.isDivider == true {
            return true
        }

        if info.marker.isPresent {
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
    ) -> (variant: ShowCLITranscriptVariant, confidence: ShowCLITranscriptConfidence) {
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
    ) -> ShowCLITranscriptFeatures {
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
#endif
