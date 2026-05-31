## 1. Establish Display AST Contract

- [x] 1.1 Define `DisplayDocument`, `DisplayTurn`, `DisplayBlock`, `DisplaySpan`, confidence, source range, rule hit, render hint, and fallback metadata.
- [x] 1.2 Define block kinds for paragraph, list, code, preformatted, table, warning, status, activity, tool event, overlay, divider, and raw fallback.
- [x] 1.3 Define span kinds for text, code, emphasis, strong, link, path, command, status token, line breaks, and terminal-styled spans.
- [x] 1.4 Add serialization support for Display AST snapshots used by tests and diagnostics.

## 2. Normalize Terminal Frames

- [x] 2.1 Build a `TerminalStyledSnapshot` model from current Ghostty screen text and styled row data.
- [x] 2.2 Add `TerminalRowRun` normalization that preserves visible text, style runs, cell width, and row/column ranges.
- [x] 2.3 Add `TerminalRowFeatures` extraction for indentation, markers, dividers, boxes, tables, fences, selected rows, warning/status hints, and wrap candidates.
- [x] 2.4 Identify required Ghostty bridge gaps for run/cell-level style and record follow-up integration tasks.

## 3. Add Rule Engine and Codex Rule Pack

- [x] 3.1 Implement a rule engine with hard, heuristic, and fallback rule modes.
- [x] 3.2 Move existing Reading blockizer heuristics into a first Codex display rule pack.
- [x] 3.3 Ensure Codex-specific rules are isolated from generic terminal facts.
- [x] 3.4 Emit confidence, rule hits, source ranges, and fallback reasons for every Display AST node.
- [x] 3.5 Add conservative unknown/generic fallback rules that never hide visible content.

## 4. Reconcile Transcript Projection

- [x] 4.1 Add active vs sealed turn handling so live terminal repaint can update active output without rewriting completed history.
- [x] 4.2 Add prompt echo matching using Penggie-owned submitted composer input.
- [x] 4.3 Add overlap/fingerprint logic for viewport scroll and resize.
- [x] 4.4 Keep native overlay regions outside the sealed Reading transcript flow.

## 5. Render Reading from Display AST

- [x] 5.1 Route Reading renderer through Display AST while preserving current visible behavior.
- [x] 5.2 Add cell-aware/monospace rendering for preformatted, table, box drawing, and CJK-sensitive blocks.
- [x] 5.3 Render warning/status/activity/tool blocks without hiding final answer content.
- [x] 5.4 Keep overlay rendering on the native interaction path and prevent overlay nodes from appearing as transcript content.
- [x] 5.5 Preserve Raw Terminal fallback and same-PTY behavior throughout the renderer migration.

## 6. Build Fixtures and Regression Coverage

- [x] 6.1 Create fixture directory schema for ANSI bytes, Ghostty screen JSON, raw text, Display AST, Reading snapshots, and screenshots.
- [x] 6.2 Add P0 fixtures for Markdown/prose, tables, CJK/Unicode, slash/model, approval, warnings/status, theme/style, and resize/viewport.
- [x] 6.3 Add explicit negative fixtures for historical slash text, inline slash text, and leading-space slash text.
- [x] 6.4 Add AST snapshot tests for `ghostty-screen.json -> display-ast.json`.
- [x] 6.5 Add Reading projection tests for `display-ast.json -> reading-snapshot.json`.
- [x] 6.6 Add visual or screenshot tests for table/CJK alignment and overlay selection.

## 7. Validate and Harden

- [x] 7.1 Verify theme changes do not alter Display AST semantics.
- [x] 7.2 Verify resize does not duplicate or drop transcript content.
- [x] 7.3 Verify real answers are never hidden as chrome/status/menu.
- [x] 7.4 Verify approval prompts and choices remain visible and correct.
- [x] 7.5 Verify slash/model overlay still comes only from the real terminal screen model and no local selected-index state is introduced.
- [x] 7.6 Run existing Swift tests and macOS app build after implementation.
