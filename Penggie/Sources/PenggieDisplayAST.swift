import Foundation

struct DisplayDocument: Codable, Equatable, Sendable {
    var turns: [DisplayTurn]
    var metadata: Metadata

    struct Metadata: Codable, Equatable, Sendable {
        var source: Source
        var terminalColumns: Int?
        var terminalRows: Int?

        enum Source: String, Codable, Equatable, Sendable {
            case terminalProjection
            case semantic
            case mixed
        }
    }
}

struct DisplayTurn: Codable, Equatable, Sendable {
    var id: String
    var role: DisplayRole
    var blocks: [DisplayBlock]
    var sourceFingerprint: String?
    var isLive: Bool
    var isSealed: Bool
}

enum DisplayRole: String, Codable, Equatable, Sendable {
    case user
    case assistant
    case system
    case tool
    case unknown
}

struct DisplayBlock: Codable, Equatable, Sendable {
    var id: String
    var kind: Kind
    var role: DisplayRole
    var spans: [DisplaySpan]
    var sourceRange: DisplaySourceRange?
    var sourceFingerprint: String?
    var confidence: DisplayConfidence
    var ruleHits: [DisplayRuleHit]
    var isLive: Bool
    var isSealed: Bool
    var renderHints: DisplayRenderHints
    var fallback: DisplayFallback?

    enum Kind: String, CaseIterable, Codable, Equatable, Sendable {
        case userPrompt
        case paragraph
        case list
        case listItem
        case codeBlock
        case preformatted
        case table
        case warning
        case status
        case activity
        case toolEvent
        case disclosure
        case overlay
        case divider
        case rawFallback
    }
}

struct DisplaySpan: Codable, Equatable, Sendable {
    var kind: Kind
    var text: String
    var sourceRange: DisplaySourceRange?
    var style: DisplayTerminalStyle?
    var url: String?

    init(
        kind: Kind,
        text: String,
        sourceRange: DisplaySourceRange? = nil,
        style: DisplayTerminalStyle? = nil,
        url: String? = nil
    ) {
        self.kind = kind
        self.text = text
        self.sourceRange = sourceRange
        self.style = style
        self.url = url
    }

    enum Kind: String, CaseIterable, Codable, Equatable, Sendable {
        case text
        case lineBreak
        case softBreak
        case code
        case emphasis
        case strong
        case link
        case path
        case command
        case statusToken
        case terminalStyled
    }
}

struct DisplaySourceRange: Codable, Equatable, Sendable {
    var startRow: Int
    var startColumn: Int
    var endRow: Int
    var endColumn: Int
}

struct DisplayConfidence: Codable, Equatable, Sendable {
    var level: Level
    var score: Double

    enum Level: String, Codable, Equatable, Sendable {
        case hard
        case heuristic
        case fallback
    }
}

struct DisplayRuleHit: Codable, Equatable, Sendable {
    var ruleID: String
    var mode: Mode
    var reason: String

    enum Mode: String, Codable, Equatable, Sendable {
        case hard
        case heuristic
        case fallback
    }
}

struct DisplayRenderHints: Codable, Equatable, Sendable {
    var preserveWhitespace: Bool
    var monospace: Bool
    var horizontalScroll: Bool
    var cellAware: Bool
    var softWrap: Bool

    init(
        preserveWhitespace: Bool = false,
        monospace: Bool = false,
        horizontalScroll: Bool = false,
        cellAware: Bool = false,
        softWrap: Bool = true
    ) {
        self.preserveWhitespace = preserveWhitespace
        self.monospace = monospace
        self.horizontalScroll = horizontalScroll
        self.cellAware = cellAware
        self.softWrap = softWrap
    }
}

struct DisplayFallback: Codable, Equatable, Sendable {
    var code: String
    var message: String
}

struct DisplayTerminalStyle: Codable, Equatable, Sendable {
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
