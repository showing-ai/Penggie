## Why

Penggie now has stable Reading, Raw Terminal, native slash overlay, and transcript ownership, but the entry flow still conflates choosing an agent with launching a session. Because an Agent CLI working directory becomes effectively immutable after PTY launch, Penggie needs a productized pre-launch configuration step and a quieter active-session chrome.

## What Changes

- Replace the start screen's immediate provider launch action with a configure-then-start flow:
  - Show Codex as the selected v0.1 agent CLI.
  - Require or restore a session folder before launch.
  - Start the real Codex/Ghostty session only after the user activates `Create with Penggie`.
- Treat the session folder as a launch-time invariant:
  - The folder is chosen before Codex starts.
  - The active session displays the folder as read-only context.
  - Changing folders requires starting a new session.
- Refine active-session chrome:
  - Remove redundant Penggie icon/provider text from the in-window chrome.
  - Keep a minimal destination mode icon aligned with the macOS traffic-light/titlebar region.
  - Keep the mode switch icon-only, accessible, and backed by the existing Reading/Terminal view switch.
- Refine the Reading composer footer:
  - Remove the fake `/ commands` affordance.
  - Slash commands remain triggered by typing `/`.
  - Keep session folder context in the titlebar instead of duplicating it in the composer footer.
- Align Raw Terminal fallback with Penggie's light product surface:
  - Use a Penggie-controlled light Ghostty config for the embedded terminal.
  - Preserve Raw Terminal as the same PTY/session view, not a separate transcript or renderer.
- Do not change Ghostty PTY creation semantics beyond passing the selected working directory.
- Do not change Reading turn ownership, transcript extraction, native slash overlay source-of-truth, Raw Terminal state, or composer IME behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `penggie-app-shell`: start/connect screen and active chrome requirements change to support pre-launch folder selection and minimal titlebar-aligned controls.
- `codex-single-session`: Codex session launch gains a working-directory invariant selected before process start.
- `reading-chat-ui`: composer footer removes fake `/ commands` and duplicated folder context while slash commands remain input-driven.
- `raw-terminal`: Raw Terminal fallback uses a Penggie light terminal theme while preserving same-session behavior.

## Impact

- Primary code impact should stay in `PenggieRootView.swift` and `PenggieSessionModel.swift`.
- Small documentation updates are expected in `DESIGN.md` and OpenSpec specs.
- No changes should be made to `PenggieReadingTurnStore`, Reading blockization, native slash overlay row extraction/selection, Ghostty screen model parsing, Raw Terminal rendering, or PTY key routing.
