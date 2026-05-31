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
| Theme/style rows | `theme-style` | Covered with styled screen and Reading snapshot. |
| Warning/status/tool rows | `warning-status-tools` | Covered for warning and status style preservation. |
| Approval prompt | `approval-prompt` | Covered at Display AST layer. Missing Reading snapshot and low-confidence fallback variant. |

## Coverage Gaps For `harden-terminal-ux-qa-foundation`

- Long sessions: add a fixture with completed turns, later output, active prompt readiness, and no duplicate or polluted turns.
- CJK/table/code: add a fixture that combines CJK prose, table or box drawing, and code/preformatted content in one terminal-sensitive output.
- Tool-heavy output: add a fixture with repeated tool/status rows and a final answer hierarchy.
- Warning/status: add explicit prevention for footer, model line, active input row, and transient status rows becoming assistant answer content.
- Low-confidence fallback: add raw/preformatted fallback fixture where semantic classification is intentionally weak.
- Approval/permission display: add Reading snapshot coverage to ensure prompts remain visible but are not sealed as assistant answer content.

## Review Rule

When Display AST classification is uncertain, the expected result should preserve
the visible terminal evidence with raw or preformatted fallback. Do not invent
Markdown structure just to make Reading look cleaner.
