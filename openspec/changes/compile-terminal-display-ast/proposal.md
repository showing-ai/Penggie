## Why

Reading currently projects Codex terminal output from Ghostty screen text and styled rows. That preserves the real CLI session and slash behavior, but complex terminal-rendered output still loses quality in Reading: tables can misalign, box drawing can be flattened, CJK wide characters can shift, and colored Markdown-ish spans are treated too much like plain text.

The product boundary is still correct: Penggie should keep running the real local Codex CLI in a Ghostty-backed PTY, Raw Terminal must remain the same session, and slash/model UI must remain sourced from the terminal screen model. The missing layer is a display-aware compiler between Ghostty styled cells and Reading UI.

## What Changes

- Introduce a terminal display pipeline that converts Ghostty styled cells into a stable Penggie Display AST.
- Treat the terminal output as Codex's display-state transcript, not as recoverable original Markdown.
- Use visible characters as the primary signal, terminal layout/cell width as the second signal, and ANSI/style attributes only as auxiliary evidence.
- Add adapter rule packs so generic terminal facts are separated from Codex-specific display conventions.
- Render Reading from Display AST blocks instead of relying on a flat transcript text/block model.
- Preserve low-confidence output as raw/preformatted display rather than over-interpreting it.
- Establish multi-layer fixtures for ANSI bytes, Ghostty styled rows, Display AST snapshots, Reading snapshots, and screenshots.

## Capabilities

### Modified Capabilities

- `reading-chat-ui`: Reading transcript extraction becomes display-aware and cell-aware while preserving the real Codex CLI PTY as the interaction source of truth.

## Non-Goals

- Do not replace Codex CLI with SDK, `codex exec --json`, app-server, or a custom agent runtime.
- Do not infer or maintain slash command lists, model lists, or selected indexes locally.
- Do not promise to reconstruct the model's original Markdown source from terminal output.
- Do not make color alone a semantic contract.
- Do not change Raw Terminal fallback semantics or start a second Codex session.
- Do not implement multi-provider UI in this change; the architecture should allow future adapters, but v0.1 remains Codex-first.

## Impact

- Expected design areas: Reading transcript extraction, presentation model, Ghostty screen-model ingestion, native overlay projection boundaries, and test fixtures.
- Expected code areas when implemented later: `PenggieReadingTranscript.swift`, `PenggieNativeInteractionProjection.swift`, Reading renderer views, Ghostty screen-model bridge, and test targets.
- Existing behavior that must remain unchanged: real Codex PTY launch, Raw Terminal same-session fallback, composer IME behavior, slash lifecycle, PTY key routing, and native overlay source-of-truth.
