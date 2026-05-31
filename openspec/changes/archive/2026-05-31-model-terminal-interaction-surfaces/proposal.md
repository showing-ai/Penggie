## Why

Penggie currently treats Codex terminal-owned interaction surfaces as separate feature paths: Reading transcript heuristics, native slash overlay, and native resume picker each infer terminal state with local rules. The resume picker 6.8 failure shows this does not scale: Reading can drift from Raw Terminal selection, and confirmation can become unsafe when selection is ambiguous.

This change establishes Terminal as the only interaction state machine. Chat UI may render native projections, but every terminal-owned selection, confirmation, and navigation state must be derived from the same Ghostty/Codex screen facts that Raw Terminal displays.

## What Changes

- Introduce a unified terminal-owned interaction surface model for Codex TUI surfaces such as resume picker, slash suggestions, slash continuation, model/effort pickers, approval prompts, and permission prompts.
- Add frame-bound projection: each Chat UI surface is derived from a single terminal frame containing visible text, screen text, screen model, cursor/style facts, viewport facts, and frame identity.
- Centralize terminal-owned row extraction, selected-row inference, confidence, freshness, and confirmation eligibility.
- Replace Bool-style “has selected row” checks with confidence-aware states: none, ambiguous, or exactly one terminal-owned selected row.
- Route all keyboard interaction for terminal-owned surfaces back through the active Ghostty PTY; Chat UI must not mutate selection locally.
- Gate GUI confirmation/Enter on fresh, reliable, terminal-owned selection; ambiguous confirmation must be consumed or blocked rather than falling through to ordinary text input.
- Preserve rows and visible evidence when confidence is low; do not hide terminal-owned lists or invent a default selected row.
- Add explicit non-goals: no local session/model/command/approval lists, no local selectedIndex, no Raw Terminal split session, no theme/chrome/Display AST refactor.

## Capabilities

### New Capabilities
- `terminal-interaction-surfaces`: Defines the cross-surface contract for classifying terminal-owned interaction surfaces, extracting candidates, inferring terminal-owned selection, gating confirmation, and routing keyboard input.

### Modified Capabilities
- `reading-chat-ui`: Reading must render terminal-owned interaction projections from the unified surface contract and stop owning surface-specific selected state.
- `codex-single-session`: All terminal-owned interactions must preserve the single active Codex/Ghostty PTY as the source of truth and the only input target.
- `raw-terminal-fallback`: Raw Terminal remains the visual reference for terminal-owned interaction state and must stay in parity with Reading projections.

## Impact

- Affected code: `PenggieSessionModel`, `PenggieRootView`, native interaction projection, resume picker projection, key capture/input routing, and projection tests.
- Affected specs: new terminal interaction surface capability plus targeted deltas to Reading, single-session, and Raw Terminal behavior.
- Affected tests: add fixtures for resume, slash continuation, model/effort picker, approval/permission prompts, ambiguous selection, and confirmation blocking.
- No Ghostty substrate patch is expected unless implementation proves the current screen model lacks required terminal facts.
