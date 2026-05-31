# Agent Terminal Display Fixtures

These fixtures document Penggie Reading's terminal-display pipeline:

`Ghostty styled cells -> Terminal frame normalizer -> Agent adapter -> Display AST -> Reading snapshot`

Each fixture directory may contain these files:

- `ansi.txt`: raw PTY or ANSI bytes captured before terminal parsing.
- `ghostty-screen.json`: raw Ghostty screen model or styled rows.
- `terminal-styled-snapshot.json`: normalized `TerminalStyledSnapshot` input.
- `raw-text.txt`: visible terminal projection used by current tests.
- `display-ast.json`: expected `DisplayDocument` snapshot.
- `reading-snapshot.json`: expected Reading display segments.
- `screenshot.png`: visual reference only, not authoritative unless a test explicitly uses it.

Missing files mean that layer is not under test for that fixture. They do not mean the layer is unavailable.

Rules for adding fixtures:

- Keep Codex/Ghostty as the source of truth for slash, model, selection, and Raw Terminal state.
- Do not turn fixture data into local slash commands, model lists, or selected-index state.
- Prefer visible text as the primary signal, layout/cell width as the second signal, and style only as a hint.
- Low-confidence cases must preserve visible content with a raw or preformatted fallback.
- Add negative fixtures for historical slash text, inline slash text, and indented slash text.

## Current Coverage

| Area | Current fixtures | Status |
| --- | --- | --- |
| Markdown/prose | `markdown-prose` | Covered for ordinary prose and Reading snapshot. |
| Slash negative | `slash-negative` | Covered for terminal-looking slash text that must not become an active overlay. |
| CJK/table/box drawing | `table-box-cjk` | Covered with raw text, Ghostty screen, Display AST, and Reading snapshot. |
| CJK prose + table + code | `cjk-table-code` | Covered for mixed CJK prose, terminal-sensitive table output, and code-fence text that must preserve visible evidence. |
| Theme/style rows | `theme-style` | Covered with styled screen and Reading snapshot. |
| Warning/status/tool rows | `warning-status-tools` | Covered for warning and status style preservation. |
| Tool-heavy hierarchy | `tool-heavy-warning-hierarchy` | Covered for repeated activity/tool/status rows, warning rows, and final answer text that must remain visible. |
| Long sessions | `long-session-stable` | Covered for completed answer text followed by later status/prompt-ready output without polluting stable turns. |
| Low-confidence fallback | `low-confidence-fallback` | Covered for intentionally weak semantic classification that must preserve raw/preformatted terminal evidence. |
| Approval prompt | `approval-prompt` | Covered at Display AST layer. Missing Reading snapshot and low-confidence fallback variant. |

## Remaining Coverage Gaps

- Warning/status: add explicit prevention for footer, model line, active input row, and transient status rows becoming assistant answer content.
- Approval/permission display: add Reading snapshot coverage to ensure prompts remain visible but are not sealed as assistant answer content.

## Productize UI/UX Task Coverage

`productize-ui-ux-contract` task `5.4` requires Display AST fixture coverage for CJK prose, CJK tables, box drawing, code blocks, warnings, tool-heavy output, low-confidence classification, and long transcripts. The required fixture set is:

- `cjk-table-code`: CJK prose, table output, box drawing, and code-fence text.
- `table-box-cjk`: CJK table and terminal cell-width preservation from raw text and Ghostty screen model.
- `warning-status-tools`: warning, activity, tool event, status, and final answer preservation.
- `tool-heavy-warning-hierarchy`: tool-heavy output with repeated progress rows and final answer hierarchy.
- `low-confidence-fallback`: fallback classification that keeps visible terminal evidence.
- `long-session-stable`: long-session stability pressure with completed output and later status/prompt-ready rows.

These fixtures are snapshot-tested by `PenggieDisplayFixtureTests` against Display AST output. Reading visual breadth, footer pollution prevention, and traceable fallback presentation remain covered by later tasks.

## Review Rule

When Display AST classification is uncertain, the expected result should preserve
the visible terminal evidence with raw or preformatted fallback. Do not invent
Markdown structure just to make Reading look cleaner.
