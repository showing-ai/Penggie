# Terminal-Owned Surface Contract Audit

Task: `3.1 Review PenggieNativeInteractionProjection.swift, PenggieNativeInteractionPhase.swift, PenggieCodexScreenKind.swift, PenggieTerminalFrameNormalizer.swift, PenggieSessionModel.swift, and PenggieRootView.swift against the terminal-owned surface contract.`

## Scope Reviewed

- `Penggie/Sources/PenggieNativeInteractionProjection.swift`
- `Penggie/Sources/PenggieNativeInteractionPhase.swift`
- `Penggie/Sources/PenggieCodexScreenKind.swift`
- `Penggie/Sources/PenggieTerminalFrameNormalizer.swift`
- `Penggie/Sources/PenggieSessionModel.swift`
- `Penggie/Sources/PenggieRootView.swift`
- `Tests/PenggieCoreTests/PenggieTerminalInteractionSurfaceTests.swift`
- `Tests/PenggieCoreTests/PenggieNativeInteractionProjectionTests.swift`
- `Tests/PenggieCoreTests/Fixtures/terminal-interaction-surfaces/`

## Contract Alignment

### Terminal Frame Store

Penggie now has a single frame object for terminal-owned interaction projection:

- `PenggieTerminalFrame` carries `id`, `observedAt`, `visibleText`, `screenText`, `screenModelJSON`, and process state.
- `PenggieSessionModel` polls Ghostty, creates a `PenggieTerminalFrame`, stores it as `latestTerminalFrame`, and derives `activeTerminalInteractionSurface` from that frame.
- `PenggieTerminalScreenModelReadPolicy` requests screen model JSON for native interaction, resume picker, and visible TUI cues.

This matches the contract that Chat UI projections must start from terminal facts rather than local SwiftUI state.

### Behavior Zoning And Surface Projection

`PenggieTerminalBehaviorZoner` centralizes the first useful behavior layer:

- `resumePicker`
- `slashSuggestions`
- `slashContinuation`
- `modelPicker`
- `effortPicker`
- `approvalPrompt`
- `permissionPrompt`
- `modalChoice`

`PenggieTerminalInteractionSurface` carries zones, candidates, selection, selection source, confidence, freshness, evidence, metadata, and input policy. This is aligned with the contract requirement that selectable surfaces expose a unified interaction model instead of each feature owning its own selection state.

### Terminal-Owned Selection

Selection is inferred from terminal evidence:

- visible text markers
- screen model markers
- explicit selected cells
- foreground/style summaries
- cursor row fallback
- screen text marker fallback

`PenggieTerminalOwnedSelectionProjection` and `inferTerminalOwnedSelection` provide a shared primitive for menu-like surfaces. Enter confirmation requires a fresh, single, confirmable selected row.

### Input Routing

`PenggieTerminalInputPolicy.commandDecision(.enter, surface:)` blocks Enter unless the active surface has one fresh confirmable selection. Other keys are routed to PTY by `PenggieSessionModel.sendTerminalSurfaceCommand` / `sendTerminalSurfaceText`, preserving Codex/Ghostty as the owner of menu state.

This satisfies the main safety contract: Chat UI must not confirm ambiguous, stale, or missing terminal-owned selection.

### UI Rendering

`PenggieRootView` renders full-page terminal-owned surfaces and composer overlays from `activeTerminalInteractionSurface`. Candidate lists use `PenggieTerminalInteractionCandidateViewport.derive(...)` so the selected row stays in the projected visible window without local selectedIndex ownership.

The UI uses projection data for highlight state and key handling. It does not maintain a local resume/session list or local selected index.

### Fixture Coverage Already Present

Existing terminal interaction fixture coverage includes:

- resume selected, scrolled, unselected, ambiguous, and low-confidence states
- resume filter/sort/pager fixture
- slash suggestions, style-selected slash, ambiguous slash, and slash continuation
- model/effort picker, cursor fallback, and stale unselected states
- approval/permission prompt, cancel-selected, and missing-selection states
- negative historical transcript fixture

Tests already assert:

- supported surface classification
- frame identity propagation
- blocked Enter for ambiguous, low-confidence, stale, and waiting surfaces
- candidate viewport keeps selected row visible
- transcript text does not become an active terminal-owned surface without active TUI chrome

## Gaps And Risks

### 1. Freshness Is Not Yet Proven By Frame Advancement

`sendTerminalSurfaceCommand` and `sendTerminalSurfaceText` mark the active surface as `.waitingForTerminalFrame`, but the next poll recomputes a fresh surface from whatever frame is read. There is no explicit pending input token or `lastInputFrameID` gate that proves the selected row evidence came from a terminal frame after the input.

Risk: fast repeated key events can show a fresh highlight based on a re-read of the same terminal state, or briefly allow confirmation before Codex/Ghostty has advanced.

Required follow-up: task 3.6 should add a frame-advance freshness gate while keeping rows visible.

### 2. Resume Still Has A Legacy Projection Path

`PenggieCodexResumePickerProjection` still parses resume rows and selection separately from `PenggieTerminalInteractionSurface`. `PenggieRootView.handleResumePickerCommand` also contains legacy fallback behavior when no active surface is available.

Risk: resume metadata, selected row, and confirmability can diverge between the legacy projection and the unified surface.

Required follow-up: migrate resume rendering and command policy fully onto `PenggieTerminalInteractionSurface`, keeping legacy projection only as a parser helper if needed.

### 3. Slash Overlay Still Has Dual Paths

Slash flows can render through `activeTerminalInteractionSurface` as a composer overlay, but `nativeInteractionRows` and the older `PenggieNativeInteractionOverlay` path still exist.

Risk: slash suggestions and slash continuation can regress if the legacy overlay and unified surface infer different selected rows or different visible regions.

Required follow-up: define the migration boundary for slash/model/effort surfaces in tasks 3.3, 3.6, and 3.9.

### 4. Geometry Is Projection-Based, Not Viewport-State-Based

`PenggieTerminalInteractionCandidateViewport.derive` keeps selected candidates in the projected list, but it does not model terminal pager position, scroll direction, row geometry, or animation suppression.

Risk: selected rows are not clipped, but the list can still appear to jump when the candidate window shifts. Header/footer metadata can also flash when the surface updates.

Required follow-up: tasks 3.5 and 3.8 should define stable visible-window behavior and metadata layout rules.

### 5. Accessibility Values Are Incomplete

Candidate rows visually expose selected state, but the row view does not yet provide complete accessibility values for:

- selected/not selected
- confirmable/unavailable
- syncing/unknown
- row text
- non-color selected affordance

Required follow-up: task 3.9 should add row-level accessibility labels, values, and hints, then cover them with manual VoiceOver QA.

### 6. Approval/Permission Detection Is Still Heuristic

Approval and permission surfaces are covered by the central surface model and fixtures, but detection is text heuristic based. It needs broader safety fixtures and Raw Terminal parity checks.

Risk: safety-sensitive prompts can be missed or misclassified if Codex changes copy or layout.

Required follow-up: task 3.4 should expand modal fixtures for selected evidence, confirmable state, blocked Enter, Esc/cancel behavior, and Raw Terminal parity.

### 7. `PenggieCodexScreenKind` Remains Page-Oriented

`PenggieCodexScreenKind` still models startup/status/resume/chat pages rather than the behavior-zone taxonomy. This is acceptable as a short-term screen-kind gate, but it must not become a second terminal-owned state machine.

Required follow-up: keep feature behavior in `PenggieTerminalInteractionSurface`; use `PenggieCodexScreenKind` only for coarse startup/resume/chat display gating.

### 8. Screen Model Read Policy Is Cue-Based

`PenggieTerminalScreenModelReadPolicy` uses a list of text cues to decide when screen model JSON is required.

Risk: new Codex terminal-owned surfaces can be missed if no cue matches.

Required follow-up: fixture/source guard coverage should include approval, permission, modal, slash, model, effort, and resume cues; future behavior zoning should prefer active frame evidence over narrow feature names.

## P0 Follow-Up Order

1. Complete task 3.2 and task 3.3 fixture expansion for resume/slash/model/effort surfaces.
2. Complete task 3.4 approval/permission/modal fixtures before changing modal UI behavior.
3. Implement task 3.6 freshness with a frame-advance gate.
4. Implement task 3.5 selected-row geometry and task 3.8 metadata stability.
5. Implement task 3.7 low-confidence behavior and confirm that rows remain visible while Enter is blocked.
6. Implement task 3.9 accessibility values.
7. Run task 3.10 manual QA across Reading and Raw Terminal.

## Non-Goals For This Change Segment

- Do not add local command/model/resume/approval/permission lists.
- Do not add local selectedIndex ownership in SwiftUI.
- Do not split Raw Terminal and Reading into separate Codex/Ghostty sessions.
- Do not change Codex key event semantics.
- Do not fake terminal-owned highlights from SwiftUI state.
- Do not hide useful candidate rows just because selection confidence is low.

## 3.1 Acceptance Evidence

This audit establishes the current alignment and remaining gaps for the terminal-owned surface contract. The next implementation task should start with fixture/test expansion, not broad UI rewrites.

