import Foundation

protocol TerminalDisplayAdapter {
    func compile(snapshot: TerminalStyledSnapshot) -> DisplayDocument
}

struct GenericAnsiAdapter: TerminalDisplayAdapter {
    func compile(snapshot: TerminalStyledSnapshot) -> DisplayDocument {
        let rows = DisplayRuleRows(snapshot: snapshot)
        let blocks = DisplayRuleCompiler.compile(rows: rows) { row, features in
            guard !features.isBlank else {
                return nil
            }
            if features.isTableCandidate || features.hasBoxDrawing {
                return .group(.tableShape)
            }
            return .single(.rawVisibleText)
        }

        return DisplayRuleCompiler.document(
            id: "generic.turn.0",
            role: .unknown,
            blocks: blocks,
            snapshot: snapshot
        )
    }
}

struct CodexAdapter: TerminalDisplayAdapter {
    func compile(snapshot: TerminalStyledSnapshot) -> DisplayDocument {
        let rows = DisplayRuleRows(snapshot: snapshot)
        let blocks = DisplayRuleCompiler.compile(rows: rows) { row, features in
            guard !features.isBlank else {
                return nil
            }
            if features.isTableCandidate || features.hasBoxDrawing {
                return .group(.tableShape)
            }
            let text = row.visibleText.trimmingCharacters(in: .whitespacesAndNewlines)
            let lowercased = text.lowercased()

            if Self.isCodexWorkedForStatus(lowercased) {
                return .single(.codexWorkedFor)
            }
            if Self.isCodexWorkingStatus(lowercased) {
                return .single(.codexWorking)
            }
            if lowercased.hasPrefix("searching the web") || lowercased == "searching" {
                return .single(.codexSearchingWeb)
            }
            if lowercased.hasPrefix("searched") {
                return .single(.codexSearched)
            }
            if features.isWarningCandidate || lowercased.contains("skill descriptions were shortened") {
                return .single(.codexWarning)
            }
            return .single(.rawVisibleText)
        }

        return DisplayRuleCompiler.document(
            id: "codex.turn.0",
            role: .assistant,
            blocks: blocks,
            snapshot: snapshot
        )
    }

    private static func isCodexWorkedForStatus(_ lowercased: String) -> Bool {
        let prefix = "worked for "
        guard lowercased.hasPrefix(prefix) else {
            return false
        }

        let remainder = lowercased
            .dropFirst(prefix.count)
            .replacingOccurrences(of: "›", with: "")
            .replacingOccurrences(of: ">", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstToken = remainder.split(separator: " ").first else {
            return false
        }
        return isDurationToken(firstToken)
    }

    private static func isCodexWorkingStatus(_ lowercased: String) -> Bool {
        lowercased.hasPrefix("working... ") || lowercased.hasPrefix("working (")
    }

    private static func isDurationToken(_ token: Substring) -> Bool {
        let digitPrefix = token.prefix { $0.isNumber }
        guard !digitPrefix.isEmpty else {
            return false
        }

        let suffix = token.dropFirst(digitPrefix.count)
        switch String(suffix) {
        case "s", "sec", "secs", "m", "min", "mins", "h", "hr", "hrs":
            return true
        default:
            return false
        }
    }
}

private struct DisplayRuleRows {
    var rows: [(runs: TerminalRowRuns, features: TerminalRowFeatures)]

    init(snapshot: TerminalStyledSnapshot) {
        rows = snapshot.lines.map { line in
            let runs = TerminalRowRuns.normalize(line: line)
            return (runs, TerminalRowFeatures.extract(from: runs))
        }
    }
}

private enum DisplayRuleDecision {
    case single(DisplayRuleProfile)
    case group(DisplayRuleProfile)
}

private enum DisplayRuleProfile {
    case rawVisibleText
    case tableShape
    case codexWorkedFor
    case codexWorking
    case codexSearchingWeb
    case codexSearched
    case codexWarning

    var blockKind: DisplayBlock.Kind {
        switch self {
        case .rawVisibleText:
            return .rawFallback
        case .tableShape:
            return .preformatted
        case .codexWorkedFor:
            return .status
        case .codexWorking:
            return .status
        case .codexSearchingWeb:
            return .activity
        case .codexSearched:
            return .toolEvent
        case .codexWarning:
            return .warning
        }
    }

    var ruleID: String {
        switch self {
        case .rawVisibleText:
            return "generic.raw.visible_text"
        case .tableShape:
            return "generic.preformatted.table_shape"
        case .codexWorkedFor:
            return "codex.status.worked_for"
        case .codexWorking:
            return "codex.status.working"
        case .codexSearchingWeb:
            return "codex.activity.searching_web"
        case .codexSearched:
            return "codex.tool.searched"
        case .codexWarning:
            return "codex.warning.visible_text"
        }
    }

    var confidence: DisplayConfidence {
        switch self {
        case .rawVisibleText, .tableShape:
            return DisplayConfidence(level: .fallback, score: 0.45)
        case .codexWorkedFor, .codexWorking, .codexSearchingWeb, .codexSearched:
            return DisplayConfidence(level: .heuristic, score: 0.86)
        case .codexWarning:
            return DisplayConfidence(level: .heuristic, score: 0.78)
        }
    }

    var ruleMode: DisplayRuleHit.Mode {
        switch confidence.level {
        case .hard:
            return .hard
        case .heuristic:
            return .heuristic
        case .fallback:
            return .fallback
        }
    }

    var renderHints: DisplayRenderHints {
        switch self {
        case .tableShape:
            return DisplayRenderHints(
                preserveWhitespace: true,
                monospace: true,
                horizontalScroll: true,
                cellAware: true,
                softWrap: false
            )
        case .rawVisibleText:
            return DisplayRenderHints(preserveWhitespace: true, monospace: true)
        default:
            return DisplayRenderHints()
        }
    }

    var fallback: DisplayFallback? {
        switch self {
        case .rawVisibleText:
            return DisplayFallback(
                code: "generic.visible_text",
                message: "Preserved visible terminal text without semantic classification."
            )
        case .tableShape:
            return DisplayFallback(
                code: "generic.table_shape",
                message: "Preserved terminal-shaped table or box drawing as cell-aware preformatted text."
            )
        default:
            return nil
        }
    }

    var reason: String {
        switch self {
        case .rawVisibleText:
            return "No high-confidence semantic rule matched; visible text is preserved."
        case .tableShape:
            return "Terminal row shape contains box drawing or table-like separators."
        case .codexWorkedFor:
            return "Codex TUI worked-for status row."
        case .codexWorking:
            return "Codex TUI working status row."
        case .codexSearchingWeb:
            return "Codex TUI web search activity row."
        case .codexSearched:
            return "Codex TUI searched-result tool row."
        case .codexWarning:
            return "Codex TUI warning/status text row."
        }
    }
}

private enum DisplayRuleCompiler {
    typealias Row = (runs: TerminalRowRuns, features: TerminalRowFeatures)
    typealias Decide = (TerminalRowRuns, TerminalRowFeatures) -> DisplayRuleDecision?

    static func compile(rows: DisplayRuleRows, decide: Decide) -> [DisplayBlock] {
        var blocks: [DisplayBlock] = []
        var index = 0

        while index < rows.rows.count {
            let row = rows.rows[index]
            guard let decision = decide(row.runs, row.features) else {
                index += 1
                continue
            }

            switch decision {
            case let .single(profile):
                blocks.append(block(profile: profile, rows: [row.runs], ordinal: blocks.count))
                index += 1
            case let .group(profile):
                var group = [row.runs]
                var end = index + 1
                while end < rows.rows.count {
                    let next = rows.rows[end]
                    guard !next.features.isBlank else {
                        break
                    }
                    guard let nextDecision = decide(next.runs, next.features),
                          case let .group(nextProfile) = nextDecision,
                          nextProfile == profile else {
                        break
                    }
                    group.append(next.runs)
                    end += 1
                }
                blocks.append(block(profile: profile, rows: group, ordinal: blocks.count))
                index = end
            }
        }

        return blocks
    }

    static func document(
        id: String,
        role: DisplayRole,
        blocks: [DisplayBlock],
        snapshot: TerminalStyledSnapshot
    ) -> DisplayDocument {
        let text = blocks.flatMap(\.spans).map(\.text).joined(separator: "\n")
        return DisplayDocument(
            turns: [
                DisplayTurn(
                    id: id,
                    role: role,
                    blocks: blocks,
                    sourceFingerprint: fingerprint(text),
                    isLive: true,
                    isSealed: false
                )
            ],
            metadata: DisplayDocument.Metadata(
                source: .terminalProjection,
                terminalColumns: snapshot.columns,
                terminalRows: snapshot.rows
            )
        )
    }

    private static func block(
        profile: DisplayRuleProfile,
        rows: [TerminalRowRuns],
        ordinal: Int
    ) -> DisplayBlock {
        let text = rows.map(\.visibleText).joined(separator: "\n")
        let sourceRange = sourceRange(rows: rows)
        return DisplayBlock(
            id: "\(profile.ruleID).\(ordinal).\(fingerprint(text))",
            kind: profile.blockKind,
            role: role(for: profile),
            spans: [DisplaySpan(kind: .text, text: text, sourceRange: sourceRange)],
            sourceRange: sourceRange,
            sourceFingerprint: fingerprint(text),
            confidence: profile.confidence,
            ruleHits: [
                DisplayRuleHit(
                    ruleID: profile.ruleID,
                    mode: profile.ruleMode,
                    reason: profile.reason
                )
            ],
            isLive: true,
            isSealed: false,
            renderHints: profile.renderHints,
            fallback: profile.fallback
        )
    }

    private static func role(for profile: DisplayRuleProfile) -> DisplayRole {
        switch profile {
        case .codexSearched:
            return .tool
        case .codexWorkedFor, .codexWorking, .codexSearchingWeb, .codexWarning:
            return .system
        default:
            return .unknown
        }
    }

    private static func sourceRange(rows: [TerminalRowRuns]) -> DisplaySourceRange? {
        guard let first = rows.first, let last = rows.last else {
            return nil
        }
        return DisplaySourceRange(
            startRow: first.rowIndex,
            startColumn: 0,
            endRow: last.rowIndex,
            endColumn: max(last.displayWidth, last.visibleText.count)
        )
    }

    private static func fingerprint(_ text: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }
}
