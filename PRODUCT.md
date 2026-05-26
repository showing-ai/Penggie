# Penggie Product Context

## Register

product

## Product Purpose

Penggie is a focused macOS app shell for working with a real agent CLI. Penggie v0.1 supports Codex only and turns the validated Ghostty PTY kernel into a product-grade Reading experience with Raw Terminal as a fallback view.

Penggie is not a generic terminal, a multi-provider launcher, or a custom agent runtime. Codex remains the source of truth for model state, slash commands, command selection, and TUI behavior.

## Users

Primary users are developers and technical builders on macOS who want the power of Codex CLI without living in a raw terminal all day. They need a calm chat surface for ordinary work, plus a faithful terminal fallback when they need to inspect the underlying session.

## Product Principles

- Penggie first: app name, bundle, menu, window title, icon, state pages, and visible chrome are Penggie-owned.
- Codex only for v0.1: no visible alternate provider paths until they are real.
- One local session: Reading and Raw Terminal are two views of the same Codex PTY.
- Reading is primary: it should feel like a chat/work surface, not a white terminal viewport.
- Raw Terminal is fallback: it exposes the same PTY state and must not restart or fork the session.
- Agent CLI is source of truth: do not clone slash command lists, model lists, or selected indexes locally.
- Native overlay is projection: slash UI reads terminal screen model and styled rows, then renders a Penggie-native view.
- Stability over spectacle: preserve composer IME, PTY routing, transcript history, and slash behavior before visual ambition.

## User Experience Boundaries

- First launch shows a Penggie start state, not a terminal.
- `Create with Penggie` is the only v0.1 launch action after the user chooses a project folder.
- Codex missing, launch failure, and process exit are Penggie product states with retry or recovery paths.
- Active session chrome should feel native to macOS, close to the traffic-light region, and not like a web toolbar.
- The composer is always available in Reading after a session starts.
- Tool calls, working status, and trace details can be collapsed, but the final answer and turn ownership must remain clear.

## Anti-References

- Do not expose ShowCLI or Ghostty product shell copy in user-visible Penggie surfaces.
- Do not make Reading look like a terminal viewport inside a card.
- Do not use nested cards for transcript, composer, and overlay.
- Do not add decorative gradients, blobs, or heavy brand treatment to the work surface.
- Do not add clickable-looking controls that do not perform real actions.
- Do not hide core state behind styling that makes Raw Terminal and Reading feel like separate sessions.

## Voice

Penggie should feel quiet, precise, native, and work-focused. Copy should be short and concrete. Errors should explain what happened and what the user can do next.
