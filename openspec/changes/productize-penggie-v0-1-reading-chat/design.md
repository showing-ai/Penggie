## Context

The ShowCLI/Ghostty PoC already validated the technical kernel: a real Codex CLI running in a Ghostty PTY can power both a Reading UI and a Raw Terminal fallback. It also validated native slash interaction through real PTY input and Ghostty screen model/styled-row projection.

Penggie v0.1 is not a technical demo. It must feel like a focused macOS app even though its functional scope is narrow: Codex only, one local session, Reading chat UI by default, Raw Terminal fallback.

## Goals / Non-Goals

**Goals:**

- Present Penggie, not Ghostty or ShowCLI, as the user-visible app.
- Make Reading the main chat UI: empty-state headline, composer, native slash overlay, and transcript.
- Keep Codex CLI as the source of truth for command suggestions, model menus, selected rows, and slash state.
- Reuse the validated PoC kernel for composer trigger rules, native interaction phases, screen model parsing, focus recovery, and IME-safe placeholder behavior.
- Provide Raw Terminal as a same-session fallback.
- Keep v0.1 to one same-window Codex session.

**Non-Goals:**

- Multi-provider selection beyond Codex.
- Multiple simultaneous sessions, tab management, or true multi-window session management.
- Local slash command tables, semantic parsers, local selected-index state, or copied model lists.
- Ghostty product shell features such as splits, command palette, terminal preferences, update overlay, or Ghostty-branded menus.
- Reworking Reading transcript/blockizer behavior to solve native slash overlay concerns.

## Decisions

### Decision 1: Penggie shell owns product UI; Ghostty remains substrate

Penggie will own bundle metadata, app icon, menus, window title, start screen, top bar, state pages, Reading chat UI, and Raw Terminal toggle. Ghostty is used only for PTY/session/screen-model substrate and raw terminal rendering.

Alternative considered: continue modifying the Ghostty app shell. Rejected because terminal-first lifecycle, menus, command palette, split/tree UI, and Ghostty text would keep leaking into the product.

### Decision 2: v0.1 supports Codex only

The start screen keeps the calm centered onboarding style but shows only `Start with Codex`. Provider cards for Claude, Copilot, local models, or other providers are out of scope.

Alternative considered: show multiple disabled/future provider options. Rejected because it creates unsupported product promises.

### Decision 3: New Chat restarts the same-window single session

`New Chat` ends the active Codex PTY and starts a fresh Codex PTY in the same window. This preserves the v0.1 single-session constraint.

Alternative considered: open a new window. Deferred because that implies multi-session lifecycle decisions that are not needed for v0.1.

### Decision 4: Reading is the chat UI

Reading includes the empty chat prompt, central composer, native slash overlay, and transcript projection. Empty Reading shows the centered composer; after the first submitted prompt or visible transcript content, the composer can move to a bottom/sticky chat position.

Alternative considered: make Reading only a transcript view after a separate chat surface. Rejected because it splits the primary product experience unnecessarily.

### Decision 5: Top bar controls are shortcuts into Codex, not local state

Top bar can include Codex status, Reading/Terminal mode switch, New Chat, Close Session, and optional model/permission shortcuts. Any model or command shortcut must drive the real Codex CLI through PTY input and render the resulting terminal screen model. Penggie must not own model lists, command suggestions, or selected rows.

Alternative considered: native local model selector for polish. Rejected because it violates the PoC boundary that Agent CLI is the source of truth.

### Decision 6: Raw Terminal is a same-PTY fallback

Switching to Terminal shows the same Ghostty surface/session. It does not start another process, clear Reading state, or change Codex command state.

Alternative considered: start a separate shell/terminal session. Rejected because it breaks the validated Reading/Raw Terminal same-session model.

## Ghostty Substrate API

Penggie should expose only the minimum surface needed by the app shell:

- create or attach a single Codex surface/session
- report process running/exited state and launch failure
- send text to PTY
- send key events to PTY
- read screen text as plain text
- read screen text as VT text
- read screen model JSON
- host the raw terminal surface view
- focus/resize the active surface as needed

## PoC Migration Boundary

Directly migrate and rename:

- `ShowCLIComposerNativeTrigger.swift`
- `ShowCLITerminalScreenSnapshot.swift`
- native interaction scope/presentation/phase/timing logic
- AppKit composer and key capture bridge from `ShowCLIReadingMode.swift`
- Reading projection, presentation, and transcript models
- regression tests for trigger rules, screen model row extraction, native continuation, transcript, and IME placeholder behavior

Do not migrate:

- multi-agent presets other than Codex
- ShowCLI agent picker UI
- shell fallback as a start option
- research runner and corpus capture code
- ShowCLI/Ghostty visible text or brand assets
- Ghostty split tree, command palette, preferences, update overlay, or user-facing terminal product shell

## Risks / Trade-offs

- Screen model shape changes in Codex CLI could affect native overlay projection. Mitigation: keep regression fixtures and avoid adding local semantic assumptions.
- SwiftUI/AppKit focus handoff can regress around native mode. Mitigation: preserve PoC focus-request and key-capture behavior, then test `/`, `/m`, `/model`, arrows, Enter, Esc, and Backspace.
- IME behavior can regress if composer synchronization is simplified. Mitigation: preserve the PoC rule that SwiftUI must not overwrite `NSTextView.string` while marked text is active.
- Same-window `New Chat` may be less powerful than true multi-window chat. Mitigation: use clear v0.1 wording and defer multi-session design.
- Product top bar shortcuts may tempt local state duplication. Mitigation: require all command/model shortcuts to operate by sending real PTY input and projecting the resulting screen model.
