# Terminal-Owned Live QA Readiness

Task support: `3.10`.

## Scope

This is source-backed readiness evidence for the P0 terminal-owned overlay
manual QA pass. It does not claim live overlay QA pass, Raw Terminal parity pass,
keyboard focus pass, or VoiceOver pass.

Task `3.10` remains open until slash, model, resume, approval, and permission
surfaces are exercised in the running macOS app in both Reading and Raw Terminal.

## Source-Backed Readiness

### Fixture Coverage

The terminal interaction fixture catalog includes:

- resume selected/filter/sort/pager, scrolled selected, unselected, ambiguous,
  and low-confidence states;
- slash suggestions, style-selected rows, ambiguous selection, stale/missing
  selection, and continuation rows;
- model and effort picker rows with cursor fallback and stale/missing selection;
- approval prompt rows with marker-selected, style-selected, cancel/reject,
  ambiguous, and missing-selection states;
- permission prompt rows with selected allow/cancel and missing-selection
  states.

The fixture README records selected-row evidence, confidence, freshness,
confirmability, Raw Terminal parity expectations, and the rule that ambiguous,
stale, waiting-for-frame, or missing selection states consume Enter.

### Regression Coverage

`PenggieTerminalInteractionSurfaceTests` covers:

- surface classification for resume, slash, model, effort, approval, permission,
  and negative historical transcript cases;
- selected-row evidence sources including marker, cursor, explicit selected
  cells, and screen model marker;
- low-confidence and ambiguous surfaces that keep rows visible but block Enter;
- stale and waiting-for-terminal-frame surfaces that preserve rows but block
  confirmation;
- approval and permission modal choices with safe cancel routing and blocked
  unsafe Enter.

### Source Path Readiness

The app source keeps terminal-owned state in the terminal path:

- screen model JSON is required when terminal-owned cues such as `allow once`,
  `deny`, model/effort prompts, filter/sort, or resume shortcuts appear;
- `PenggieSessionModel` publishes `activeTerminalInteractionSurface` from the
  terminal frame zoner/resolver;
- arrow/Tab/text routes to the PTY and marks the surface
  `waitingForTerminalFrame`;
- Reading renders resume/approval/permission/modal surfaces from the active
  terminal interaction surface;
- Enter is gated through `PenggieTerminalInputPolicy` and
  `hasFreshConfirmableSelection`.

### Manual QA Coverage

The manual QA matrix includes:

- `QA-OVERLAY-001` slash suggestions;
- `QA-OVERLAY-002` model and effort picker;
- `QA-OVERLAY-003` resume picker scroll, filter, sort, and page boundary;
- `QA-OVERLAY-004` approval and permission modal choices.

These scenarios require light/dark review, normal/narrow windows where relevant,
rapid keyboard navigation, Esc, Enter, Tab, Backspace or typed filtering, and
Raw Terminal parity.

## Manual QA Boundary

This readiness guard cannot prove:

- the running app receives the same live terminal frames in every Codex TUI
  surface;
- rapid arrow navigation never flickers or jumps under real rendering load;
- Raw Terminal shows the same live selected row for every surface;
- focus restoration works with live AppKit first responder behavior;
- VoiceOver announces the selected/syncing/unavailable states correctly.

Those checks remain part of `3.10` and must be recorded from a live app run.

## Verification

- `scripts/qa/check-p0-terminal-owned-live-qa-readiness.sh` -> P0 terminal-owned
  live QA readiness guard passed.

## Non-Goals

- No local command, model, resume, approval, permission, or selected-index state.
- No second Codex process.
- No second Ghostty session.
- No forked Raw Terminal session.
- No SwiftUI overlay may fake terminal-owned selected state or confirmability.
