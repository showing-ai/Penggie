import Foundation

enum PenggieInteractionCommand: Equatable {
    case tab
    case enter
    case escape
    case arrowUp
    case arrowDown
    case arrowLeft
    case arrowRight
    case backspace
    case delete
}

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
            let backgroundCellCount: Int
            let backgroundOnlyCellCount: Int
            let foregroundCellCount: Int

            init(
                textCellCount: Int,
                selectedCellCount: Int,
                selectedTextCellCount: Int,
                boldTextCellCount: Int,
                faintTextCellCount: Int,
                inverseTextCellCount: Int,
                backgroundTextCellCount: Int,
                foregroundTextCellCount: Int,
                backgroundCellCount: Int? = nil,
                backgroundOnlyCellCount: Int? = nil,
                foregroundCellCount: Int? = nil
            ) {
                self.textCellCount = textCellCount
                self.selectedCellCount = selectedCellCount
                self.selectedTextCellCount = selectedTextCellCount
                self.boldTextCellCount = boldTextCellCount
                self.faintTextCellCount = faintTextCellCount
                self.inverseTextCellCount = inverseTextCellCount
                self.backgroundTextCellCount = backgroundTextCellCount
                self.foregroundTextCellCount = foregroundTextCellCount
                self.backgroundCellCount = backgroundCellCount ?? backgroundTextCellCount
                self.backgroundOnlyCellCount = backgroundOnlyCellCount ?? max(0, self.backgroundCellCount - backgroundTextCellCount)
                self.foregroundCellCount = foregroundCellCount ?? foregroundTextCellCount
            }

            private enum CodingKeys: String, CodingKey {
                case textCellCount
                case selectedCellCount
                case selectedTextCellCount
                case boldTextCellCount
                case faintTextCellCount
                case inverseTextCellCount
                case backgroundTextCellCount
                case foregroundTextCellCount
                case backgroundCellCount
                case backgroundOnlyCellCount
                case foregroundCellCount
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.init(
                    textCellCount: try container.decode(Int.self, forKey: .textCellCount),
                    selectedCellCount: try container.decodeIfPresent(Int.self, forKey: .selectedCellCount) ?? 0,
                    selectedTextCellCount: try container.decodeIfPresent(Int.self, forKey: .selectedTextCellCount) ?? 0,
                    boldTextCellCount: try container.decode(Int.self, forKey: .boldTextCellCount),
                    faintTextCellCount: try container.decode(Int.self, forKey: .faintTextCellCount),
                    inverseTextCellCount: try container.decode(Int.self, forKey: .inverseTextCellCount),
                    backgroundTextCellCount: try container.decode(Int.self, forKey: .backgroundTextCellCount),
                    foregroundTextCellCount: try container.decode(Int.self, forKey: .foregroundTextCellCount),
                    backgroundCellCount: try container.decodeIfPresent(Int.self, forKey: .backgroundCellCount),
                    backgroundOnlyCellCount: try container.decodeIfPresent(Int.self, forKey: .backgroundOnlyCellCount),
                    foregroundCellCount: try container.decodeIfPresent(Int.self, forKey: .foregroundCellCount)
                )
            }

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
                    || backgroundCellCount >= selectedRowThreshold
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
        let terminalTextSelected: Bool
        let firstNonBlankColumn: Int?
        let lastNonBlankColumn: Int?
        let styleSummary: StyleSummary?
        let styleRuns: [StyleRun]

        init(
            index: Int,
            text: String,
            selected: Bool,
            firstNonBlankColumn: Int? = nil,
            lastNonBlankColumn: Int? = nil,
            styleSummary: StyleSummary? = nil,
            styleRuns: [StyleRun] = []
        ) {
            self.index = index
            self.text = text
            self.terminalTextSelected = selected
            self.firstNonBlankColumn = firstNonBlankColumn
            self.lastNonBlankColumn = lastNonBlankColumn
            self.styleSummary = styleSummary
            self.styleRuns = styleRuns
        }

        var selected: Bool {
            terminalTextSelected
        }

        var hasExplicitSelectionStyle: Bool {
            styleSummary?.hasExplicitSelectionStyle == true
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

        private enum CodingKeys: String, CodingKey {
            case index
            case text
            case selected
            case terminalTextSelected
            case firstNonBlankColumn
            case lastNonBlankColumn
            case styleSummary
            case styleRuns
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.index = try container.decode(Int.self, forKey: .index)
            self.text = try container.decode(String.self, forKey: .text)
            self.terminalTextSelected = try container.decodeIfPresent(Bool.self, forKey: .terminalTextSelected)
                ?? container.decodeIfPresent(Bool.self, forKey: .selected)
                ?? false
            self.firstNonBlankColumn = try container.decodeIfPresent(Int.self, forKey: .firstNonBlankColumn)
            self.lastNonBlankColumn = try container.decodeIfPresent(Int.self, forKey: .lastNonBlankColumn)
            self.styleSummary = try container.decodeIfPresent(StyleSummary.self, forKey: .styleSummary)
            self.styleRuns = try container.decodeIfPresent([StyleRun].self, forKey: .styleRuns) ?? []
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(index, forKey: .index)
            try container.encode(text, forKey: .text)
            try container.encode(terminalTextSelected, forKey: .terminalTextSelected)
            try container.encodeIfPresent(firstNonBlankColumn, forKey: .firstNonBlankColumn)
            try container.encodeIfPresent(lastNonBlankColumn, forKey: .lastNonBlankColumn)
            try container.encodeIfPresent(styleSummary, forKey: .styleSummary)
            if !styleRuns.isEmpty {
                try container.encode(styleRuns, forKey: .styleRuns)
            }
        }

        struct StyleRun: Codable, Equatable {
            struct Color: Codable, Equatable {
                let kind: String
                let value: String?
            }

            let startColumn: Int
            let endColumn: Int
            let foreground: Color?
            let background: Color?
            let bold: Bool
            let faint: Bool
            let inverse: Bool
            let textCellCount: Int
            let backgroundCellCount: Int
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

struct PenggieTerminalFrame: Equatable {
    let id: Int
    let observedAt: Date
    let visibleText: String
    let screenText: String
    let screenModelJSON: String?
    let snapshot: PenggieTerminalScreenSnapshot?
    let processExited: Bool

    var columns: Int? { snapshot?.columns }
    var rows: Int? { snapshot?.rows }
    var cursor: PenggieTerminalScreenSnapshot.Cursor? { snapshot?.cursor }

    init(
        id: Int,
        observedAt: Date,
        visibleText: String,
        screenText: String,
        screenModelJSON: String?,
        processExited: Bool
    ) {
        self.id = id
        self.observedAt = observedAt
        self.visibleText = visibleText
        self.screenText = screenText
        self.screenModelJSON = screenModelJSON
        self.snapshot = screenModelJSON.flatMap(PenggieTerminalScreenSnapshot.init(json:))
        self.processExited = processExited
    }
}

enum PenggieTerminalInteractionSurfaceKind: String, Equatable {
    case transcript
    case startup
    case slashSuggestions
    case slashContinuation
    case resumePicker
    case modelPicker
    case effortPicker
    case modalChoice
    case approvalPrompt
    case permissionPrompt
    case pager
    case opaqueTerminal
}

struct PenggieTerminalScreenZone: Equatable {
    enum Kind: String, Equatable {
        case header
        case transcript
        case activeInput
        case keyboardSelectableList
        case modalChoice
        case statusActivity
        case footerHelp
        case pagerViewport
        case opaqueTerminal
    }

    let kind: Kind
    let lineRange: ClosedRange<Int>
}

enum PenggieTerminalOwnedSelectionSource: String, Equatable {
    case visibleMarker
    case screenModelMarker
    case explicitSelectedCells
    case inverseStyle
    case foregroundStyle
    case cursorRow
    case contiguousRegion
    case unknown
}

enum PenggieTerminalOwnedSelectionState: Equatable {
    case none(evidence: [String] = [])
    case ambiguous(evidence: [String])
    case single(rowID: String, source: PenggieTerminalOwnedSelectionSource, evidence: [String])

    var isSingle: Bool {
        if case .single = self { return true }
        return false
    }

    var confirmableRowID: String? {
        guard case let .single(rowID, _, _) = self else { return nil }
        return rowID
    }
}

enum PenggieTerminalInputDecision: Equatable {
    case handled
    case blocked(String)
    case unhandled

    var consumesEvent: Bool {
        switch self {
        case .handled, .blocked:
            return true
        case .unhandled:
            return false
        }
    }
}

enum PenggieTerminalSurfaceStatusCopy {
    static let syncingSelection = "Syncing selection; use ↑/↓ to refresh the selected row."
}

enum PenggieTerminalSurfaceCandidateAccessibility {
    static func value(
        isSelected: Bool,
        isConfirmable: Bool,
        surfaceIsSyncing: Bool
    ) -> String {
        var parts = [
            isSelected ? "Selected" : "Not selected",
            isConfirmable ? "Confirmable" : "Unavailable"
        ]

        if surfaceIsSyncing {
            parts.append("Selection syncing")
        }

        return parts.joined(separator: ", ")
    }

    static func hint(
        isSelected: Bool,
        isConfirmable: Bool,
        surfaceIsSyncing: Bool
    ) -> String {
        if surfaceIsSyncing {
            return "Selection is syncing with the terminal. Use arrow keys and wait for the selected row to refresh before confirming."
        }

        if isSelected && isConfirmable {
            return "Press Enter to confirm the terminal selected row."
        }

        if !isConfirmable {
            return "This terminal row is not currently available for confirmation."
        }

        return "Use arrow keys to move the terminal-owned selection."
    }
}

enum PenggieTerminalInputPolicy {
    static func commandDecision(
        _ command: PenggieInteractionCommand,
        surface: PenggieTerminalInteractionSurface?
    ) -> PenggieTerminalInputDecision {
        guard command == .enter, let surface else { return .unhandled }

        return surface.hasFreshConfirmableSelection
            ? .unhandled
            : .blocked("\(surface.kind.rawValue) confirmation requires one fresh terminal-owned selected row.")
    }

    static func resumePickerCommandDecision(
        _ command: PenggieInteractionCommand,
        projection: PenggieCodexResumePickerProjection
    ) -> PenggieTerminalInputDecision {
        guard command == .enter else { return .unhandled }

        return projection.selectionState.isSingle
            ? .unhandled
            : .blocked("Resume picker confirmation requires one fresh terminal-owned selected row.")
    }
}

enum PenggieTerminalSurfaceFreshness: String, Equatable {
    case fresh
    case waitingForTerminalFrame
    case stale
}

struct PenggieTerminalFrameContentSignature: Equatable {
    let visibleText: String
    let screenText: String
    let screenModelJSON: String?
    let processExited: Bool

    init(frame: PenggieTerminalFrame) {
        self.visibleText = frame.visibleText
        self.screenText = frame.screenText
        self.screenModelJSON = frame.screenModelJSON
        self.processExited = frame.processExited
    }
}

enum PenggieTerminalSurfaceFreshnessGate {
    static func resolve(
        pendingBaseline: PenggieTerminalFrameContentSignature?,
        previousSurface: PenggieTerminalInteractionSurface?,
        currentSurface: PenggieTerminalInteractionSurface?,
        currentSignature: PenggieTerminalFrameContentSignature
    ) -> (surface: PenggieTerminalInteractionSurface?, pendingBaseline: PenggieTerminalFrameContentSignature?) {
        guard let pendingBaseline else {
            return (currentSurface, nil)
        }

        guard currentSignature != pendingBaseline else {
            let waitingSurface = previousSurface ?? currentSurface
            return (waitingSurface?.withFreshness(.waitingForTerminalFrame), pendingBaseline)
        }

        return (currentSurface, nil)
    }
}

enum PenggieTerminalSelectionConfidence: String, Equatable {
    case reliable
    case low
    case ambiguous
}

struct PenggieTerminalInteractionCandidate: Equatable, Identifiable {
    let id: String
    let sourceLineIndex: Int
    let text: String
    let isConfirmable: Bool
    let metadata: [String: String]

    init(
        id: String,
        sourceLineIndex: Int,
        text: String,
        isConfirmable: Bool,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.sourceLineIndex = sourceLineIndex
        self.text = text
        self.isConfirmable = isConfirmable
        self.metadata = metadata
    }
}

struct PenggieTerminalInteractionCandidateViewport: Equatable {
    let candidates: [PenggieTerminalInteractionCandidate]
    let hasLeadingOverflow: Bool
    let hasTrailingOverflow: Bool

    static func derive(
        candidates: [PenggieTerminalInteractionCandidate],
        selectedRowID: String?,
        maxVisibleCount: Int
    ) -> Self {
        guard !candidates.isEmpty else {
            return Self(candidates: [], hasLeadingOverflow: false, hasTrailingOverflow: false)
        }

        let visibleCount = max(1, maxVisibleCount)
        guard candidates.count > visibleCount else {
            return Self(candidates: candidates, hasLeadingOverflow: false, hasTrailingOverflow: false)
        }

        let selectedIndex = selectedRowID.flatMap { selectedRowID in
            candidates.firstIndex { $0.id == selectedRowID }
        }
        let startIndex: Int
        if let selectedIndex {
            let contextBeforeSelected = max(0, visibleCount - 2)
            startIndex = min(
                max(0, candidates.count - visibleCount),
                max(0, selectedIndex - contextBeforeSelected)
            )
        } else {
            startIndex = 0
        }
        let endIndex = min(candidates.count, startIndex + visibleCount)

        return Self(
            candidates: Array(candidates[startIndex..<endIndex]),
            hasLeadingOverflow: startIndex > 0,
            hasTrailingOverflow: endIndex < candidates.count
        )
    }
}

struct PenggieTerminalInteractionCandidateListGeometry: Equatable {
    let visibleRowCount: Int
    let viewportHeight: Double

    static func derive(
        candidateCount: Int,
        maxVisibleCount: Int,
        rowHeight: Double,
        rowSpacing: Double,
        verticalPadding: Double
    ) -> Self {
        let visibleRowCount = max(0, min(candidateCount, max(1, maxVisibleCount)))
        guard visibleRowCount > 0 else {
            return Self(visibleRowCount: 0, viewportHeight: 0)
        }

        let rowHeights = Double(visibleRowCount) * rowHeight
        let spacing = Double(max(0, visibleRowCount - 1)) * rowSpacing
        let viewportHeight = rowHeights + spacing + (verticalPadding * 2)

        return Self(visibleRowCount: visibleRowCount, viewportHeight: viewportHeight)
    }
}

struct PenggieTerminalInteractionSurface: Equatable, Identifiable {
    let id: String
    let kind: PenggieTerminalInteractionSurfaceKind
    let frameID: Int
    let zones: [PenggieTerminalScreenZone]
    let candidates: [PenggieTerminalInteractionCandidate]
    let selection: PenggieTerminalOwnedSelectionState
    let selectionConfidence: PenggieTerminalSelectionConfidence
    let freshness: PenggieTerminalSurfaceFreshness
    let evidence: [String]
    let metadata: [String: String]

    init(
        id: String,
        kind: PenggieTerminalInteractionSurfaceKind,
        frameID: Int,
        zones: [PenggieTerminalScreenZone],
        candidates: [PenggieTerminalInteractionCandidate],
        selection: PenggieTerminalOwnedSelectionState,
        selectionConfidence: PenggieTerminalSelectionConfidence,
        freshness: PenggieTerminalSurfaceFreshness,
        evidence: [String],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.kind = kind
        self.frameID = frameID
        self.zones = zones
        self.candidates = candidates
        self.selection = selection
        self.selectionConfidence = selectionConfidence
        self.freshness = freshness
        self.evidence = evidence
        self.metadata = metadata
    }

    var hasFreshConfirmableSelection: Bool {
        guard freshness == .fresh,
              let selectedID = selection.confirmableRowID,
              let selectedCandidate = candidates.first(where: { $0.id == selectedID }) else {
            return false
        }

        return selectedCandidate.isConfirmable
    }

    func withFreshness(_ freshness: PenggieTerminalSurfaceFreshness) -> Self {
        Self(
            id: id,
            kind: kind,
            frameID: frameID,
            zones: zones,
            candidates: candidates,
            selection: selection,
            selectionConfidence: selectionConfidence,
            freshness: freshness,
            evidence: evidence,
            metadata: metadata
        )
    }
}

enum PenggieTerminalBehaviorZoner {
    static func classify(
        frame: PenggieTerminalFrame,
        currentInput: String? = nil
    ) -> PenggieTerminalInteractionSurface? {
        if let resume = resumeSurface(from: frame) {
            return resume
        }

        if let modalChoice = modalChoiceSurface(from: frame) {
            return modalChoice
        }

        if let currentInput,
           let slash = slashSurface(from: frame, currentInput: currentInput) {
            return slash
        }

        if let numberedPicker = numberedPickerSurface(from: frame) {
            return numberedPicker
        }

        return nil
    }

    private static func resumeSurface(
        from frame: PenggieTerminalFrame
    ) -> PenggieTerminalInteractionSurface? {
        guard PenggieCodexScreenKind.detect(in: frame.visibleText) == .resumePicker else {
            return nil
        }

        let projection = PenggieCodexResumePickerProjection.parse(
            from: frame.visibleText,
            backingProjection: frame.screenText,
            snapshot: frame.snapshot
        )
        guard !projection.rows.isEmpty else { return nil }

        let candidates = projection.rows.map { row in
            PenggieTerminalInteractionCandidate(
                id: candidateID(
                    region: PenggieTerminalInteractionSurfaceKind.resumePicker.rawValue,
                    lineIndex: row.sourceLineIndex,
                    text: row.title
                ),
                sourceLineIndex: row.sourceLineIndex,
                text: "\(row.age) \(row.title)",
                isConfirmable: true,
                metadata: ["age": row.age, "title": row.title]
            )
        }
        let selection = inferTerminalOwnedSelectionFromFrame(
            frame,
            candidates: candidates,
            markerPredicate: isResumeSelectionMarker,
            candidatePredicate: isResumePickerCandidate,
            rowIDForLine: { line in
                resumeCandidateID(for: line, candidates: candidates)
            },
            allowForegroundStyle: false,
            evidencePrefix: PenggieTerminalInteractionSurfaceKind.resumePicker.rawValue
        )

        let rowIndices = projection.rows.map(\.sourceLineIndex)
        let zones = [
            zone(.header, matching: frame, where: { $0.localizedCaseInsensitiveContains("resume a previous session") }),
            zone(.keyboardSelectableList, covering: rowIndices),
            zone(.footerHelp, matching: frame, where: {
                $0.localizedCaseInsensitiveContains("enter resume") ||
                    $0.localizedCaseInsensitiveContains("esc exit")
            }),
            zone(.pagerViewport, matching: frame, where: {
                resumePagerText(from: $0) != nil
            })
        ].compactMap(\.self)

        var metadata: [String: String] = [:]
        if let filterText = projection.filterText {
            metadata["filter"] = filterText
        }
        if let sortText = projection.sortText {
            metadata["sort"] = sortText
        }
        if let pagerText = terminalLines(from: frame)
            .lazy
            .compactMap({ resumePagerText(from: $0.text) })
            .first {
            metadata["pager"] = pagerText
        }

        return PenggieTerminalInteractionSurface(
            id: "resumePicker:\(frame.id)",
            kind: .resumePicker,
            frameID: frame.id,
            zones: zones,
            candidates: candidates,
            selection: selection,
            selectionConfidence: confidence(for: selection),
            freshness: .fresh,
            evidence: ["screenKind=resumePicker", "frame=\(frame.id)", "rows=\(projection.rows.count)"],
            metadata: metadata
        )
    }

    private static func slashSurface(
        from frame: PenggieTerminalFrame,
        currentInput: String
    ) -> PenggieTerminalInteractionSurface? {
        guard !currentInput.isEmpty else { return nil }

        let snapshot = frame.snapshot ?? syntheticSnapshot(from: frame.visibleText)
        let nativeRows = PenggieNativeInteractionProjection.rows(
            from: snapshot,
            currentInput: currentInput
        )
        guard !nativeRows.isEmpty else { return nil }

        let zoneKind: PenggieTerminalInteractionSurfaceKind =
            PenggieNativeInteractionProjection.containsContinuationMenu(nativeRows.map(\.text))
            ? .slashContinuation
            : .slashSuggestions

        let candidateRows = nativeRows.filter { row in
            let text = stripMarker(row.text)
            return text != currentInput &&
                (text.hasPrefix("/") || isNumberedChoice(text))
        }
        guard !candidateRows.isEmpty else { return nil }

        let candidates = candidateRows.map { row in
            PenggieTerminalInteractionCandidate(
                id: candidateID(
                    region: zoneKind.rawValue,
                    lineIndex: row.screenLineIndex,
                    text: row.text
                ),
                sourceLineIndex: row.screenLineIndex,
                text: row.text,
                isConfirmable: true,
                metadata: [:]
            )
        }
        let selection = inferTerminalOwnedSelection(
            lines: terminalLines(from: frame),
            cursorY: frame.cursor?.y,
            candidates: candidates,
            markerPredicate: hasTerminalSelectionMarker,
            candidatePredicate: { text in
                let candidateText = stripMarker(text)
                return candidateText.hasPrefix("/") || isNumberedChoice(candidateText)
            },
            rowIDForLine: { line in
                candidateID(
                    region: zoneKind.rawValue,
                    lineIndex: line.index,
                    text: line.text.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            },
            markerSource: frame.snapshot == nil ? .visibleMarker : .screenModelMarker,
            evidencePrefix: zoneKind.rawValue
        )

        return PenggieTerminalInteractionSurface(
            id: "\(zoneKind.rawValue):\(frame.id)",
            kind: zoneKind,
            frameID: frame.id,
            zones: [
                zone(.activeInput, matching: frame, where: { $0.contains(currentInput) }),
                zone(.keyboardSelectableList, covering: nativeRows.map(\.screenLineIndex))
            ].compactMap(\.self),
            candidates: candidates,
            selection: selection,
            selectionConfidence: confidence(for: selection),
            freshness: .fresh,
            evidence: ["currentInput=\(currentInput)", "frame=\(frame.id)", "rows=\(nativeRows.count)"]
        )
    }

    private static func numberedPickerSurface(
        from frame: PenggieTerminalFrame
    ) -> PenggieTerminalInteractionSurface? {
        let lines = terminalLines(from: frame)
        guard let header = lines.first(where: { line in
            let lower = line.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return lower.contains("select model") ||
                lower.contains("model and effort") ||
                lower.contains("select reasoning") ||
                lower.contains("reasoning level")
        }) else {
            return nil
        }

        let kind: PenggieTerminalInteractionSurfaceKind = {
            let lower = header.text.lowercased()
            if lower.contains("reasoning") && !lower.contains("model and effort") {
                return .effortPicker
            }
            return .modelPicker
        }()

        let choiceLines = lines.filter { line in
            line.index > header.index && isNumberedChoice(stripMarker(line.text))
        }
        guard choiceLines.count >= 2 else { return nil }

        let candidates = choiceLines.map { line in
            let text = stripMarker(line.text)
            return PenggieTerminalInteractionCandidate(
                id: candidateID(region: kind.rawValue, lineIndex: line.index, text: text),
                sourceLineIndex: line.index,
                text: text,
                isConfirmable: true,
                metadata: ["kind": kind.rawValue]
            )
        }

        let selection = inferTerminalOwnedSelection(
            lines: lines,
            cursorY: frame.cursor?.y,
            candidates: candidates,
            markerPredicate: { text in
                let stripped = stripMarker(text)
                return hasTerminalSelectionMarker(text) && isNumberedChoice(stripped)
            },
            candidatePredicate: { text in
                isNumberedChoice(stripMarker(text))
            },
            rowIDForLine: { line in
                candidateID(region: kind.rawValue, lineIndex: line.index, text: stripMarker(line.text))
            },
            markerSource: frame.snapshot == nil ? .visibleMarker : .screenModelMarker,
            evidencePrefix: kind.rawValue
        )

        return PenggieTerminalInteractionSurface(
            id: "\(kind.rawValue):\(frame.id)",
            kind: kind,
            frameID: frame.id,
            zones: [
                zone(.header, covering: [header.index]),
                zone(.keyboardSelectableList, covering: choiceLines.map(\.index)),
                zone(.footerHelp, matching: frame, where: {
                    $0.localizedCaseInsensitiveContains("press enter") ||
                        $0.localizedCaseInsensitiveContains("esc")
                })
            ].compactMap(\.self),
            candidates: candidates,
            selection: selection,
            selectionConfidence: confidence(for: selection),
            freshness: .fresh,
            evidence: ["\(kind.rawValue)", "frame=\(frame.id)", "rows=\(choiceLines.count)"]
        )
    }

    private static func modalChoiceSurface(
        from frame: PenggieTerminalFrame
    ) -> PenggieTerminalInteractionSurface? {
        let lines = terminalLines(from: frame)
        let normalized = lines.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
        let hasPrompt = normalized.contains { line in
            let lower = line.lowercased()
            return lower.contains("approve") ||
                lower.contains("permission") ||
                lower.contains("allow this") ||
                lower.contains("allow command")
        }
        guard hasPrompt else { return nil }

        let kind: PenggieTerminalInteractionSurfaceKind = normalized.contains { line in
            let lower = line.lowercased()
            return lower.contains("permission") || lower.contains("allow this")
        } ? .permissionPrompt : .approvalPrompt

        let promptLineIndices = Set(lines.filter { line in
            let lower = line.text.lowercased()
            return lower.contains("approve command") ||
                lower.contains("permission") ||
                lower.contains("allow this") ||
                lower.contains("allow command")
        }.map(\.index))

        let choiceLines = lines.filter { line in
            guard !promptLineIndices.contains(line.index) else { return false }
            let text = stripMarker(line.text)
            let lower = text.lowercased()
            return lower.hasPrefix("allow") ||
                lower == "approve" ||
                lower.hasPrefix("deny") ||
                lower.hasPrefix("reject")
        }
        guard !choiceLines.isEmpty else { return nil }

        let candidates = choiceLines.map { line in
            let text = stripMarker(line.text)
            return PenggieTerminalInteractionCandidate(
                id: candidateID(region: kind.rawValue, lineIndex: line.index, text: text),
                sourceLineIndex: line.index,
                text: text,
                isConfirmable: true,
                metadata: [:]
            )
        }

        let selection = inferTerminalOwnedSelection(
            lines: lines,
            cursorY: frame.cursor?.y,
            candidates: candidates,
            markerPredicate: hasTerminalSelectionMarker,
            candidatePredicate: { text in
                let lower = stripMarker(text).lowercased()
                return lower.hasPrefix("allow") ||
                    lower == "approve" ||
                    lower.hasPrefix("deny") ||
                    lower.hasPrefix("reject")
            },
            rowIDForLine: { line in
                candidateID(region: kind.rawValue, lineIndex: line.index, text: stripMarker(line.text))
            },
            markerSource: frame.snapshot == nil ? .visibleMarker : .screenModelMarker,
            evidencePrefix: kind.rawValue
        )

        return PenggieTerminalInteractionSurface(
            id: "\(kind.rawValue):\(frame.id)",
            kind: kind,
            frameID: frame.id,
            zones: [
                zone(.modalChoice, covering: Array(promptLineIndices)),
                zone(.keyboardSelectableList, covering: choiceLines.map(\.index))
            ].compactMap(\.self),
            candidates: candidates,
            selection: selection,
            selectionConfidence: confidence(for: selection),
            freshness: .fresh,
            evidence: ["\(kind.rawValue)", "frame=\(frame.id)", "rows=\(choiceLines.count)"]
        )
    }

    private static func inferTerminalOwnedSelectionFromFrame(
        _ frame: PenggieTerminalFrame,
        candidates: [PenggieTerminalInteractionCandidate],
        markerPredicate: @escaping (String) -> Bool,
        candidatePredicate: @escaping (String) -> Bool,
        rowIDForLine: @escaping (PenggieTerminalScreenSnapshot.Line) -> String,
        allowForegroundStyle: Bool = true,
        evidencePrefix: String
    ) -> PenggieTerminalOwnedSelectionState {
        var missingEvidence: [String] = []

        let visibleSelection = inferTerminalOwnedSelection(
            lines: terminalLines(fromText: frame.visibleText),
            cursorY: nil,
            candidates: candidates,
            markerPredicate: markerPredicate,
            candidatePredicate: candidatePredicate,
            rowIDForLine: rowIDForLine,
            markerSource: .visibleMarker,
            allowExplicitStyle: false,
            allowForegroundStyle: false,
            allowCursor: false,
            evidencePrefix: "\(evidencePrefix).visible"
        )
        switch visibleSelection {
        case .single, .ambiguous:
            return visibleSelection
        case let .none(evidence):
            missingEvidence.append(contentsOf: evidence)
        }

        if let snapshot = frame.snapshot {
            let snapshotSelection = inferTerminalOwnedSelection(
                lines: snapshot.lines,
                cursorY: snapshot.cursor?.visible == true ? snapshot.cursor?.y : nil,
                candidates: candidates,
                markerPredicate: markerPredicate,
                candidatePredicate: candidatePredicate,
                rowIDForLine: rowIDForLine,
                markerSource: .screenModelMarker,
                allowExplicitStyle: true,
                allowForegroundStyle: allowForegroundStyle,
                allowCursor: true,
                evidencePrefix: "\(evidencePrefix).screenModel"
            )
            switch snapshotSelection {
            case .single, .ambiguous:
                return snapshotSelection
            case let .none(evidence):
                missingEvidence.append(contentsOf: evidence)
            }
        }

        if !frame.screenText.isEmpty, frame.screenText != frame.visibleText {
            let screenTextSelection = inferTerminalOwnedSelection(
                lines: terminalLines(fromText: frame.screenText),
                cursorY: nil,
                candidates: candidates,
                markerPredicate: markerPredicate,
                candidatePredicate: candidatePredicate,
                rowIDForLine: rowIDForLine,
                markerSource: .visibleMarker,
                allowExplicitStyle: false,
                allowForegroundStyle: false,
                allowCursor: false,
                evidencePrefix: "\(evidencePrefix).screenText"
            )
            switch screenTextSelection {
            case .single, .ambiguous:
                return screenTextSelection
            case let .none(evidence):
                missingEvidence.append(contentsOf: evidence)
            }
        }

        return .none(evidence: missingEvidence.isEmpty
            ? ["\(evidencePrefix) rows=\(candidates.count), selected=0"]
            : missingEvidence)
    }

    private static func inferTerminalOwnedSelection(
        lines: [PenggieTerminalScreenSnapshot.Line],
        cursorY: Int?,
        candidates: [PenggieTerminalInteractionCandidate],
        markerPredicate: @escaping (String) -> Bool,
        candidatePredicate: @escaping (String) -> Bool,
        rowIDForLine: @escaping (PenggieTerminalScreenSnapshot.Line) -> String,
        markerSource: PenggieTerminalOwnedSelectionSource,
        allowExplicitStyle: Bool = true,
        allowForegroundStyle: Bool = true,
        allowCursor: Bool = true,
        evidencePrefix: String
    ) -> PenggieTerminalOwnedSelectionState {
        let candidateIDs = Set(candidates.map(\.id))
        let candidateLines = lines.filter { line in
            candidatePredicate(line.text) &&
                candidateIDs.contains(rowIDForLine(line))
        }
        guard !candidateLines.isEmpty else {
            return .none(evidence: ["\(evidencePrefix) rows=\(candidates.count), selected=0"])
        }

        let markerLines = candidateLines.filter { markerPredicate($0.text) }
        if markerLines.count == 1 {
            return singleSelectionState(
                line: markerLines[0],
                lines: lines,
                candidatePredicate: candidatePredicate,
                source: markerSource,
                rowIDForLine: rowIDForLine,
                evidencePrefix: evidencePrefix
            )
        }
        if markerLines.count > 1 {
            return .ambiguous(evidence: markerLines.map { "\(evidencePrefix) marker line=\($0.index)" })
        }

        let explicitLines = allowExplicitStyle ? candidateLines.filter(\.hasExplicitSelectionStyle) : []
        if explicitLines.count == 1 {
            return singleSelectionState(
                line: explicitLines[0],
                lines: lines,
                candidatePredicate: candidatePredicate,
                source: .explicitSelectedCells,
                rowIDForLine: rowIDForLine,
                evidencePrefix: evidencePrefix
            )
        }
        if explicitLines.count > 1 {
            return .ambiguous(evidence: explicitLines.map { "\(evidencePrefix) explicit line=\($0.index)" })
        }

        let foregroundLines = allowForegroundStyle ? candidateLines.filter(\.hasForegroundSelectionStyle) : []
        if foregroundLines.count == 1 {
            return singleSelectionState(
                line: foregroundLines[0],
                lines: lines,
                candidatePredicate: candidatePredicate,
                source: .foregroundStyle,
                rowIDForLine: rowIDForLine,
                evidencePrefix: evidencePrefix
            )
        }
        if foregroundLines.count > 1 {
            return .ambiguous(evidence: foregroundLines.map { "\(evidencePrefix) foreground line=\($0.index)" })
        }

        if allowForegroundStyle && candidateLines.contains(where: \.hasDimmedMenuSiblingStyle) {
            let undimmedLines = candidateLines.filter(\.hasUndimmedMenuSelectionStyle)
            if undimmedLines.count == 1 {
                return singleSelectionState(
                    line: undimmedLines[0],
                    lines: lines,
                    candidatePredicate: candidatePredicate,
                    source: .foregroundStyle,
                    rowIDForLine: rowIDForLine,
                    evidencePrefix: evidencePrefix
                )
            }
            if undimmedLines.count > 1 {
                return .ambiguous(evidence: undimmedLines.map { "\(evidencePrefix) undimmed line=\($0.index)" })
            }
        }

        if allowCursor,
           let cursorY,
           let cursorLine = candidateLines.first(where: { $0.index == cursorY }) {
            return singleSelectionState(
                line: cursorLine,
                lines: lines,
                candidatePredicate: candidatePredicate,
                source: .cursorRow,
                rowIDForLine: rowIDForLine,
                evidencePrefix: evidencePrefix
            )
        }

        return .none(evidence: ["\(evidencePrefix) rows=\(candidates.count), selected=0"])
    }

    private static func singleSelectionState(
        line: PenggieTerminalScreenSnapshot.Line,
        lines: [PenggieTerminalScreenSnapshot.Line],
        candidatePredicate: (String) -> Bool,
        source: PenggieTerminalOwnedSelectionSource,
        rowIDForLine: (PenggieTerminalScreenSnapshot.Line) -> String,
        evidencePrefix: String
    ) -> PenggieTerminalOwnedSelectionState {
        let selectedID = rowIDForLine(line)
        var evidence = ["\(evidencePrefix) line=\(line.index)"]
        if let regionEvidence = contiguousCandidateRegionEvidence(
            around: line,
            in: lines,
            candidatePredicate: candidatePredicate,
            evidencePrefix: evidencePrefix
        ) {
            evidence.append(regionEvidence)
        }

        return .single(
            rowID: selectedID,
            source: source,
            evidence: evidence
        )
    }

    private static func terminalLines(
        from frame: PenggieTerminalFrame
    ) -> [PenggieTerminalScreenSnapshot.Line] {
        if let snapshot = frame.snapshot {
            return snapshot.lines
        }

        return terminalLines(fromText: frame.visibleText)
    }

    private static func terminalLines(fromText text: String) -> [PenggieTerminalScreenSnapshot.Line] {
        text.components(separatedBy: .newlines).enumerated().map { index, text in
            PenggieTerminalScreenSnapshot.Line(index: index, text: text, selected: false)
        }
    }

    private static func syntheticSnapshot(from visibleText: String) -> PenggieTerminalScreenSnapshot {
        let lines = visibleText.components(separatedBy: .newlines).enumerated().map { index, text in
            PenggieTerminalScreenSnapshot.Line(index: index, text: text, selected: false)
        }
        return PenggieTerminalScreenSnapshot(
            columns: lines.map { $0.text.count }.max() ?? 0,
            rows: lines.count,
            cursor: nil,
            lines: lines
        )
    }

    private static func zone(
        _ kind: PenggieTerminalScreenZone.Kind,
        matching frame: PenggieTerminalFrame,
        where predicate: (String) -> Bool
    ) -> PenggieTerminalScreenZone? {
        let matchingIndices = terminalLines(from: frame)
            .filter { predicate($0.text.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .map(\.index)
        return zone(kind, covering: matchingIndices)
    }

    private static func zone(
        _ kind: PenggieTerminalScreenZone.Kind,
        covering indices: [Int]
    ) -> PenggieTerminalScreenZone? {
        guard let first = indices.min(), let last = indices.max() else {
            return nil
        }

        return PenggieTerminalScreenZone(kind: kind, lineRange: first...last)
    }

    private static func resumePagerText(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^\d+\s*/\s*\d+\s*[·•]\s*\d+%$"#
        guard trimmed.range(of: pattern, options: .regularExpression) != nil else {
            return nil
        }
        return trimmed
    }

    private static func confidence(
        for selection: PenggieTerminalOwnedSelectionState
    ) -> PenggieTerminalSelectionConfidence {
        switch selection {
        case .single:
            return .reliable
        case .none:
            return .low
        case .ambiguous:
            return .ambiguous
        }
    }

    private static func stripMarker(_ text: String) -> String {
        var candidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if hasTerminalSelectionMarker(candidate) {
            candidate.removeFirst()
        }
        return candidate.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func hasTerminalSelectionMarker(_ text: String) -> Bool {
        let candidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return candidate.hasPrefix("›") || candidate.hasPrefix("❯")
    }

    private static func isResumeSelectionMarker(_ text: String) -> Bool {
        hasTerminalSelectionMarker(text) &&
            isResumePickerCandidate(text)
    }

    private static func isResumePickerCandidate(_ text: String) -> Bool {
        resumeIdentityText(from: text) != nil
    }

    private static func resumeIdentityText(from text: String) -> String? {
        let candidate = stripMarker(text)
        let lowercased = candidate.lowercased()
        if lowercased.contains("resume a previous session") ||
            lowercased.contains("type to search") ||
            lowercased.contains("enter resume") ||
            lowercased.contains("esc exit") ||
            lowercased.contains("filter:") ||
            lowercased.contains("sort:") ||
            Set(candidate).isSubset(of: Set(["-", "─", " "])) {
            return nil
        }

        let agePatterns = [
            #"^\d+\s*(?:mo|[smhdwy])\s+ago\b"#,
            #"^just\s+now\b"#,
            #"^yesterday\b"#,
            #"^today\b"#
        ]
        for pattern in agePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }
            let range = NSRange(candidate.startIndex..<candidate.endIndex, in: candidate)
            guard let match = regex.firstMatch(in: candidate, range: range),
                  let ageRange = Range(match.range, in: candidate) else {
                continue
            }

            let age = String(candidate[ageRange])
            let title = candidate[ageRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { return nil }
            return "\(age) \(title)"
        }

        return nil
    }

    private static func resumeTitleIdentityText(from text: String) -> String? {
        guard let identity = resumeIdentityText(from: text) else { return nil }

        let agePatterns = [
            #"^\d+\s*(?:mo|[smhdwy])\s+ago\b"#,
            #"^just\s+now\b"#,
            #"^yesterday\b"#,
            #"^today\b"#
        ]
        for pattern in agePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }
            let range = NSRange(identity.startIndex..<identity.endIndex, in: identity)
            guard let match = regex.firstMatch(in: identity, range: range),
                  let matchRange = Range(match.range, in: identity) else {
                continue
            }

            let title = identity[matchRange.upperBound...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return title.isEmpty ? nil : title
        }

        return identity
    }

    private static func resumeCandidateID(
        for line: PenggieTerminalScreenSnapshot.Line,
        candidates: [PenggieTerminalInteractionCandidate]
    ) -> String {
        guard let title = resumeTitleIdentityText(from: line.text) else {
            return candidateID(
                region: PenggieTerminalInteractionSurfaceKind.resumePicker.rawValue,
                lineIndex: line.index,
                text: stripMarker(line.text)
            )
        }

        if let exactLineMatch = candidates.first(where: {
            $0.sourceLineIndex == line.index && $0.metadata["title"] == title
        }) {
            return exactLineMatch.id
        }

        if let titleMatch = candidates.first(where: { $0.metadata["title"] == title }) {
            return titleMatch.id
        }

        return candidateID(
            region: PenggieTerminalInteractionSurfaceKind.resumePicker.rawValue,
            lineIndex: line.index,
            text: title
        )
    }

    private static func contiguousCandidateRegionEvidence(
        around selectedLine: PenggieTerminalScreenSnapshot.Line,
        in lines: [PenggieTerminalScreenSnapshot.Line],
        candidatePredicate: (String) -> Bool,
        evidencePrefix: String
    ) -> String? {
        let sortedLines = lines.sorted { $0.index < $1.index }
        guard let selectedOffset = sortedLines.firstIndex(where: { $0.index == selectedLine.index }) else {
            return nil
        }

        var start = selectedOffset
        while start > sortedLines.startIndex,
              candidatePredicate(sortedLines[start - 1].text) {
            start -= 1
        }

        var end = selectedOffset
        while end + 1 < sortedLines.endIndex,
              candidatePredicate(sortedLines[end + 1].text) {
            end += 1
        }

        return "\(evidencePrefix) contiguousRegion=\(sortedLines[start].index)...\(sortedLines[end].index)"
    }

    private static func isNumberedChoice(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).range(
            of: #"^\d+[\.\)]\s+\S"#,
            options: .regularExpression
        ) != nil
    }

    private static func candidateID(region: String, lineIndex: Int, text: String) -> String {
        let fingerprint = text
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        return "\(region):\(lineIndex):\(fingerprint)"
    }
}

struct PenggieNativeInteractionLine: Identifiable, Equatable {
    let screenLineIndex: Int
    let text: String
    let isSelected: Bool

    var id: String {
        "screen-\(screenLineIndex)-\(text.hashValue)"
    }

    static func visibleTextFallback(index: Int, text: String) -> Self {
        .init(screenLineIndex: index, text: text, isSelected: false)
    }
}

struct PenggieTerminalOwnedSelectionRegion: Equatable {
    let selectedLineIndex: Int
    let lines: [PenggieTerminalScreenSnapshot.Line]
}

enum PenggieTerminalOwnedSelectionProjection {
    static func selectedRegion(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        cursorY: Int? = nil,
        markerPredicate: (String) -> Bool,
        candidatePredicate: (String) -> Bool,
        allowForegroundSelection: Bool = true,
        requireUniqueStyleSelection: Bool = true,
        explicitStylePredicate: (PenggieTerminalScreenSnapshot.Line) -> Bool = { $0.hasExplicitSelectionStyle },
        foregroundStylePredicate: (PenggieTerminalScreenSnapshot.Line) -> Bool = { $0.hasForegroundSelectionStyle }
    ) -> PenggieTerminalOwnedSelectionRegion? {
        let sortedLines = lines.sorted { $0.index < $1.index }
        guard !sortedLines.isEmpty else { return nil }

        guard let selectedIndex = selectedLineIndex(
            in: sortedLines,
            cursorY: cursorY,
            markerPredicate: markerPredicate,
            candidatePredicate: candidatePredicate,
            allowForegroundSelection: allowForegroundSelection,
            requireUniqueStyleSelection: requireUniqueStyleSelection,
            explicitStylePredicate: explicitStylePredicate,
            foregroundStylePredicate: foregroundStylePredicate
        ) else {
            return nil
        }

        let bounds = contiguousRegionBounds(in: sortedLines, around: selectedIndex)
        return PenggieTerminalOwnedSelectionRegion(
            selectedLineIndex: sortedLines[selectedIndex].index,
            lines: Array(sortedLines[bounds.start...bounds.end])
        )
    }

    private static func selectedLineIndex(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        cursorY: Int?,
        markerPredicate: (String) -> Bool,
        candidatePredicate: (String) -> Bool,
        allowForegroundSelection: Bool,
        requireUniqueStyleSelection: Bool,
        explicitStylePredicate: (PenggieTerminalScreenSnapshot.Line) -> Bool,
        foregroundStylePredicate: (PenggieTerminalScreenSnapshot.Line) -> Bool
    ) -> Int? {
        let candidateIndices = lines.indices.filter { index in
            candidatePredicate(trimmedText(lines[index]))
        }
        guard !candidateIndices.isEmpty else { return nil }

        let markerIndices = candidateIndices.filter { index in
            markerPredicate(trimmedText(lines[index]))
        }
        if markerIndices.count == 1 {
            return markerIndices[0]
        }

        if let explicitIndex = styleSelectedIndex(
            in: lines,
            candidateIndices: candidateIndices,
            requireUniqueStyleSelection: requireUniqueStyleSelection,
            predicate: explicitStylePredicate
        ) {
            return explicitIndex
        }

        if allowForegroundSelection,
           let foregroundIndex = styleSelectedIndex(
            in: lines,
            candidateIndices: candidateIndices,
            requireUniqueStyleSelection: requireUniqueStyleSelection,
            predicate: foregroundStylePredicate
           ) {
            return foregroundIndex
        }

        if let cursorY,
           let cursorIndex = candidateIndices.first(where: { lines[$0].index == cursorY }) {
            return cursorIndex
        }

        return nil
    }

    private static func styleSelectedIndex(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        candidateIndices: [Int],
        requireUniqueStyleSelection: Bool,
        predicate: (PenggieTerminalScreenSnapshot.Line) -> Bool
    ) -> Int? {
        let styleIndices = candidateIndices.filter { predicate(lines[$0]) }
        if requireUniqueStyleSelection {
            return styleIndices.count == 1 ? styleIndices[0] : nil
        }

        return styleIndices.last
    }

    private static func contiguousRegionBounds(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        around index: Int
    ) -> (start: Int, end: Int) {
        var start = index
        while start > lines.startIndex,
              !trimmedText(lines[start - 1]).isEmpty {
            start -= 1
        }

        var end = index
        while end + 1 < lines.endIndex,
              !trimmedText(lines[end + 1]).isEmpty {
            end += 1
        }

        return (start, end)
    }

    private static func trimmedText(_ line: PenggieTerminalScreenSnapshot.Line) -> String {
        line.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum PenggieNativeInteractionProjection {
    static func containsContinuationMenu(_ rows: [String]) -> Bool {
        let normalizedRows = rows.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if normalizedRows.contains(where: { row in
            row.localizedCaseInsensitiveContains("press enter")
                && row.localizedCaseInsensitiveContains("esc")
        }) {
            return true
        }

        return normalizedRows.contains { row in
            hasTerminalSelectionMarker(row)
        } && normalizedRows.contains { row in
            row.localizedCaseInsensitiveContains("select ")
                || row.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil
        }
    }

    static func rows(
        fromVisibleText visibleText: String,
        currentInput: String,
        limit: Int = 10
    ) -> [String] {
        let lines = visibleText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let anchorIndex = lines.lastIndex(where: {
            isInputAnchor($0, currentInput: currentInput)
        }) else {
            return []
        }

        let following = Array(lines.dropFirst(anchorIndex + 1))
        guard !following.isEmpty else { return [] }

        let suggestions = following
            .prefix(limit)
            .prefix { line in
                line.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(currentInput)
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        return Array(suggestions)
    }

    static func rowsFromVisibleText(
        _ visibleText: String,
        currentInput: String,
        limit: Int = 10
    ) -> [PenggieNativeInteractionLine] {
        rows(fromVisibleText: visibleText, currentInput: currentInput, limit: limit)
            .enumerated()
            .map { index, text in
                .visibleTextFallback(index: index, text: text)
            }
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

        if containsContinuationMenu(lines.map(\.text)),
           let selectedIndex = selectedLineIndex(
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

        if requiresContinuationMenuStructure,
           let markerIndex = continuationSelectionMarkerLineIndex(in: lines, startingAt: startIndex) {
            return markerIndex
        }

        if allowForegroundSelection,
           let markerIndex = slashSelectionMarkerLineIndex(in: lines, startingAt: startIndex) {
            return markerIndex
        }

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

    private static func continuationSelectionMarkerLineIndex(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        startingAt startIndex: Int
    ) -> Int? {
        let markerIndices = lines.indices.filter { index in
            guard index >= startIndex else { return false }
            let trimmed = lines[index].text.trimmingCharacters(in: .whitespacesAndNewlines)
            return isContinuationSelectionMarker(trimmed)
        }

        let structuredMarkerIndices = markerIndices.filter { index in
            hasContinuationMenuStructure(
                in: lines,
                selectedIndex: index,
                lowerBound: startIndex
            )
        }

        if let lastStructuredMarkerIndex = structuredMarkerIndices.last {
            return lastStructuredMarkerIndex
        }

        return markerIndices.count == 1 ? markerIndices[0] : nil
    }

    private static func isContinuationSelectionMarker(_ text: String) -> Bool {
        text.range(
            of: #"^[›❯]\s*\d+[\.\)]\s+\S"#,
            options: .regularExpression
        ) != nil
    }

    private static func slashSelectionMarkerLineIndex(
        in lines: [PenggieTerminalScreenSnapshot.Line],
        startingAt startIndex: Int
    ) -> Int? {
        let markerIndices = lines.indices.filter { index in
            guard index >= startIndex else { return false }
            let trimmed = lines[index].text.trimmingCharacters(in: .whitespacesAndNewlines)
            return isSlashSelectionMarker(trimmed)
        }

        return markerIndices.count == 1 ? markerIndices[0] : markerIndices.last
    }

    private static func isSlashSelectionMarker(_ text: String) -> Bool {
        text.range(
            of: #"^[›❯]\s*/\S+"#,
            options: .regularExpression
        ) != nil
    }

    private static func suggestionComparableText(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isSlashSelectionMarker(trimmed) else { return trimmed }
        return String(trimmed.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func hasTerminalSelectionMarker(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("›") || trimmed.hasPrefix("❯")
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

            return suggestionComparableText(trimmed).hasPrefix(currentInput) ? index : nil
        }

        return nil
    }

    private static func currentInputSuggestionRows(
        _ rows: [PenggieNativeInteractionLine],
        currentInput: String
    ) -> [PenggieNativeInteractionLine] {
        guard let startIndex = rows.firstIndex(where: {
            suggestionComparableText($0.text).hasPrefix(currentInput)
        }) else {
            return []
        }

        var result: [PenggieNativeInteractionLine] = []
        for row in rows[startIndex...] {
            let comparableText = suggestionComparableText(row.text)
            guard comparableText.hasPrefix(currentInput) else {
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
            suggestionComparableText($0.text).hasPrefix(currentInput)
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
