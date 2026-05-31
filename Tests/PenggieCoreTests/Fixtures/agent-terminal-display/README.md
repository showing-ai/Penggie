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
