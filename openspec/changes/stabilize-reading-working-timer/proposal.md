## Why

Reading currently shows a weak `Working... 0s` state that can remain static while Codex is still running. This makes a submitted prompt look stuck because Penggie is treating terminal-projected working text as the primary waiting indicator instead of owning a stable Reading turn timer.

## What Changes

- Make the active Reading response header (`Working... Ns`) driven by Penggie turn metadata and a local UI clock.
- Keep Codex terminal output as the source of truth for response content, tool/activity detail rows, native slash suggestions, and Raw Terminal.
- Hide or demote Codex-projected transient working text from the primary Reading flow so it cannot suppress or freeze the local timer.
- Freeze completed responses as `Worked for Ns` using Codex-provided duration when available, with local duration as fallback.
- Avoid per-second full transcript re-blockization; timer updates must be lightweight and scoped to active-turn display state.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `reading-chat-ui`: Active response waiting/progress state becomes a stable Reading UI behavior with local timing and no dependency on Codex TUI repaint cadence.

## Impact

- Affected code should stay within Reading transcript/store/presentation and active-session UI rendering.
- Expected files include `PenggieReadingTranscript.swift`, `PenggieSessionModel.swift`, `PenggieRootView.swift`, and focused tests.
- Ghostty PTY routing, Raw Terminal rendering, native slash overlay extraction/selection, composer IME behavior, and Codex launch semantics must remain unchanged.
