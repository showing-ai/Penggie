import Foundation
import Testing
@testable import PenggieCore

@Suite
struct PenggieNativeInteractionProjectionTests {
    @Test
    func parsesScreenModelJSON() throws {
        let json = """
        {
          "columns": 80,
          "rows": 24,
          "cursor": { "x": 4, "y": 8, "visible": true },
          "lines": [
            { "index": 8, "text": "› /m", "selected": false, "firstNonBlankColumn": 0, "lastNonBlankColumn": 3, "styleSummary": null },
            { "index": 10, "text": "  /model     choose model", "selected": true, "firstNonBlankColumn": 2, "lastNonBlankColumn": 25, "styleSummary": null }
          ]
        }
        """

        let snapshot = try #require(PenggieTerminalScreenSnapshot(json: json))
        #expect(snapshot.columns == 80)
        #expect(snapshot.cursor?.y == 8)
        #expect(snapshot.lines[1].text.contains("/model"))
    }

    @Test
    func extractsFilteredSuggestionsAfterCurrentInputAnchor() {
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 80,
            rows: 24,
            cursor: .init(x: 4, y: 8, visible: true),
            lines: [
                .init(index: 8, text: "› /m", selected: false),
                .init(index: 9, text: "", selected: false),
                .init(index: 10, text: "  /model     choose what model and reasoning effort to use", selected: true),
                .init(index: 11, text: "  /memories  configure memory use and generation", selected: false),
                .init(index: 12, text: "  /mention   mention a file", selected: false),
                .init(index: 13, text: "  /mcp       list configured MCP tools", selected: false),
                .init(index: 14, text: "  /quit      exit", selected: false)
            ]
        )

        let rows = PenggieNativeInteractionProjection.rows(from: snapshot, currentInput: "/m")

        #expect(rows.map(\.text) == [
            "/model     choose what model and reasoning effort to use",
            "/memories  configure memory use and generation",
            "/mention   mention a file",
            "/mcp       list configured MCP tools"
        ])
        #expect(rows.first?.isSelected == true)
    }

    @Test
    func extractsContinuationMenuAroundSelectedModel() {
        let headingStyle = style(text: "Select Model and Effort", bold: 23)
        let snapshot = PenggieTerminalScreenSnapshot(
            columns: 120,
            rows: 32,
            cursor: nil,
            lines: [
                .init(index: 2, text: "  Select Model and Effort", selected: false, styleSummary: headingStyle),
                .init(index: 3, text: "", selected: false),
                .init(index: 4, text: "  1. gpt-5.5 (current)", selected: false),
                .init(index: 5, text: "› 2. gpt-5.4", selected: true),
                .init(index: 6, text: "  3. gpt-5.4-mini", selected: false),
                .init(index: 7, text: "", selected: false),
                .init(index: 8, text: "  Press enter to confirm or esc to go back", selected: false, styleSummary: style(text: "  Press enter to confirm or esc to go back", faint: 40))
            ]
        )

        let rows = PenggieNativeInteractionProjection.rows(from: snapshot, currentInput: "")

        #expect(rows.map(\.text) == [
            "1. gpt-5.5 (current)",
            "› 2. gpt-5.4",
            "3. gpt-5.4-mini",
            "",
            "Press enter to confirm or esc to go back"
        ])
        #expect(rows[1].isSelected == true)
    }

    @Test
    func visibleTextProjectionKeepsTailRowsWithoutLocalCommandKnowledge() {
        let visibleText = """
        banner

        › /m

          /model     choose model
          /memories  configure memories
        """

        #expect(PenggieNativeInteractionProjection.rows(fromVisibleText: visibleText) == [
            "banner",
            "› /m",
            "/model     choose model",
            "/memories  configure memories"
        ])
    }

    @Test
    func detectsContinuationMenusFromVisibleRows() {
        #expect(PenggieNativeInteractionProjection.containsContinuationMenu([
            "Select Model and Effort",
            "› 1. gpt-5.5",
            "  2. gpt-5.4",
            "Press enter to confirm or esc to go back"
        ]))

        #expect(!PenggieNativeInteractionProjection.containsContinuationMenu([
            "› /m",
            "/model choose model",
            "/memories configure memory"
        ]))
    }

    private func style(
        text: String,
        selected: Int = 0,
        selectedText: Int = 0,
        bold: Int = 0,
        faint: Int = 0,
        inverse: Int = 0,
        background: Int = 0,
        foreground: Int = 0
    ) -> PenggieTerminalScreenSnapshot.Line.StyleSummary {
        .init(
            textCellCount: text.count,
            selectedCellCount: selected,
            selectedTextCellCount: selectedText,
            boldTextCellCount: bold,
            faintTextCellCount: faint,
            inverseTextCellCount: inverse,
            backgroundTextCellCount: background,
            foregroundTextCellCount: foreground
        )
    }
}
