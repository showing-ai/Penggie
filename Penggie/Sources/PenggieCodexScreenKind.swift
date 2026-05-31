import Foundation

enum PenggieCodexScreenKind: Equatable {
    case unknown
    case chat
    case startupShell
    case codexStartupStatus
    case resumePicker

    var isTerminalOwnedInteraction: Bool {
        switch self {
        case .startupShell, .codexStartupStatus, .resumePicker:
            return true
        case .unknown, .chat:
            return false
        }
    }

    var isLaunchBlockingScreen: Bool {
        switch self {
        case .unknown, .startupShell, .codexStartupStatus:
            return true
        case .chat, .resumePicker:
            return false
        }
    }

    static func detect(in projection: String) -> Self {
        let normalized = projection
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !normalized.isEmpty else { return .unknown }

        if containsResumePicker(in: normalized) {
            return .resumePicker
        }

        if containsStartupShellChrome(in: normalized) {
            return .startupShell
        }

        if containsCodexStartupStatus(in: normalized) {
            return .codexStartupStatus
        }

        return .chat
    }

    static func detect(currentProjection: String, backingProjection: String) -> Self {
        let currentKind = detect(in: currentProjection)
        return currentKind == .unknown ? detect(in: backingProjection) : currentKind
    }

    private static func containsResumePicker(in lines: [String]) -> Bool {
        let hasTitle = lines.contains {
            $0.localizedCaseInsensitiveContains("resume a previous session")
        }
        let hasSearchPrompt = lines.contains {
            $0.localizedCaseInsensitiveContains("type to search")
        }
        let hasFilterOrSort = lines.contains {
            $0.localizedCaseInsensitiveContains("filter:") ||
                $0.localizedCaseInsensitiveContains("sort:")
        }
        let hasResumeShortcut = lines.contains {
            $0.localizedCaseInsensitiveContains("enter resume") &&
                $0.localizedCaseInsensitiveContains("esc exit")
        }
        let hasSessionRow = lines.contains {
            PenggieCodexResumePickerRow.parse($0, sourceLineIndex: 0) != nil
        }

        return hasTitle && (hasSearchPrompt || hasFilterOrSort || hasResumeShortcut || hasSessionRow)
    }

    private static func containsStartupShellChrome(in lines: [String]) -> Bool {
        guard lines.contains(where: { $0.hasPrefix("Last login:") }) else {
            return false
        }

        return lines.allSatisfy { line in
            line.hasPrefix("Last login:") ||
                isShellCommandEcho(line)
        }
    }

    private static func isShellCommandEcho(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasSuffix("% codex") ||
            trimmed.hasSuffix("$ codex") ||
            trimmed.hasSuffix("# codex")
    }

    private static func containsCodexStartupStatus(in lines: [String]) -> Bool {
        lines.contains { line in
            let lowercased = line.lowercased()
            return lowercased.contains("starting mcp servers") ||
                lowercased.contains("esc to interrupt") ||
                (lowercased.hasPrefix("starting ") && lowercased.contains("server"))
        }
    }
}

enum PenggieCodexDisplayReadyTarget: Equatable {
    case reading
    case resumePicker
}

enum PenggieCodexDisplayReadiness {
    static func target(
        screenKind: PenggieCodexScreenKind,
        frame: PenggieTerminalFrame,
        resumePickerProjection: PenggieCodexResumePickerProjection,
        hasObservedCodexScreen: Bool
    ) -> PenggieCodexDisplayReadyTarget? {
        target(
            screenKind: screenKind,
            visibleText: frame.visibleText,
            backingText: frame.screenText,
            resumePickerProjection: resumePickerProjection,
            hasObservedCodexScreen: hasObservedCodexScreen
        )
    }

    static func target(
        screenKind: PenggieCodexScreenKind,
        visibleText: String,
        backingText: String,
        resumePickerProjection: PenggieCodexResumePickerProjection,
        hasObservedCodexScreen: Bool
    ) -> PenggieCodexDisplayReadyTarget? {
        switch screenKind {
        case .resumePicker:
            return resumePickerProjection.rows.isEmpty ? nil : .resumePicker
        case .unknown:
            return hasObservedCodexScreen &&
                !hasMeaningfulText(visibleText) ? .reading : nil
        case .chat:
            return isExplicitReadingReadyProjection(
                visibleText: visibleText,
                backingText: backingText
            ) ? .reading : nil
        case .startupShell, .codexStartupStatus:
            return nil
        }
    }

    private static func isExplicitReadingReadyProjection(
        visibleText: String,
        backingText: String
    ) -> Bool {
        if !hasMeaningfulText(visibleText) {
            return true
        }

        let visibleLines = visibleText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if visibleLines.contains(where: isChatPromptOrTranscriptLine) {
            return true
        }

        guard visibleLines.isEmpty else {
            return false
        }

        return backingText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .contains(where: isChatPromptOrTranscriptLine)
    }

    private static func isChatPromptOrTranscriptLine(_ line: String) -> Bool {
        hasTerminalSelectionMarker(line) &&
            PenggieCodexResumePickerRow.parse(line, sourceLineIndex: 0) == nil
    }

    private static func hasTerminalSelectionMarker(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("›") || trimmed.hasPrefix("❯")
    }

    private static func hasMeaningfulText(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

enum PenggieTerminalScreenModelReadPolicy {
    static func requiresScreenModelJSON(
        visibleText: String,
        screenText: String,
        screenKind: PenggieCodexScreenKind,
        nativeInteractionIsActive: Bool
    ) -> Bool {
        if nativeInteractionIsActive {
            return true
        }

        if screenKind == .resumePicker {
            return true
        }

        let projection = "\(visibleText)\n\(screenText)".lowercased()
        return containsTerminalOwnedSurfaceCue(in: projection)
    }

    private static func containsTerminalOwnedSurfaceCue(in projection: String) -> Bool {
        let cues = [
            "↑/↓ select",
            "↑/↓ browse",
            "enter accept",
            "enter resume",
            "esc cancel",
            "esc exit",
            "allow once",
            "deny",
            "approve command",
            "approve one retry",
            "choose what model",
            "reasoning effort",
            "filter:",
            "sort:"
        ]

        return cues.contains { projection.contains($0) }
    }
}

struct PenggieCodexResumePickerProjection: Equatable {
    var rows: [PenggieCodexResumePickerRow]
    var filterText: String?
    var sortText: String?

    var hasExactlyOneSelectedRow: Bool {
        selectionState.isSingle
    }

    var selectionState: PenggieTerminalOwnedSelectionState {
        let selectedRows = rows.filter(\.isSelected)
        switch selectedRows.count {
        case 0:
            return .none(evidence: ["resume rows=\(rows.count), selected=0"])
        case 1:
            let row = selectedRows[0]
            return .single(
                rowID: row.id,
                source: .unknown,
                evidence: ["resume row line=\(row.sourceLineIndex), age=\(row.age)"]
            )
        default:
            return .ambiguous(
                evidence: selectedRows.map { "line=\($0.sourceLineIndex), age=\($0.age)" }
            )
        }
    }

    static let empty = PenggieCodexResumePickerProjection(
        rows: [],
        filterText: nil,
        sortText: nil
    )

    static func parse(
        from projection: String,
        backingProjection: String? = nil,
        snapshot: PenggieTerminalScreenSnapshot? = nil
    ) -> Self {
        let textProjection = parseTextProjection(from: projection)
        if let snapshot {
            return parse(
                from: snapshot,
                visibleProjection: projection,
                backingProjection: backingProjection
            )
        }

        return PenggieCodexResumePickerProjection(
            rows: selectedResumeRows(
                from: terminalLines(from: projection),
                cursorY: nil
            ) ?? withoutSelection(textProjection.rows),
            filterText: textProjection.filterText,
            sortText: textProjection.sortText
        )
    }

    private static func parseTextProjection(
        from projection: String
    ) -> (rows: [PenggieCodexResumePickerRow], filterText: String?, sortText: String?) {
        var rows: [PenggieCodexResumePickerRow] = []
        var filterText: String?
        var sortText: String?

        for (lineIndex, rawLine) in projection.components(separatedBy: .newlines).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            if let parsedFilter = value(after: "Filter:", before: "Sort:", in: line) {
                filterText = parsedFilter
            }
            if let parsedSort = value(after: "Sort:", before: nil, in: line) {
                sortText = parsedSort
            }

            guard let row = PenggieCodexResumePickerRow.parse(line, sourceLineIndex: lineIndex) else {
                continue
            }
            rows.append(row)
        }

        return (rows, filterText, sortText)
    }

    private static func parse(
        from snapshot: PenggieTerminalScreenSnapshot,
        visibleProjection: String,
        backingProjection: String?
    ) -> Self {
        let visibleTextProjection = parseTextProjection(from: visibleProjection)
        let backingTextProjection = parseTextProjection(from: backingProjection ?? "")
        var filterText: String?
        var sortText: String?

        for line in snapshot.lines.sorted(by: { $0.index < $1.index }) {
            let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            if let parsedFilter = value(after: "Filter:", before: "Sort:", in: text) {
                filterText = parsedFilter
            }
            if let parsedSort = value(after: "Sort:", before: nil, in: text) {
                sortText = parsedSort
            }
        }

        if filterText == nil || sortText == nil {
            filterText = filterText ?? visibleTextProjection.filterText ?? backingTextProjection.filterText
            sortText = sortText ?? visibleTextProjection.sortText ?? backingTextProjection.sortText
        }

        let visibleMarkerRows = selectedResumeRows(
            from: terminalLines(from: visibleProjection),
            cursorY: nil,
            markerSelection: true,
            strongStyleSelection: false
        )
        let snapshotMarkerRows = selectedResumeRows(
            from: snapshot.lines,
            cursorY: nil,
            markerSelection: true,
            strongStyleSelection: false
        )
        let snapshotStrongStyleRows = selectedResumeRows(
            from: snapshot.lines,
            cursorY: nil,
            markerSelection: false,
            strongStyleSelection: true
        )
        let snapshotCursorRows = selectedResumeRows(
            from: snapshot.lines,
            cursorY: snapshot.cursor?.visible == true ? snapshot.cursor?.y : nil,
            markerSelection: false,
            strongStyleSelection: false
        )
        let backingMarkerRows = selectedResumeRows(
            from: terminalLines(from: backingProjection ?? ""),
            cursorY: nil,
            markerSelection: true,
            strongStyleSelection: false
        )
        let fallbackRows = firstNonEmpty(
            withoutSelection(resumeRows(from: snapshot.lines)),
            withoutSelection(visibleTextProjection.rows),
            withoutSelection(backingTextProjection.rows)
        )

        return PenggieCodexResumePickerProjection(
            rows: visibleMarkerRows ??
                snapshotMarkerRows ??
                snapshotStrongStyleRows ??
                snapshotCursorRows ??
                backingMarkerRows ??
                fallbackRows,
            filterText: filterText,
            sortText: sortText
        )
    }

    private static func selectedResumeRows(
        from lines: [PenggieTerminalScreenSnapshot.Line],
        cursorY: Int?,
        markerSelection: Bool = true,
        strongStyleSelection: Bool = true
    ) -> [PenggieCodexResumePickerRow]? {
        guard let region = PenggieTerminalOwnedSelectionProjection.selectedRegion(
            in: lines,
            cursorY: cursorY,
            markerPredicate: markerSelection ? isResumeSelectionMarker : neverResumeSelectionMarker,
            candidatePredicate: isResumePickerRow,
            allowForegroundSelection: false,
            requireUniqueStyleSelection: true,
            explicitStylePredicate: strongStyleSelection ? hasStrongResumeSelectionStyle : neverResumeSelectionStyle,
            foregroundStylePredicate: neverResumeSelectionStyle
        ) else {
            return nil
        }

        let rows = resumeRows(from: region.lines)
        guard rows.contains(where: { $0.sourceLineIndex == region.selectedLineIndex }) else {
            return nil
        }

        return rows.map { row in
            row.withSelection(row.sourceLineIndex == region.selectedLineIndex)
        }
    }

    private static func resumeRows(
        from lines: [PenggieTerminalScreenSnapshot.Line]
    ) -> [PenggieCodexResumePickerRow] {
        lines.sorted { $0.index < $1.index }.compactMap { line in
            let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return PenggieCodexResumePickerRow.parse(text, sourceLineIndex: line.index)
        }
    }

    private static func terminalLines(from projection: String) -> [PenggieTerminalScreenSnapshot.Line] {
        projection.components(separatedBy: .newlines).enumerated().map { index, rawLine in
            PenggieTerminalScreenSnapshot.Line(
                index: index,
                text: rawLine,
                selected: false
            )
        }
    }

    private static func isResumeSelectionMarker(_ text: String) -> Bool {
        PenggieCodexResumePickerRow.parse(text, sourceLineIndex: 0)?.isSelected == true
    }

    private static func neverResumeSelectionMarker(_ text: String) -> Bool {
        false
    }

    private static func isResumePickerRow(_ text: String) -> Bool {
        PenggieCodexResumePickerRow.parse(text, sourceLineIndex: 0) != nil
    }

    private static func withoutSelection(
        _ rows: [PenggieCodexResumePickerRow]
    ) -> [PenggieCodexResumePickerRow] {
        rows.map { $0.withSelection(false) }
    }

    private static func firstNonEmpty(
        _ candidates: [PenggieCodexResumePickerRow]...
    ) -> [PenggieCodexResumePickerRow] {
        candidates.first(where: { !$0.isEmpty }) ?? []
    }

    private static func hasStrongResumeSelectionStyle(_ line: PenggieTerminalScreenSnapshot.Line) -> Bool {
        guard let style = line.styleSummary, style.textCellCount > 0 else {
            return false
        }

        let selectedTextThreshold = max(1, (style.textCellCount + 1) / 2)
        if style.selectedTextCellCount >= selectedTextThreshold {
            return true
        }
        if style.inverseTextCellCount >= selectedTextThreshold {
            return true
        }

        let selectedRowThreshold = max(3, style.textCellCount)
        if style.selectedCellCount >= selectedRowThreshold {
            return true
        }

        let backgroundOnlyThreshold = max(3, style.textCellCount / 2)
        if style.backgroundOnlyCellCount >= backgroundOnlyThreshold {
            return true
        }

        return line.styleRuns.contains { run in
            run.background != nil &&
                run.backgroundCellCount >= max(3, style.textCellCount)
        }
    }

    private static func neverResumeSelectionStyle(_ line: PenggieTerminalScreenSnapshot.Line) -> Bool {
        false
    }

    private static func value(after startMarker: String, before endMarker: String?, in line: String) -> String? {
        guard let startRange = line.range(of: startMarker, options: [.caseInsensitive]) else {
            return nil
        }

        let valueStart = startRange.upperBound
        let valueEnd: String.Index
        if let endMarker,
           let endRange = line.range(of: endMarker, options: [.caseInsensitive], range: valueStart..<line.endIndex) {
            valueEnd = endRange.lowerBound
        } else {
            valueEnd = line.endIndex
        }

        let value = line[valueStart..<valueEnd]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

struct PenggieCodexResumePickerRow: Equatable, Identifiable {
    let sourceLineIndex: Int
    let age: String
    let title: String
    let isSelected: Bool

    var id: String {
        "\(sourceLineIndex)-\(age)-\(title)"
    }

    fileprivate func withSelection(_ selected: Bool) -> Self {
        PenggieCodexResumePickerRow(
            sourceLineIndex: sourceLineIndex,
            age: age,
            title: title,
            isSelected: selected
        )
    }

    fileprivate static func parse(_ line: String, sourceLineIndex: Int) -> Self? {
        guard !isChromeLine(line) else { return nil }

        var candidate = line.trimmingCharacters(in: .whitespacesAndNewlines)
        var isSelected = false

        if Self.hasTerminalSelectionMarker(candidate) {
            isSelected = true
            candidate.removeFirst()
            candidate = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let match = agePrefix(in: candidate) else { return nil }
        let title = candidate[match.titleStart...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        return PenggieCodexResumePickerRow(
            sourceLineIndex: sourceLineIndex,
            age: match.age,
            title: title,
            isSelected: isSelected
        )
    }

    private static func hasTerminalSelectionMarker(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("›") || trimmed.hasPrefix("❯")
    }

    private static func isChromeLine(_ line: String) -> Bool {
        let lowercased = line.lowercased()
        return lowercased.contains("resume a previous session") ||
            lowercased.contains("type to search") ||
            lowercased.contains("enter resume") ||
            lowercased.contains("esc exit") ||
            lowercased.contains("filter:") ||
            lowercased.contains("sort:") ||
            line.unicodeScalars.allSatisfy { chromeDividerScalars.contains($0) }
    }

    private static func agePrefix(in candidate: String) -> (age: String, titleStart: String.Index)? {
        for regex in agePrefixRegexes {
            let range = NSRange(candidate.startIndex..<candidate.endIndex, in: candidate)
            guard let match = regex.firstMatch(in: candidate, range: range),
                  let ageRange = Range(match.range, in: candidate) else {
                continue
            }

            let age = String(candidate[ageRange])
            return (age, ageRange.upperBound)
        }

        return nil
    }

    private static let chromeDividerScalars = CharacterSet(charactersIn: "-─ ")

    private static let agePrefixRegexes: [NSRegularExpression] = [
        #"^\d+\s*(?:mo|[smhdwy])\s+ago\b"#,
        #"^just\s+now\b"#,
        #"^yesterday\b"#,
        #"^today\b"#
    ].map { pattern in
        // Hard-coded patterns should fail at development time, not per polling tick.
        try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }
}
