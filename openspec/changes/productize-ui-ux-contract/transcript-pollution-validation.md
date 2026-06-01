# Transcript Pollution Validation

Task: `5.5 Validate that terminal footers, model/status rows, active input rows, slash/resume/approval surfaces, and transient startup/status UI do not become sealed assistant transcript content.`

## Validation Scope

This task validates the Display AST reconciliation boundary. At this layer, terminal-owned UI is represented as `DisplayBlock.Kind.overlay`; the reconciler must never seal those blocks as assistant transcript content.

This task does not claim that every upstream terminal parser always classifies every future Codex UI row correctly. Parser breadth remains covered by terminal interaction surface fixtures and follow-up fixture expansion tasks.

## Evidence Matrix

| Terminal-owned content | Reconciler evidence | Result |
| --- | --- | --- |
| Terminal footer / model status row | `terminalChromeAndOwnedSurfacesDoNotBecomeSealedAssistantContent` uses `gpt-5.5 high · ~/A-ThinkBig/TestSpace` as `.overlay`. | Filtered before sealing. |
| Active input row | The same test uses `› Write tests for @filename` as `.overlay`. | Filtered before sealing. |
| Slash / model surface | The same test uses `/model choose what model and reasoning effort to use` as `.overlay`. | Filtered before sealing. |
| Resume surface | The same test uses `Resume a previous session` as `.overlay`. | Filtered before sealing. |
| Approval / permission surface | The same test uses `Approve command?` and `Allow once   Deny` as `.overlay`. | Filtered before sealing. |
| Transient startup/status UI | The same test uses `Starting Codex` and `Starting MCP servers (2/3): figma...` as `.overlay`. | Filtered before sealing. |
| Legitimate assistant answer | The same test includes two `.paragraph` blocks around the overlays. | Preserved and sealed in order. |

## Acceptance Notes

- `DisplayTranscriptReconciler.updateActiveTurn(from:)` filters `.overlay` before prompt echo stripping, sealed-history overlap stripping, active turn merge, and sealing.
- `PenggieDisplayASTRenderer` also skips `.overlay`, so both Display AST transcript storage and rendering share the same exclusion invariant.
- Status, warning, activity, and tool-event blocks are not blanket-filtered because they can be legitimate assistant-visible transcript roles; only terminal-owned chrome/surfaces should arrive as `.overlay`.
- Upstream surface classification remains terminal-frame evidence driven. This validation does not introduce local command/model/resume/approval/permission lists or local selected-index state.

## Result

Task `5.5` is complete for the transcript reconciliation boundary: terminal-owned UI represented as overlay cannot become sealed assistant transcript content, while legitimate answer content remains sealed and ordered.
