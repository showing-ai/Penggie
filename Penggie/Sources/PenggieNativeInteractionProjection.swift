import Foundation

struct PenggieTerminalScreenSnapshot: Codable, Equatable {
    struct Cursor: Codable, Equatable {
        let x: Int
        let y: Int
        let visible: Bool
    }

    struct Line: Codable, Equatable {
        struct StyleSummary: Codable, Equatable {
            let textCellCount: Int
            let selectedCellCount: Int
            let selectedTextCellCount: Int
            let boldTextCellCount: Int
            let faintTextCellCount: Int
            let inverseTextCellCount: Int
            let backgroundTextCellCount: Int
            let foregroundTextCellCount: Int

            var hasExplicitSelectionStyle: Bool {
                guard textCellCount > 0 else { return false }

                let selectedTextThreshold = max(1, (textCellCount + 1) / 2)
                if selectedTextCellCount >= selectedTextThreshold {
                    return true
                }

                let selectedRowThreshold = max(3, textCellCount)
                return selectedCellCount >= selectedRowThreshold
                    || inverseTextCellCount >= selectedTextThreshold
                    || backgroundTextCellCount >= selectedTextThreshold
            }

            var hasForegroundSelectionStyle: Bool {
                guard textCellCount > 0 else { return false }

                let textThreshold = max(1, (textCellCount + 1) / 2)
                if foregroundTextCellCount >= textThreshold {
                    return faintTextCellCount < textThreshold
                }

                guard boldTextCellCount > 0 else { return false }
                return faintTextCellCount < max(1, textCellCount / 2)
            }

            var hasUndimmedMenuSelectionStyle: Bool {
                textCellCount > 0
                    && boldTextCellCount == 0
                    && faintTextCellCount == 0
            }

            var hasDimmedMenuSiblingStyle: Bool {
                textCellCount > 0
                    && faintTextCellCount > 0
                    && faintTextCellCount < textCellCount
            }

            var hasInstructionStyle: Bool {
                guard textCellCount > 0 else { return false }
                let faintThreshold = max(1, textCellCount / 2)
                return faintTextCellCount >= faintThreshold
            }
        }

        let index: Int
        let text: String
        let selected: Bool
        let firstNonBlankColumn: Int?
        let lastNonBlankColumn: Int?
        let styleSummary: StyleSummary?

        init(
            index: Int,
            text: String,
            selected: Bool,
            firstNonBlankColumn: Int? = nil,
            lastNonBlankColumn: Int? = nil,
            styleSummary: StyleSummary? = nil
        ) {
            self.index = index
            self.text = text
            self.selected = selected
            self.firstNonBlankColumn = firstNonBlankColumn
            self.lastNonBlankColumn = lastNonBlankColumn
            self.styleSummary = styleSummary
        }

        var hasExplicitSelectionStyle: Bool {
            selected || (styleSummary?.hasExplicitSelectionStyle == true)
        }

        var hasForegroundSelectionStyle: Bool {
            styleSummary?.hasForegroundSelectionStyle == true
        }

        var hasUndimmedMenuSelectionStyle: Bool {
            styleSummary?.hasUndimmedMenuSelectionStyle == true
        }

        var hasDimmedMenuSiblingStyle: Bool {
            styleSummary?.hasDimmedMenuSiblingStyle == true
        }

        var hasInstructionStyle: Bool {
            styleSummary?.hasInstructionStyle == true
        }
    }

    let columns: Int
    let rows: Int
    let cursor: Cursor?
    let lines: [Line]

    init(columns: Int, rows: Int, cursor: Cursor?, lines: [Line]) {
        self.columns = columns
        self.rows = rows
        self.cursor = cursor
        self.lines = lines
    }

    init?(json: String) {
        guard !json.isEmpty,
              let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(Self.self, from: data) else {
            return nil
        }

        self = decoded
    }
}

struct PenggieNativeInteractionLine: Identifiable, Equatable {
    let screenLineIndex: Int
    let text: String
    let isSelected: Bool

    var id: String {
        "screen-\(screenLineIndex)-\(text.hashValue)"
    }
}

enum PenggieNativeInteractionProjection {
    static func rows(fromVisibleText visibleText: String, limit: Int = 10) -> [String] {
        let lines = visibleText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Array(lines.suffix(limit))
    }

    static func rows(
        from snapshot: PenggieTerminalScreenSnapshot?,
        currentInput: String,
        minimumScreenLineIndex: Int? = nil,
        excludingRowsUnchangedFrom previousSnapshot: PenggieTerminalScreenSnapshot? = nil
    ) -> [PenggieNativeInteractionLine] {
        guard let snapshot else { return [] }

        let sortedLines = snapshot.lines.sorted { $0.index < $1.index }
        let lines = filteredLines(
            sortedLines,
            minimumScreenLineIndex: currentInput.isEmpty ? minimumScreenLineIndex : nil,
            excludingRowsUnchangedFrom: previousSnapshot
        )
        guard !lines.isEmpty else { return [] }

        if !currentInput.isEmpty {
            guard let anchorIndex = inputAnchorIndex(
                in: lines,
                cursorY: snapshot.cursor?.y,
                currentInput: currentInput
            ) else {
                return []
            }

            guard let menuStartIndex = currentInputMenuStartIndex(
                in: lines,
                anchorIndex: anchorIndex,
                currentInput: currentInput
            ) else {
                return []
            }

            if let selectedIndex = selectedLineIndex(
                in: lines,
                startingAt: menuStartIndex,
                allowForegroundSelection: true,
                requiresContinuationMenuStructure: false
            ) {
                let selectedRows = selectedRegionRows(
                    in: lines,
                    selectedIndex: selectedIndex,
                    lowerBound: menuStartIndex
                )

                if containsCurrentInputSuggestion(selectedRows, currentInput: currentInput) {
                    return currentInputSuggestionRows(selectedRows, currentInput: currentInput)
                }
            }

            return rowsAfterInputAnchor(
                in: lines,
                menuStartIndex: menuStartIndex,
                currentInput: currentInput
            )
        }

        if let selectedIndex = selectedLineIndex(
            in: lines,
            startingAt: lines.startIndex,
            allowForegroundSelection: false,
            requiresContinuationMenuStructure: true
        ) {
            return selectedRegionRows(
                in: lines,
                selectedIndex: selectedIndex,
                lowerBound: lines.startIndex
            )
        }

        return []
    }

    private static func filteredLines(
        _ lines: [PenggieTerminalScreenSnapshot.Line],
        minimumScreenLineIndex: Int?,
        excludingRowsUnchangedFrom previousSnapshot: PenggieTerminalScreenSnapshot?
    ) -> [PenggieTerminalScreenSnapshot.Line] {
        let previousTextByIndex = previousSnapshot.map {
            Dictionary(uniqueKeysWithValues: $0.lines.map { ($0.index, $0.text) })
        } ?? [:]

        return lines.filter { line in
            if let minimumScreenLineIndex, line.index < minimumScreenLineIndex {
                return false
            }

            return previousTextByIndex[line.index] != line.text
        }
    }

    private static func selectedLineIndex(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        startingAt startIndex: Int,
        allowForegroundSelection: Bool,
        requiresContinuationMenuStructure: Bool
    ) -> Int? {
        guard lines.indices.contains(startIndex) else { return nil }

        if let explicitIndex = lines.indices.reversed().first(where: { index in
            guard index >= startIndex else { return false }
            let line = lines[index]
            guard !line.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return false
            }

            if line.hasExplicitSelectionStyle {
                return !requiresContinuationMenuStructure ||
                    hasContinuationMenuStructure(
                        in: lines,
                        selectedIndex: index,
                        lowerBound: startIndex
                    )
            }

            guard allowForegroundSelection && line.hasForegroundSelectionStyle else {
                return false
            }

            return !requiresContinuationMenuStructure ||
                hasContinuationMenuStructure(
                    in: lines,
                    selectedIndex: index,
                    lowerBound: startIndex
                )
        }) {
            return explicitIndex
        }

        return undimmedMenuSelectionLineIndex(
            in: lines,
            startingAt: startIndex,
            requiresContinuationMenuStructure: requiresContinuationMenuStructure
        )
    }

    private static func undimmedMenuSelectionLineIndex(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        startingAt startIndex: Int,
        requiresContinuationMenuStructure: Bool
    ) -> Int? {
        lines.indices.reversed().first { index in
            guard index >= startIndex else { return false }
            let line = lines[index]
            guard !line.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  line.hasUndimmedMenuSelectionStyle else {
                return false
            }

            guard hasDimmedSiblingInContiguousRegion(
                lines,
                around: index,
                lowerBound: startIndex
            ) else {
                return false
            }

            return !requiresContinuationMenuStructure ||
                hasContinuationMenuStructure(
                    in: lines,
                    selectedIndex: index,
                    lowerBound: startIndex
                )
        }
    }

    private static func hasContinuationMenuStructure(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        selectedIndex: Int,
        lowerBound: Int
    ) -> Bool {
        let bounds = contiguousRegionBounds(
            in: lines,
            around: selectedIndex,
            lowerBound: lowerBound
        )

        return hasSeparatedHeadingBeforeRegion(
            in: lines,
            regionStart: bounds.start,
            lowerBound: lowerBound
        ) || hasSeparatedTrailingPromptAfterRegion(
            in: lines,
            regionEnd: bounds.end
        )
    }

    private static func hasDimmedSiblingInContiguousRegion(
        _ lines: [PenggieTerminalScreenSnapshot.Line],
        around index: Int,
        lowerBound: Int
    ) -> Bool {
        let bounds = contiguousRegionBounds(
            in: lines,
            around: index,
            lowerBound: lowerBound
        )

        return lines[bounds.start...bounds.end].contains { sibling in
            sibling.index != lines[index].index && sibling.hasDimmedMenuSiblingStyle
        }
    }

    private static func contiguousRegionBounds(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        around index: Int,
        lowerBound: Int
    ) -> (start: Int, end: Int) {
        var start = index
        while start > max(lines.startIndex, lowerBound),
              !lines[start - 1].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            start -= 1
        }

        var end = index
        while end + 1 < lines.endIndex,
              !lines[end + 1].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            end += 1
        }

        return (start, end)
    }

    private static func hasSeparatedHeadingBeforeRegion(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        regionStart: Int,
        lowerBound: Int
    ) -> Bool {
        guard regionStart - 2 >= max(lines.startIndex, lowerBound) else {
            return false
        }

        let separator = lines[regionStart - 1]
        let heading = lines[regionStart - 2]

        guard separator.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !heading.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        return heading.styleSummary?.boldTextCellCount ?? 0 > 0
    }

    private static func hasSeparatedTrailingPromptAfterRegion(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        regionEnd: Int
    ) -> Bool {
        guard regionEnd + 2 < lines.endIndex else {
            return false
        }

        let separator = lines[regionEnd + 1]
        let prompt = lines[regionEnd + 2]

        guard separator.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !prompt.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        return prompt.styleSummary?.hasInstructionStyle == true
    }

    private static func selectedRegionRows(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        selectedIndex: Int,
        lowerBound: Int
    ) -> [PenggieNativeInteractionLine] {
        var start = selectedIndex
        while start > max(lines.startIndex, lowerBound),
              !lines[start - 1].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            start -= 1
        }

        var end = selectedIndex
        while end + 1 < lines.endIndex,
              !lines[end + 1].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            end += 1
        }

        if end + 2 < lines.endIndex,
           lines[end + 1].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !lines[end + 2].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            end += 1
            while end + 1 < lines.endIndex,
                  !lines[end + 1].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                end += 1
            }
        }

        let selectedScreenLineIndex = lines[selectedIndex].index
        return lines[start...end].map {
            screenLine($0, selectedScreenLineIndex: selectedScreenLineIndex)
        }
    }

    private static func inputAnchorIndex(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        cursorY: Int?,
        currentInput: String
    ) -> Int? {
        if let cursorY {
            return lines.indices
                .filter { abs(lines[$0].index - cursorY) <= 3 }
                .sorted { lhs, rhs in
                    let lhsDistance = abs(lines[lhs].index - cursorY)
                    let rhsDistance = abs(lines[rhs].index - cursorY)
                    if lhsDistance == rhsDistance {
                        return lines[lhs].index > lines[rhs].index
                    }

                    return lhsDistance < rhsDistance
                }
                .first { isInputAnchor(lines[$0].text, currentInput: currentInput) }
        }

        return lines.indices.last { isInputAnchor(lines[$0].text, currentInput: currentInput) }
    }

    private static func rowsAfterInputAnchor(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        menuStartIndex: Int,
        currentInput: String
    ) -> [PenggieNativeInteractionLine] {
        var selectedScreenLineIndex: Int?
        if let selectedIndex = selectedLineIndex(
            in: lines,
            startingAt: menuStartIndex,
            allowForegroundSelection: true,
            requiresContinuationMenuStructure: false
        ) {
            selectedScreenLineIndex = lines[selectedIndex].index
        }

        var rows: [PenggieNativeInteractionLine] = []
        for line in lines[menuStartIndex...] {
            if line.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if rows.isEmpty {
                    continue
                }

                break
            }

            rows.append(screenLine(line, selectedScreenLineIndex: selectedScreenLineIndex))
        }

        guard containsCurrentInputSuggestion(rows, currentInput: currentInput) else {
            return []
        }

        return currentInputSuggestionRows(rows, currentInput: currentInput)
    }

    private static func currentInputMenuStartIndex(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        anchorIndex: Int,
        currentInput: String
    ) -> Int? {
        guard anchorIndex + 1 < lines.endIndex else { return nil }

        for index in lines.indices[(anchorIndex + 1)...] {
            let trimmed = lines[index].text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                continue
            }

            return trimmed.hasPrefix(currentInput) ? index : nil
        }

        return nil
    }

    private static func currentInputSuggestionRows(
        _ rows: [PenggieNativeInteractionLine],
        currentInput: String
    ) -> [PenggieNativeInteractionLine] {
        guard let startIndex = rows.firstIndex(where: {
            $0.text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(currentInput)
        }) else {
            return []
        }

        var result: [PenggieNativeInteractionLine] = []
        for row in rows[startIndex...] {
            let trimmed = row.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix(currentInput) else {
                break
            }

            result.append(row)
        }

        return result
    }

    private static func containsCurrentInputSuggestion(
        _ rows: [PenggieNativeInteractionLine],
        currentInput: String
    ) -> Bool {
        rows.contains {
            $0.text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(currentInput)
        }
    }

    private static func screenLine(
        _ line: PenggieTerminalScreenSnapshot.Line,
        selectedScreenLineIndex: Int?
    ) -> PenggieNativeInteractionLine {
        PenggieNativeInteractionLine(
            screenLineIndex: line.index,
            text: line.text.trimmingCharacters(in: .whitespacesAndNewlines),
            isSelected: selectedScreenLineIndex == line.index
        )
    }

    private static func isInputAnchor(_ text: String, currentInput: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if trimmed == currentInput { return true }
        guard trimmed.hasSuffix(currentInput) else { return false }

        let prefix = trimmed.dropLast(currentInput.count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let alphanumerics = CharacterSet.alphanumerics
        return prefix.unicodeScalars.allSatisfy { scalar in
            !alphanumerics.contains(scalar)
        }
    }
}
