## Why

Penggie v0.1 needs to turn the validated ShowCLI/Ghostty PoC kernel into a narrow but complete macOS product experience. The core technology is already proven; this change defines the product boundary, Reading chat UI, and same-session Raw Terminal fallback needed for the first usable Penggie app.

## What Changes

- Introduce a Penggie-branded macOS app shell with Penggie app name, icon, menu, window title, start screen, top bar, and productized error states.
- Support only one local Codex-backed session in v0.1.
- Provide a Codex-only start/connect flow with a single `Start with Codex` entry.
- Make Reading a full chat UI: empty-state prompt, central composer, transcript projection, send button, and native slash overlay.
- Keep Codex CLI as the source of truth for slash commands, model selection, command suggestions, and selected menu rows.
- Provide Raw Terminal as a fallback view over the same Ghostty PTY/session.
- Define `New Chat` as restarting the same-window single Codex session.
- Define `Close Session` as ending the active Codex session and returning to the Penggie start screen.
- Exclude Ghostty and ShowCLI product shell elements from user-visible UI.

## Capabilities

### New Capabilities

- `penggie-app-shell`: Penggie-branded app lifecycle, start screen, top bar, and productized session states.
- `codex-single-session`: Single local Codex session launch, failure, exit, close, and new-chat behavior.
- `reading-chat-ui`: Reading as the default chat UI backed by the real Codex CLI PTY and native overlay projection.
- `raw-terminal-fallback`: Raw Terminal fallback view over the same Codex PTY/session.

### Modified Capabilities

- None.

## Impact

- Affected product modules: new Penggie macOS app shell, session state controller, Reading chat surface, composer, native interaction overlay, Raw Terminal fallback.
- Affected reference code: migrate and rename selected files from `PenggieReferencePackage/source/showcli-reading-native/`.
- Affected terminal integration: expose only minimal Ghostty substrate APIs for PTY send/key events, screen text reads, screen model JSON reads, process state, and raw surface hosting.
- Explicit non-impact: no multi-agent support, no multi-session manager, no local slash command list, no semantic parser, no local model selector, no Ghostty product shell.
