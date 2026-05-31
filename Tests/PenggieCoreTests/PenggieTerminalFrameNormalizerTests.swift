import Testing
@testable import PenggieCore

@Suite
struct PenggieTerminalFrameNormalizerTests {
    @Test
    func rowRunsPreserveVisibleTextStyleBoundariesAndCellWidths() {
        let normal = TerminalCellStyle(foreground: "#222222")
        let strong = TerminalCellStyle(foreground: "#222222", bold: true)
        let line = TerminalStyledSnapshot.Line(
            rowIndex: 3,
            cells: [
                .init(column: 0, text: "A", displayWidth: 1, style: normal),
                .init(column: 1, text: "中", displayWidth: 2, style: normal),
                .init(column: 3, text: "B", displayWidth: 1, style: strong),
                .init(column: 4, text: "C", displayWidth: 1, style: strong)
            ],
            isWrapped: false
        )

        let rowRuns = TerminalRowRuns.normalize(line: line)

        #expect(rowRuns.rowIndex == 3)
        #expect(rowRuns.visibleText == "A中BC")
        #expect(rowRuns.displayWidth == 5)
        #expect(rowRuns.runs.map(\.text) == ["A中", "BC"])
        #expect(rowRuns.runs.map(\.displayWidth) == [3, 2])
        #expect(rowRuns.runs[0].startColumn == 0)
        #expect(rowRuns.runs[0].endColumn == 3)
        #expect(rowRuns.runs[1].startColumn == 3)
        #expect(rowRuns.runs[1].endColumn == 5)
        #expect(rowRuns.runs[1].style.bold)
    }

    @Test
    func rowFeaturesDetectTerminalDisplayShapesWithoutSemanticCommitment() {
        let warning = TerminalRowFeatures.extract(from: rowRuns("⚠ Skill descriptions were shortened"))
        let status = TerminalRowFeatures.extract(from: rowRuns("Worked for 24s ›"))
        let box = TerminalRowFeatures.extract(from: rowRuns("┌────┬────┐"))
        let pipe = TerminalRowFeatures.extract(from: rowRuns("| 维度 | 伦敦 | 巴黎 |"))
        let divider = TerminalRowFeatures.extract(from: rowRuns("────────────────"))
        let bullet = TerminalRowFeatures.extract(from: rowRuns("  - Searching the web"))
        let selected = TerminalRowFeatures.extract(
            from: rowRuns("/model", style: .init(inverse: true, selected: true))
        )

        #expect(warning.isWarningCandidate)
        #expect(status.isStatusCandidate)
        #expect(box.hasBoxDrawing)
        #expect(box.isTableCandidate)
        #expect(pipe.isTableCandidate)
        #expect(divider.isDividerCandidate)
        #expect(bullet.isBulletCandidate)
        #expect(bullet.indentColumns == 2)
        #expect(selected.isSelected)
    }

    @Test
    func rowFeaturesDoNotTreatAnswerPhrasesAsStatusCandidates() {
        let proseWorking = TerminalRowFeatures.extract(
            from: rowRuns("Working memory is useful in answers.")
        )
        let proseWorked = TerminalRowFeatures.extract(
            from: rowRuns("Worked for years on this project.")
        )
        let liveEllipsis = TerminalRowFeatures.extract(from: rowRuns("Working... 2s ›"))
        let liveParenthetical = TerminalRowFeatures.extract(
            from: rowRuns("Working (2s • esc to interrupt)")
        )
        let completed = TerminalRowFeatures.extract(from: rowRuns("Worked for 3m ›"))

        #expect(!proseWorking.isStatusCandidate)
        #expect(!proseWorked.isStatusCandidate)
        #expect(liveEllipsis.isStatusCandidate)
        #expect(liveParenthetical.isStatusCandidate)
        #expect(completed.isStatusCandidate)
    }

    @Test
    func snapshotCarriesTerminalDimensionsCursorAndRows() {
        let snapshot = TerminalStyledSnapshot(
            columns: 80,
            rows: 24,
            cursor: .init(row: 10, column: 4, isVisible: true),
            lines: [
                .init(
                    rowIndex: 0,
                    cells: [.init(column: 0, text: ">", displayWidth: 1, style: .init())],
                    isWrapped: false
                )
            ]
        )

        #expect(snapshot.columns == 80)
        #expect(snapshot.rows == 24)
        #expect(snapshot.cursor?.row == 10)
        #expect(snapshot.lines[0].visibleText == ">")
    }

    private func rowRuns(
        _ text: String,
        rowIndex: Int = 0,
        style: TerminalCellStyle = .init()
    ) -> TerminalRowRuns {
        var column = 0
        let cells = text.map { character -> TerminalStyledCell in
            let width = character.unicodeScalars.contains { $0.value >= 0x1100 } ? 2 : 1
            defer { column += width }
            return TerminalStyledCell(
                column: column,
                text: String(character),
                displayWidth: width,
                style: style
            )
        }
        return TerminalRowRuns.normalize(
            line: .init(rowIndex: rowIndex, cells: cells, isWrapped: false)
        )
    }
}
