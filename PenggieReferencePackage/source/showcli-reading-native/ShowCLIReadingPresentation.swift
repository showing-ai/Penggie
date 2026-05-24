#if os(macOS)
import Foundation

enum ShowCLIReadingPresentation {
    static func isHiddenChromeBlock(_ block: ShowCLIReadingBlock) -> Bool {
        block.kind == .output && isDividerOnlyText(block.displayText)
    }

    static func isToolChromeBlock(_ block: ShowCLIReadingBlock) -> Bool {
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

    static func isPromptBlock(_ block: ShowCLIReadingBlock) -> Bool {
        block.kind == .input || block.variant == .prompt
    }

    static func isUserPromptBlock(_ block: ShowCLIReadingBlock) -> Bool {
        block.kind == .input
    }

    static func promptText(for block: ShowCLIReadingBlock) -> String {
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

    static func chatText(for block: ShowCLIReadingBlock) -> String {
        if isPromptBlock(block) {
            return promptText(for: block)
        }

        let visibleLines = normalizedLines(from: block.displayText)
            .filter { !isDividerOnlyText($0) }

        return displayLines(from: visibleLines)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func terminalText(for block: ShowCLIReadingBlock) -> String {
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
#endif
