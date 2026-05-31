import Testing
@testable import PenggieCore

@Suite
struct PenggieDisplayTranscriptReconcilerTests {
    @Test
    func sealedTurnsStayStableWhenLaterProjectionContainsHistory() {
        var reconciler = DisplayTranscriptReconciler()

        reconciler.submitPrompt("今天伦敦天气怎么样?", id: "prompt.london")
        reconciler.updateActiveTurn(from: document([
            block(id: "answer.london", kind: .paragraph, text: "今天伦敦大致是晴到多云，白天最高约 22°C。")
        ]))
        reconciler.sealActiveTurn()

        reconciler.submitPrompt("那巴黎呢?", id: "prompt.paris")
        reconciler.updateActiveTurn(from: document([
            block(id: "stale.history", kind: .paragraph, text: "被改写的伦敦答案"),
            block(id: "echo.paris", kind: .userPrompt, role: .user, text: "› 那巴黎呢?"),
            block(id: "answer.paris", kind: .paragraph, text: "巴黎今天温和。")
        ]))

        #expect(visibleText(from: reconciler.displayDocument) == [
            "今天伦敦天气怎么样?",
            "今天伦敦大致是晴到多云，白天最高约 22°C。",
            "那巴黎呢?",
            "巴黎今天温和。"
        ])
    }

    @Test
    func submittedPromptEchoIsNotDuplicatedIntoAssistantOutput() {
        var reconciler = DisplayTranscriptReconciler()

        reconciler.submitPrompt("解释一下量子力学", id: "prompt.quantum")
        reconciler.updateActiveTurn(from: document([
            block(id: "echo.quantum", kind: .userPrompt, role: .user, text: "> 解释一下量子力学"),
            block(id: "answer.quantum", kind: .paragraph, text: "量子力学描述微观尺度的物理规律。")
        ]))

        #expect(visibleText(from: reconciler.displayDocument) == [
            "解释一下量子力学",
            "量子力学描述微观尺度的物理规律。"
        ])
    }

    @Test
    func activeTurnMergesViewportOverlapWithoutDuplicatingRows() {
        var reconciler = DisplayTranscriptReconciler()

        reconciler.submitPrompt("对比伦敦和巴黎", id: "prompt.compare")
        reconciler.updateActiveTurn(from: document([
            block(id: "answer.1", kind: .paragraph, text: "伦敦更像全球化职业平台。"),
            block(id: "answer.2", kind: .paragraph, text: "巴黎更像审美和生活方式中心。")
        ]))
        reconciler.updateActiveTurn(from: document([
            block(id: "answer.2.repaint", kind: .paragraph, text: "巴黎更像审美和生活方式中心。"),
            block(id: "answer.3", kind: .paragraph, text: "如果是第一次欧洲旅行，巴黎更标志性。")
        ]))

        #expect(visibleText(from: reconciler.displayDocument) == [
            "对比伦敦和巴黎",
            "伦敦更像全球化职业平台。",
            "巴黎更像审美和生活方式中心。",
            "如果是第一次欧洲旅行，巴黎更标志性。"
        ])
    }

    @Test
    func nativeOverlayBlocksNeverEnterSealedTranscript() {
        var reconciler = DisplayTranscriptReconciler()

        reconciler.submitPrompt("打开命令菜单", id: "prompt.slash")
        reconciler.updateActiveTurn(from: document([
            block(id: "overlay.slash", kind: .overlay, text: "/model choose what model to use"),
            block(id: "answer.after", kind: .paragraph, text: "这是正文输出。")
        ]))
        reconciler.sealActiveTurn()

        let blocks = reconciler.displayDocument.turns.flatMap(\.blocks)
        #expect(!blocks.contains { $0.kind == .overlay })
        #expect(visibleText(from: reconciler.displayDocument) == [
            "打开命令菜单",
            "这是正文输出。"
        ])
    }

    private func document(_ blocks: [DisplayBlock]) -> DisplayDocument {
        DisplayDocument(
            turns: [
                DisplayTurn(
                    id: "projection.turn",
                    role: .assistant,
                    blocks: blocks,
                    sourceFingerprint: nil,
                    isLive: true,
                    isSealed: false
                )
            ],
            metadata: .init(source: .terminalProjection, terminalColumns: 100, terminalRows: 32)
        )
    }

    private func block(
        id: String,
        kind: DisplayBlock.Kind,
        role: DisplayRole = .assistant,
        text: String
    ) -> DisplayBlock {
        DisplayBlock(
            id: id,
            kind: kind,
            role: role,
            spans: [.init(kind: .text, text: text)],
            sourceRange: nil,
            sourceFingerprint: text,
            confidence: .init(level: .heuristic, score: 0.86),
            ruleHits: [],
            isLive: true,
            isSealed: false,
            renderHints: .init(),
            fallback: nil
        )
    }

    private func visibleText(from document: DisplayDocument) -> [String] {
        document.turns
            .flatMap(\.blocks)
            .map { $0.spans.map(\.text).joined() }
    }
}
