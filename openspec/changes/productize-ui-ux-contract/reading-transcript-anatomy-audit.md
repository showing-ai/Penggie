# Reading Transcript And Display AST Anatomy Audit

Task: `5.1 Review PenggieReadingTranscript.swift, PenggieDisplayAST.swift, PenggieDisplayASTRenderer.swift, PenggieDisplayRuleEngine.swift, and PenggieDisplayTranscriptReconciler.swift against the Reading transcript anatomy.`

## Reviewed Files

- `Penggie/Sources/PenggieReadingTranscript.swift`
- `Penggie/Sources/PenggieDisplayAST.swift`
- `Penggie/Sources/PenggieDisplayASTRenderer.swift`
- `Penggie/Sources/PenggieDisplayRuleEngine.swift`
- `Penggie/Sources/PenggieDisplayTranscriptReconciler.swift`
- `Tests/PenggieCoreTests/PenggieReadingTranscriptTests.swift`
- `Tests/PenggieCoreTests/PenggieDisplayASTRendererTests.swift`
- `Tests/PenggieCoreTests/PenggieDisplayTranscriptReconcilerTests.swift`
- `Tests/PenggieCoreTests/PenggieDisplayFixtureTests.swift`
- `Tests/PenggieCoreTests/Fixtures/agent-terminal-display/README.md`

## Current Anatomy

### Local Reading Turn Store

`PenggieReadingTurnStore` is still the primary runtime store for local composer turns. `submitPrompt` seals previously completed turns, creates a hard local prompt block, and starts a running turn. `updateActiveTurn` only updates an unsealed turn and returns early while a native terminal-owned interaction is active.

The store protects completed content by:

- finding the latest active prompt echo before reading assistant output,
- stripping completed-output overlap from later terminal projections,
- preserving stable block identity for repeated projections,
- stripping Codex session metadata lines from assistant output,
- inserting local `Working` and `Worked for` blocks outside terminal projection.

Completion is conservative: a turn needs answer content, no active working row, and a completion signal such as Codex idle metadata or `Worked for` before it can be marked completed and eventually sealed.

### Resume Hydration And Legacy Projection

`PenggieReadingResumeHydrator` hydrates historical visible terminal content into Reading blocks before local composer turns exist. It uses `PenggieReadingProjectionModel.blocks`, not Display AST, and combines hydrated blocks before local turn-store blocks.

The legacy projection path still carries prompt-promotion logic, stable-prefix splitting, CJK-aware display line joining, table/preformatted detection, and disclosure grouping.

### Reading Presentation

`PenggieReadingPresentation.visibleBlocks` filters hidden chrome, startup chrome, terminal prompt echo, and native interaction chrome while a terminal-owned surface is active. Turn presentation splits input prompts, work/detail blocks, local work summaries, and answer blocks into visible items.

Disclosure details are driven by output variants:

- `.activity`, `.status`, and `.toolLike` become disclosure/detail candidates.
- `.proseLike` and `.unknown` stay answer-visible.
- `.menu`, `.startup`, and `.prompt` are treated as chrome/tool-sensitive rather than answer text.

### Display AST Model

`PenggieDisplayAST.swift` defines a separate display document model with roles, block kinds, spans, source ranges, confidence, rule hits, render hints, fallback metadata, and terminal style. It has the vocabulary needed for Reading anatomy:

- user prompt,
- paragraph/list/code/preformatted/table,
- warning/status/activity/tool event,
- disclosure,
- overlay,
- divider,
- raw fallback.

The model carries source and confidence metadata, but the runtime Reading path is not fully unified on this model yet.

### Display Rule Engine

`GenericAnsiAdapter` and `CodexAdapter` compile terminal snapshots into `DisplayDocument` values. Current rules intentionally favor preservation over semantic overreach:

- table-like and box-drawing rows become cell-aware preformatted fallback,
- Codex `Working`, `Worked for`, search, searched, and warning rows become heuristic status/activity/tool/warning blocks,
- unmatched rows become `rawFallback` with fallback confidence and preservation render hints.

This satisfies the contract that uncertain display should preserve visible terminal evidence.

### Display AST Renderer

`PenggieDisplayASTRenderer` converts AST blocks to `PenggieReadingDisplaySegment` values. It drops `.overlay` blocks, maps code/preformatted/table or cell-aware/horizontal-scroll blocks to preformatted segments, and maps ordinary/fallback blocks to prose segments.

### Display Transcript Reconciler

`DisplayTranscriptReconciler` is the newer AST-oriented turn reconciler. It creates hard sealed user-prompt turns for local submissions, filters overlay blocks, strips active prompt echoes, strips sealed assistant history overlap, merges active assistant projection updates, and can seal the active assistant turn.

This path encodes several product-grade invariants already, but it is currently parallel to `PenggieReadingTurnStore` rather than the single runtime authority.

## Confirmed Aligned Invariants

- Terminal-owned overlay blocks are excluded from transcript rendering in both the AST renderer and AST reconciler.
- Legacy Reading turn updates are skipped while `nativeInteractionIsActive` is true.
- Submitted local prompts are represented as local prompt blocks instead of relying on terminal echo alone.
- Prompt echoes are stripped before assistant output is appended.
- Sealed/completed assistant content is protected from later terminal projections that still contain scrollback/history.
- Low-confidence/unclassified display has a raw or preformatted fallback path.
- CJK line joining avoids inserting spaces between CJK scalars.
- Box drawing, pipe-heavy tables, and ASCII table shapes have preformatted fallback support.
- Existing fixture coverage includes table/box/CJK, theme/style rows, warning/status/tool rows, approval prompt, long-session stable, CJK/table/code, tool-heavy warning hierarchy, and low-confidence fallback.

## Gaps And Risks

### R1: Two Transcript Pipelines Still Coexist

`PenggieReadingTurnStore` and `DisplayTranscriptReconciler` solve overlapping turn-stability problems with different models. This is acceptable for the 5.1 audit, but follow-up work must avoid fixing the same class of transcript pollution in only one path.

### R2: Display AST Is Preservation-First, Not Fully Semantic

The AST vocabulary is broad, but current rule coverage is still mostly fallback plus a small Codex status/tool subset. Product-grade hierarchy for assistant answers, collapsible details, code blocks, lists, and tool-heavy turns still needs validation and fixture expansion.

### R3: Active Terminal-Owned Surface Exclusion Needs More End-To-End Evidence

The code excludes overlays and native interaction chrome, but approval, permission, slash, model, and resume cases need regression coverage that proves active terminal-owned surfaces do not become sealed assistant transcript content.

### R4: Chrome/Footer/Input Pollution Depends On Heuristics

Metadata, dividers, prompt echoes, startup blocks, tool/status blocks, active input rows, and model/status footer lines are filtered through heuristics. The current audit shows the mechanisms, not full proof across all screen states.

### R5: Completed-Turn Stability Needs Broader Stress Coverage

There is test coverage for overlap, prompt echo, scrollback, later projection, and sealed AST turns. Remaining stress cases include resize, repaint, Raw Terminal switching, process exit, long sessions with tool-heavy output, and subsequent prompt submission after degraded projection.

### R6: Low-Confidence Fallback Traceability Is Not Fully Productized

Display AST carries fallback metadata and rule-hit reasons, but Reading UI does not yet consistently expose fallback reason or traceability in product form.

### R7: Fixture Coverage Exists But Is Not Complete Enough For P0 Acceptance

Fixtures are stronger than before, but `5.4`, `5.5`, `5.6`, and `9.1` still need explicit expansion and acceptance checks for CJK prose, CJK tables, code, warnings, tool-heavy output, low-confidence classification, long transcripts, and transcript pollution prevention.

## Follow-Up Mapping

- `5.2` should validate turn roles across both legacy Reading and Display AST outputs.
- `5.3` should stress completed-turn stability with repaint, resize, later output, Raw Terminal switching, long sessions, process exit, and subsequent submissions.
- `5.4` should expand Display AST fixtures for the remaining terminal-sensitive output classes.
- `5.5` should specifically guard against footers, model/status rows, active input rows, slash/resume/approval surfaces, and transient startup/status UI becoming sealed assistant content.
- `5.6` should productize low-confidence fallback behavior and traceability while preserving Raw Terminal audit availability.

## Result

Task `5.1` is complete as an implementation audit. No application code changes are required by this task. The remaining `5.x` tasks are still required before Reading transcript and Display AST fallback can be considered productized.
