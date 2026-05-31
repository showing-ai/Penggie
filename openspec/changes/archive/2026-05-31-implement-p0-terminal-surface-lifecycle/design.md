## Context

The current runtime already has the architectural primitives required for the first P0 slice:

- `PenggieSessionModel` owns session state, launch, polling, terminal frames, active terminal surface, and input routing.
- `PenggieRootView` renders setup, Reading, Raw Terminal, full-page resume/modal surfaces, composer overlays, and key capture.
- `PenggieNativeInteractionProjection` contains `PenggieTerminalFrame`, `PenggieTerminalBehaviorZoner`, `PenggieTerminalInteractionSurface`, selection confidence, freshness, and candidate viewport helpers.
- `PenggieGhosttySession` owns the embedded Ghostty surface and same-session Raw Terminal view.
- P0 QA foundation fixtures already test selected, stale, ambiguous, low-confidence, scrolled/paged, approval, and permission terminal facts.

This implementation change should connect those primitives to product behavior without broad redesign.

## Decisions

### Decision 1: Treat this as a runtime P0 slice, not visual productization

This change implements only the minimum runtime behavior needed for the first code phase:

- entry path safety
- terminal-owned selection and confirmation safety
- list viewport stability
- same-session Raw Terminal round trip

Visual polish, theme adjustments, larger Reading hierarchy, and accessibility expansion remain separate P1/P2 or later P0 workstreams.

### Decision 2: `Create with Penggie` is a create/new-session action

`Create with Penggie` must not be implemented as a resume action. If Codex itself shows a resume picker in a future CLI version, Penggie may project it safely, but Penggie-owned launch code and product copy must not intentionally request resume unless an explicit resume entry exists.

Implementation should audit the `PenggieGhosttySession` command path and `PenggieSessionModel.startWithCodex()` flow. Any explicit resume invocation, resume default state, or setup UI path that implies resume from the create button must be removed or separated.

### Decision 3: Terminal-owned navigation sets waiting state, not local selection

When a terminal-owned surface is active and the user presses arrow keys, Tab, Backspace, text filter keys, or Esc:

1. `PenggieSessionModel` routes the input to the active PTY.
2. The current surface may be marked `waitingForTerminalFrame` or otherwise treated as non-confirmable until a newer terminal frame arrives.
3. Reading must not move the selected highlight from a local row index.
4. The next terminal frame re-derives rows, selected row, confidence, and confirmability.

This preserves terminal source-of-truth while allowing the UI to show rows during the short wait.

### Decision 4: Enter is the only high-risk key in this slice

Navigation and filtering should route to PTY even when selection is low-confidence. Enter is different: it can confirm an action or resume a session. Therefore:

- Enter may route to PTY only when the active surface has `hasFreshConfirmableSelection == true`.
- Otherwise Enter is consumed and must not submit the Reading composer or send a raw newline to Codex.
- Escape may continue to route to PTY as the terminal-owned cancel path.

### Decision 5: Candidate viewport is a projection concern with UI acceptance

The candidate viewport helper should ensure the selected row appears fully within the native list window. UI containers must allocate enough height for the visible row count plus overflow indicators and syncing rows. The selected row must not be clipped by the rounded container, footer, or composer overlay.

This should be validated at the data level with viewport tests and at the UI level with manual QA for resume/slash/model surfaces.

### Decision 6: Same-session parity is verified through object continuity and behavior

Reading and Raw Terminal already share one `PenggieGhosttySession`. This change verifies and hardens that assumption:

- Switching Reading -> Raw Terminal -> Reading must not close or replace `ghosttySession`.
- The terminal-owned surface should continue to be projected from new frames after switching back.
- Composer draft and Reading transcript state should not be discarded by mode switching.
- Raw Terminal should remain unavailable before an inspectable session exists and available after an inspectable session exists.

## Implementation Notes

- Prefer tests around pure helpers first: `PenggieTerminalInteractionCandidateViewport`, `PenggieTerminalInputPolicy`, and `PenggieTerminalBehaviorZoner`.
- Keep session-model tests focused on state and routing decisions, not real Codex behavior.
- If a live Codex behavior cannot be deterministically unit-tested, document it in the P0 manual QA script and add a fixture when a terminal frame can represent it.
- Do not introduce local mirror state for session lists or selected indices to make tests easier.

## Risks

- **Risk: Waiting-for-frame state causes visible flicker.** Mitigation: preserve rows while disabling confirmation; do not replace rows with a loading page.
- **Risk: Create-vs-resume depends on Codex CLI behavior.** Mitigation: Penggie must not intentionally request resume; if Codex presents resume anyway, projection remains safe and manual QA records it as upstream CLI behavior.
- **Risk: UI viewport and data viewport diverge.** Mitigation: keep the row count/height contract close to `PenggieTerminalSurfaceCandidateListView` and test the viewport helper.
- **Risk: Same-session tests overfit implementation details.** Mitigation: assert user-visible invariants and object identity only where stable.
