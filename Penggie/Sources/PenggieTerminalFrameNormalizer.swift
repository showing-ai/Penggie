import Foundation

struct TerminalStyledSnapshot: Codable, Equatable, Sendable {
    var columns: Int
    var rows: Int
    var cursor: Cursor?
    var lines: [Line]

    struct Cursor: Codable, Equatable, Sendable {
        var row: Int
        var column: Int
        var isVisible: Bool
    }

    struct Line: Codable, Equatable, Sendable {
        var rowIndex: Int
        var cells: [TerminalStyledCell]
        var isWrapped: Bool

        var visibleText: String {
            cells.map(\.text).joined()
        }

        var displayWidth: Int {
            cells.reduce(0) { $0 + $1.displayWidth }
        }
    }
}

struct TerminalStyledCell: Codable, Equatable, Sendable {
    var column: Int
    var text: String
    var displayWidth: Int
    var style: TerminalCellStyle
}

struct TerminalCellStyle: Codable, Equatable, Sendable {
    var foreground: String?
    var background: String?
    var bold: Bool
    var faint: Bool
    var italic: Bool
    var underline: Bool
    var inverse: Bool
    var selected: Bool

    init(
        foreground: String? = nil,
        background: String? = nil,
        bold: Bool = false,
        faint: Bool = false,
        italic: Bool = false,
        underline: Bool = false,
        inverse: Bool = false,
        selected: Bool = false
    ) {
        self.foreground = foreground
        self.background = background
        self.bold = bold
        self.faint = faint
        self.italic = italic
        self.underline = underline
        self.inverse = inverse
        self.selected = selected
    }
}

struct TerminalRowRuns: Codable, Equatable, Sendable {
    var rowIndex: Int
    var visibleText: String
    var displayWidth: Int
    var isWrapped: Bool
    var runs: [TerminalRowRun]

    static func normalize(line: TerminalStyledSnapshot.Line) -> TerminalRowRuns {
        var runs: [TerminalRowRun] = []
        var currentText = ""
        var currentStyle: TerminalCellStyle?
        var currentStartColumn: Int?
        var currentEndColumn = 0
        var currentDisplayWidth = 0

        func flush() {
            guard let style = currentStyle, let startColumn = currentStartColumn, !currentText.isEmpty else {
                return
            }
            runs.append(
                TerminalRowRun(
                    rowIndex: line.rowIndex,
                    startColumn: startColumn,
                    endColumn: currentEndColumn,
                    text: currentText,
                    displayWidth: currentDisplayWidth,
                    style: style
                )
            )
            currentText = ""
            currentStyle = nil
            currentStartColumn = nil
            currentEndColumn = 0
            currentDisplayWidth = 0
        }

        for cell in line.cells.sorted(by: { $0.column < $1.column }) {
            if currentStyle != cell.style {
                flush()
                currentStyle = cell.style
                currentStartColumn = cell.column
            }
            currentText += cell.text
            currentDisplayWidth += cell.displayWidth
            currentEndColumn = cell.column + cell.displayWidth
        }
        flush()

        return TerminalRowRuns(
            rowIndex: line.rowIndex,
            visibleText: line.visibleText,
            displayWidth: line.displayWidth,
            isWrapped: line.isWrapped,
            runs: runs
        )
    }
}

struct TerminalRowRun: Codable, Equatable, Sendable {
    var rowIndex: Int
    var startColumn: Int
    var endColumn: Int
    var text: String
    var displayWidth: Int
    var style: TerminalCellStyle
}

struct TerminalRowFeatures: Codable, Equatable, Sendable {
    var rowIndex: Int
    var indentColumns: Int
    var isBlank: Bool
    var isWrapped: Bool
    var isSelected: Bool
    var hasBoxDrawing: Bool
    var isTableCandidate: Bool
    var isDividerCandidate: Bool
    var isFenceCandidate: Bool
    var isPromptCandidate: Bool
    var isBulletCandidate: Bool
    var isWarningCandidate: Bool
    var isStatusCandidate: Bool

    static func extract(from rowRuns: TerminalRowRuns) -> TerminalRowFeatures {
        let text = rowRuns.visibleText
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()
        let hasBoxDrawing = trimmed.unicodeScalars.contains { scalar in
            (0x2500...0x257F).contains(Int(scalar.value))
        }
        let pipeCount = trimmed.filter { $0 == "|" }.count
        let isTableCandidate = hasBoxDrawing || pipeCount >= 2
        let isDividerCandidate = trimmed.count >= 3 && trimmed.allSatisfy { character in
            character == "-" || character == "_" || character == "=" || character == "─" || character == "━"
        }
        let isBulletCandidate = Self.isBullet(trimmed)

        return TerminalRowFeatures(
            rowIndex: rowRuns.rowIndex,
            indentColumns: Self.leadingWhitespaceWidth(text),
            isBlank: trimmed.isEmpty,
            isWrapped: rowRuns.isWrapped,
            isSelected: rowRuns.runs.contains { $0.style.selected || $0.style.inverse },
            hasBoxDrawing: hasBoxDrawing,
            isTableCandidate: isTableCandidate,
            isDividerCandidate: isDividerCandidate,
            isFenceCandidate: trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~"),
            isPromptCandidate: trimmed.hasPrefix("> ") || trimmed.hasPrefix("› "),
            isBulletCandidate: isBulletCandidate,
            isWarningCandidate: trimmed.hasPrefix("⚠") || lowercased.contains("warning"),
            isStatusCandidate: Self.isCodexStatusCandidate(lowercased)
        )
    }

    private static func leadingWhitespaceWidth(_ text: String) -> Int {
        var width = 0
        for character in text {
            guard character == " " || character == "\t" else { break }
            width += character == "\t" ? 4 : 1
        }
        return width
    }

    private static func isBullet(_ trimmed: String) -> Bool {
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
            return true
        }
        guard let first = trimmed.first, first.isNumber else {
            return false
        }
        let prefix = trimmed.prefix { $0.isNumber }
        let remainder = trimmed.dropFirst(prefix.count)
        return remainder.hasPrefix(". ") || remainder.hasPrefix(") ")
    }

    private static func isCodexStatusCandidate(_ lowercased: String) -> Bool {
        if lowercased.hasPrefix("working... ") || lowercased.hasPrefix("working (") {
            return true
        }

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
        return Self.isDurationToken(firstToken)
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
