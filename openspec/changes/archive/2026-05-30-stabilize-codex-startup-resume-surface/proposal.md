## Why

Penggie currently lets transient Codex terminal states leak into product surfaces during startup and resume. Users can see intermediate native resume picker frames, Raw Terminal TUI frames, and Codex startup text such as MCP server progress before the final Reading or resume state is ready.

This also exposes a resume picker selection mismatch: Raw Terminal shows the real selected row marker, while the native resume picker can render without any highlighted selection.

## What Changes

- Keep the Penggie start surface visible until the next product surface is display-ready.
- Treat Codex startup/status text, including MCP server startup lines, as launch-blocking terminal state rather than Reading chat content.
- Release the startup hold only when a stable Reading empty/chat state or native resume picker rows are ready.
- Keep native resume picker rows visible when projected rows exist; require one reliable selected row only for highlight and Enter confirmation.
- Prefer Codex/Ghostty visible text marker `›` as the resume picker selected source when snapshot parsing is also available.
- Hide inactive Raw Terminal at the AppKit/Ghostty host view layer, not only through SwiftUI opacity.
- Preserve one real Codex CLI process and one Ghostty-backed PTY; do not split Reading and Raw Terminal into separate sessions.
- Do not locally maintain Codex session lists, command lists, or selected indices.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `penggie-app-shell`: startup and resume transition surfaces must not expose transient Codex terminal states.
- `reading-chat-ui`: Reading must only render after Codex is display-ready, and native resume picker rows must remain visible while selected state synchronizes.
- `raw-terminal-fallback`: inactive Raw Terminal must not visually leak during Reading startup/resume transitions.
- `codex-single-session`: startup/resume gating must preserve a single Codex PTY and route interactions to the real session.

## Impact

- Primary code impact is expected in `PenggieSessionModel.swift`, `PenggieCodexScreenKind.swift`, `PenggieRootView.swift`, and `PenggieGhosttySession.swift`.
- Tests should cover Codex startup/status classification, display-ready gating, resume picker selected marker precedence, and inactive Raw Terminal hiding behavior where feasible.
- No changes should be made to Codex CLI process ownership, PTY key routing, local session list storage, native slash command list ownership, or Reading markdown/table rendering.
