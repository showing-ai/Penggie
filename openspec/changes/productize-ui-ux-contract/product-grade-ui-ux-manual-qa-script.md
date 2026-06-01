# Product-Grade UI/UX Manual QA Script

Task: 10.1

## Scope

This script verifies the product-grade UI/UX matrix with repeatable manual
steps. It is a QA script, not an alternate runtime. The running Penggie app,
its embedded Ghostty surface, and the real Codex CLI session remain the only
user-visible truth.

## Required Evidence Record

For every scenario, record:

- Scenario ID and result: pass, fail, blocked, or not applicable.
- Penggie commit SHA and build configuration.
- macOS appearance: light or dark.
- Window size: normal, narrow, or large-text review size.
- Project folder path.
- Terminal fixture or live terminal setup used.
- Keyboard path used.
- VoiceOver state: off, on, or not applicable.
- Expected result and observed result.
- Screenshot or screen recording when the scenario fails or is visual.
- Raw Terminal parity note whenever an inspectable terminal surface exists.

## Global Setup

1. Check out the intended commit and confirm the worktree has no unrelated dirty
   app-code changes.
2. Optionally prepare a local evidence bundle:
   `scripts/qa/prepare-product-ui-ux-local-qa.sh`
3. Build the Debug app:
   `xcodebuild -project Penggie/Penggie.xcodeproj -scheme Penggie -configuration Debug -destination 'platform=macOS' build`
4. Launch the built Penggie app from the same build product being reviewed.
5. Use a test project folder that contains:
   - At least one existing Codex session for resume QA.
   - Files that can trigger ordinary prompt output, CJK output, table output,
     code output, and long transcript output.
   - A safe prompt or command path that can trigger approval or permission UI
     when the current Codex configuration supports it.
6. Close any unrelated Penggie windows before starting the run.
7. Do not launch a second Codex CLI or Ghostty session as QA truth. If an
   external terminal is used, it is diagnostic-only and must not drive pass/fail
   for Reading or Raw Terminal parity.

## Review Matrix

Run the applicable scenarios in both light and dark mode. For visual scenarios,
also run at:

- Normal window: approximately 1440x900.
- Narrow window: minimum practical width that still supports Penggie.
- Large-text review: macOS accessibility larger text enabled, or the closest
  stable local equivalent.

## P0 App Shell And Lifecycle

### QA-SETUP-001: Valid folder start

- Setup: open Penggie at the start surface with a valid project folder.
- Terminal fixture: none; no Codex process should be running yet.
- Window size: normal.
- Theme: light and dark.
- Keyboard: Tab through agent, folder, and `Create with Penggie`; press Space
  on `Create with Penggie`.
- VoiceOver: repeat with VoiceOver on.
- Expected result: folder is announced, create is enabled, checking/launching
  appears without startup shell text leaking into Reading, and Raw Terminal is
  unavailable until an inspectable session exists.

### QA-SETUP-002: Invalid or missing folder recovery

- Setup: choose a missing folder path or remove the selected folder before
  launch.
- Terminal fixture: none.
- Window size: normal and narrow.
- Theme: light and dark.
- Keyboard: Tab to recovery controls and activate folder selection.
- VoiceOver: on.
- Expected result: Penggie explains the folder problem, disables unsafe start,
  exposes a recovery action, and does not start Codex.

### QA-LIFE-001: New Chat confirmation

- Setup: start a stable Reading session.
- Terminal fixture: ordinary chat-ready Codex prompt.
- Window size: normal.
- Theme: light and dark.
- Keyboard: activate New Chat, then Esc/cancel; repeat and confirm.
- VoiceOver: on for one run.
- Expected result: confirmation explains the destructive action, cancel keeps
  the current Codex/Ghostty session, confirm closes the old session and starts a
  new one only after confirmation.

### QA-LIFE-002: Close Session confirmation

- Setup: start a stable Reading session.
- Terminal fixture: ordinary chat-ready Codex prompt.
- Window size: normal.
- Theme: light and dark.
- Keyboard: activate Close Session, then Esc/cancel; repeat and confirm.
- VoiceOver: on for one run.
- Expected result: cancel preserves the session; confirm closes the Codex
  session and returns to the start surface.

## P0 Terminal-Owned Overlays

### QA-OVERLAY-001: Slash suggestions

- Setup: stable Reading session with empty composer.
- Terminal fixture: type `/` from the local composer so Codex owns the slash
  surface.
- Window size: normal and narrow.
- Theme: light and dark.
- Keyboard: Down, Up, Enter, Esc, Backspace, and typed filtering.
- VoiceOver: on for row-state verification.
- Expected result: candidate rows are terminal-backed, one fresh reliable row is
  selected when terminal evidence exists, highlight is fully visible, Enter is
  blocked when confidence is stale or ambiguous, and Raw Terminal shows the same
  terminal-owned state.

### QA-OVERLAY-002: Model and effort picker

- Setup: open slash menu and choose the model or effort command path.
- Terminal fixture: Codex model/effort TUI surface.
- Window size: normal and narrow.
- Theme: light and dark.
- Keyboard: arrows, Tab when available, Enter, Esc.
- VoiceOver: on for selected/not selected values.
- Expected result: Penggie does not maintain a local model list or selected
  index; selected state updates only after fresh terminal frames.

### QA-OVERLAY-003: Resume picker scroll, filter, sort, and page boundary

- Setup: launch the explicit resume path with enough saved sessions to exceed
  the visible list.
- Terminal fixture: Codex resume picker.
- Window size: normal and narrow.
- Theme: light and dark.
- Keyboard: arrows past the visible bounds, Tab to filter/sort, type filter
  text, Backspace, Esc, Enter.
- VoiceOver: on for row and syncing state.
- Expected result: selected row remains fully visible, metadata/header/footer do
  not flash or jump, low-confidence rows remain visible, Enter is unavailable
  until the terminal frame proves exactly one fresh confirmable selected row,
  and Raw Terminal matches the same selected row.

### QA-OVERLAY-004: Approval and permission modal choices

- Setup: use a safe prompt or command that triggers approval or permission UI.
- Terminal fixture: Codex approval or permission modal.
- Window size: normal.
- Theme: light and dark.
- Keyboard: arrows, Enter, Esc/cancel.
- VoiceOver: on.
- Expected result: safety-sensitive copy and all visible choices are announced;
  confirm follows the same fresh exactly-one confirmable gate as Enter; Raw
  Terminal shows the same prompt and selected row.

## P0 Composer, IME, Focus, And Input Routing

### QA-COMP-001: IME marked text

- Setup: stable Reading session.
- Terminal fixture: ordinary prompt-ready Codex input.
- Window size: normal.
- Theme: light and dark.
- Keyboard: use Chinese or Japanese IME marked text, commit text, then Enter.
- VoiceOver: optional.
- Expected result: placeholder hides during marked text, marked text is not
  overwritten by SwiftUI state, Enter does not submit while text is marked, and
  committed text submits correctly.

### QA-COMP-002: Ordinary composer behavior

- Setup: stable Reading session.
- Terminal fixture: ordinary prompt-ready Codex input.
- Window size: normal and narrow.
- Theme: light and dark.
- Keyboard: Enter submit, Shift-Enter newline, paste, large paste, disabled send
  state, draft restore after mode switch.
- VoiceOver: on for one run.
- Expected result: local composer owns ordinary prompt input only when no
  terminal-owned surface is active; bounded height and internal scroll work
  without stealing terminal-owned keys.

### QA-COMP-003: Slash handoff focus

- Setup: stable Reading session with empty composer.
- Terminal fixture: type `/` to enter terminal-owned slash surface.
- Window size: normal.
- Theme: light and dark.
- Keyboard: type slash, arrows, Esc, then resume ordinary typing.
- VoiceOver: on.
- Expected result: first slash is sent to Codex, terminal key capture owns the
  surface, local composer does not own selection, and dismissal restores the
  correct focus owner.

### QA-FOCUS-001: Focus transitions across app states

- Setup: exercise setup, Reading idle, composing, terminal-owned overlay,
  full-page resume/approval/permission, Raw Terminal, confirmation, process
  exit, and recovery states.
- Terminal fixture: live Codex session plus fixture-backed low-confidence state
  when available.
- Window size: normal and narrow.
- Theme: light and dark.
- Keyboard: Tab, Esc, Enter, mode switch, confirmation cancel/confirm, and
  return from Raw Terminal to Reading.
- VoiceOver: on for one full pass.
- Expected result: there is exactly one active keyboard owner at each point;
  blocked states do not leak keys to the wrong owner; returning from each state
  restores the expected composer, overlay, Raw Terminal, or confirmation focus.

## P0 Reading Transcript And Display AST

### QA-READ-001: Long transcript stability

- Setup: resume or create a session with a long completed answer.
- Terminal fixture: long transcript with enough content to scroll.
- Window size: normal and narrow.
- Theme: light and dark.
- Keyboard: scroll Reading, switch to Raw Terminal, switch back, resize, submit a
  follow-up prompt.
- VoiceOver: optional.
- Expected result: completed turns do not duplicate, disappear, reorder,
  rewrite, or absorb active terminal-owned surfaces.

### QA-READ-002: CJK, table, code, warning, and fallback display

- Setup: use prompts or fixtures that produce CJK prose, tables, code blocks,
  warnings, tool-heavy output, box drawing, and low-confidence content.
- Terminal fixture: matching `agent-terminal-display` fixture when available, or
  live terminal output recorded in the evidence note.
- Window size: normal, narrow, large-text review.
- Theme: light and dark.
- Keyboard: scroll, resize, switch Raw Terminal and back.
- VoiceOver: on for fallback explanation.
- Expected result: Display AST or raw/preformatted fallback preserves visible
  terminal evidence, terminal chrome/status/current input does not seal into
  assistant transcript content, and Raw Terminal remains available.

## P0 Raw Terminal Audit And Control

### QA-RAW-001: Reading to Raw Terminal round trip

- Setup: stable Reading session.
- Terminal fixture: ordinary chat-ready prompt plus one active overlay run.
- Window size: normal.
- Theme: light and dark.
- Keyboard: switch Reading to Raw Terminal and back using keyboard controls.
- VoiceOver: on for mode switch labels.
- Expected result: same Codex process, cwd, Ghostty session, scrollback, active
  terminal-owned state, process state, draft state, and transcript state are
  preserved.

### QA-RAW-002: Raw Terminal control and clipboard

- Setup: Raw Terminal visible.
- Terminal fixture: ordinary prompt-ready Codex screen and one mouse-reporting
  TUI surface when available.
- Window size: normal.
- Theme: light and dark.
- Keyboard: type in Raw Terminal, paste text, switch back to Reading.
- Pointer: optional for this scenario; use `QA-RAW-004` for full selection
  coverage.
- VoiceOver: not applicable unless testing mode switch labels.
- Expected result: Ghostty host receives keys when visible, paste reaches the
  embedded terminal, local composer does not capture terminal input, and Reading
  return restores the correct focus owner.

### QA-RAW-003: Low-confidence Raw Terminal availability

- Setup: force or fixture a Reading projection degraded/low-confidence state.
- Terminal fixture: low-confidence display or terminal-owned surface fixture
  with an inspectable terminal surface.
- Window size: normal and narrow.
- Theme: light and dark.
- Keyboard: switch to Raw Terminal, inspect state, switch back to Reading.
- VoiceOver: on for the mode switch and degraded-state message.
- Expected result: Raw Terminal remains available whenever an inspectable
  terminal surface exists; Reading does not hide visible rows or fabricate
  certainty; returning to Reading preserves session and draft state.

### QA-RAW-004: Raw Terminal text selection, copy, paste, and mouse reporting

- Setup: Raw Terminal visible with ordinary scrollback and a mouse-reporting TUI
  surface when available.
- Terminal fixture: ordinary transcript text plus a terminal-owned picker or
  prompt that may capture mouse events.
- Window size: normal.
- Theme: light and dark.
- Keyboard: copy shortcut, paste shortcut, and mode switch.
- Pointer: select text, copy, inspect pasteboard result, test platform modifier
  behavior such as Shift-drag if required.
- VoiceOver: not applicable.
- Expected result: text selection/copy behavior is documented accurately,
  pasteboard content matches selected terminal text when selection is supported,
  paste reaches the same PTY, and any mouse-reporting modifier requirement is
  recorded rather than hidden.

### QA-RAW-005: Raw Terminal visual parity

- Setup: Raw Terminal visible in ordinary prompt, active input, terminal
  selection, ANSI color output, and terminal-owned selected-row states.
- Terminal fixture: live Codex screen plus ANSI/style fixture when practical.
- Window size: normal and narrow.
- Theme: light and dark.
- Keyboard: switch themes, switch Reading/Raw, open slash/resume/model surface.
- VoiceOver: not applicable.
- Expected result: canvas, titlebar chrome, active input, cursor, terminal
  selection, ANSI palette, selected rows, and native overlay tokens remain
  visually coherent without Raw Terminal using a separate session or flattened
  Reading colors.

## P1 Accessibility And Dynamic State

### QA-AX-001: Keyboard-only and larger-text complete journey

- Setup: start from the Penggie setup surface.
- Terminal fixture: live Codex session with slash/model/resume and
  approval/permission paths when available.
- Window size: normal, narrow, and larger-text review size.
- Theme: light and dark.
- Keyboard: complete setup, prompt submission, slash/model selection, resume
  selection, approval/permission choice, Raw Terminal switch, New Chat
  confirmation, and Close Session confirmation without pointer input.
- VoiceOver: off for keyboard-only run, then on for the VoiceOver run.
- Expected result: all controls are reachable, focus owner is clear, terminal
  decisions remain terminal-owned, larger text does not hide essential state,
  full values remain accessible, and unsafe confirmation is blocked when
  evidence is stale or ambiguous.

### QA-AX-002: Dynamic announcements

- Setup: stable Reading session plus recovery and overlay scenarios.
- Terminal fixture: checking, launching, ready, working/tool running, approval
  required, permission required, projection degraded, selection syncing, process
  exited, missing Codex, and launch failed states.
- Window size: normal.
- Theme: light and dark.
- Keyboard: trigger each state through normal app controls or documented safe
  diagnostic setup.
- VoiceOver: on.
- Expected result: announcements are useful, not noisy, and never imply SwiftUI
  owns terminal-owned state.

## P1 Visual QA

### QA-VIS-001: Theme and chrome parity

- Setup: capture setup, empty Reading, long transcript, composer focus, slash
  overlay, resume picker, approval/permission, Raw Terminal, recovery, narrow
  window, and large-text states.
- Terminal fixture: relevant live or fixture-backed state for each capture.
- Window size: normal, narrow, and large-text review.
- Theme: light and dark.
- Keyboard: use keyboard-only path to reach each state where practical.
- VoiceOver: not required for visual capture.
- Expected result: topbar, canvas, composer, native overlays, Raw Terminal,
  selected rows, warnings, danger states, disabled states, focus rings, and
  terminal renderer colors use approved tokens and have no unintended seams.

### QA-VIS-002: Density and contrast review

- Setup: use long transcript, CJK/table/code, terminal-owned overlay, and Raw
  Terminal screens.
- Terminal fixture: fixture-backed or live output recorded in evidence.
- Window size: normal, narrow, large-text review.
- Theme: light and dark.
- Keyboard: navigate each surface.
- VoiceOver: optional.
- Expected result: density comes from hierarchy and disclosure, not tiny body
  text or hidden state; text, icons, selected rows, disabled state, warnings,
  danger, and focus indicators meet contrast expectations.

### QA-VIS-003: Explicit contrast target review

- Setup: capture normal text, large text/icons, disabled controls, selected
  rows, warnings, danger confirmations, focus rings, terminal renderer colors,
  and Raw Terminal active input in both themes.
- Terminal fixture: live or fixture-backed state for each contrast-sensitive
  component.
- Window size: normal, narrow, and larger-text review size.
- Theme: light and dark.
- Keyboard: navigate to focused, selected, disabled, syncing, warning, and
  destructive states.
- VoiceOver: optional.
- Expected result: each captured state meets the product contrast targets or has
  an explicit follow-up with affected component, token, and scenario ID.

## Pass Criteria

The manual QA run passes only when:

- Every applicable P0 scenario passes or has an explicit blocked reason.
- Every terminal-owned decision remains PTY-routed and terminal-frame-backed.
- Reading and Raw Terminal agree on process, cwd, selected rows, prompt
  readiness, process state, and low-confidence fallback availability.
- Visual issues are documented with captures and linked to follow-up task IDs.
- Accessibility issues are documented with spoken phrase, expected phrase, and
  whether unsafe confirmation was blocked.

## Non-Goals

- Do not use a second Codex CLI, SDK session, or `codex exec --json` output as
  user-visible truth.
- Do not add local command, model, resume, approval, permission, or selected
  index data to make QA easier.
- Do not accept screenshot-only evidence when a terminal fixture or diagnostic
  capture is required by the milestone.
- Do not mark implementation tasks complete from this script alone; tasks still
  require their specific runtime, fixture, unit, accessibility, or visual
  evidence.
