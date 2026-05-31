# terminal-interaction-surfaces Specification

## Purpose
TBD - created by archiving change model-terminal-interaction-surfaces. Update Purpose after archive.
## Requirements
### Requirement: Terminal frames are the projection input
The system SHALL derive terminal-owned interaction surfaces from immutable terminal frames captured from the active Ghostty surface.

#### Scenario: Frame is captured
- **WHEN** Penggie polls the active embedded Ghostty surface
- **THEN** the poll result includes one frame identity, visible text, screen text, decoded screen model facts, cursor/style facts, viewport facts, timestamp, and process state for downstream projections

#### Scenario: Multiple projections run
- **WHEN** Reading transcript, native slash overlay, and resume picker projections update during the same poll
- **THEN** they consume the same terminal frame rather than independently reading or decoding terminal state

### Requirement: Terminal-owned surfaces are classified by behavior
The system SHALL classify active terminal-owned interaction surfaces by behavior zone before applying feature-specific parsing.

#### Scenario: Resume picker is visible
- **WHEN** the terminal frame contains Codex resume picker header, list rows, filter/sort header, pager/footer, or equivalent evidence
- **THEN** the system classifies it as a keyboard-selectable terminal-owned surface rather than Reading transcript content

#### Scenario: Approval prompt is visible
- **WHEN** the terminal frame contains a Codex approval, permission, or confirmation choice surface
- **THEN** the system classifies it as a modal terminal-owned choice surface rather than ordinary assistant prose

#### Scenario: Historical transcript mentions picker text
- **WHEN** old transcript content mentions slash commands, model names, resume text, approval text, or permission text without an active terminal-owned surface region
- **THEN** the system does not classify that historical content as an active interaction surface

### Requirement: Interaction candidates are parsed per surface
The system SHALL use surface-specific parsers to extract visible candidates while keeping selection inference centralized.

#### Scenario: Resume rows are parsed
- **WHEN** a resume picker surface is active
- **THEN** the resume parser extracts visible session candidates, age labels, title text, filter text, sort text, and pager/footer hints without owning selected-index state

#### Scenario: Slash or model rows are parsed
- **WHEN** a slash suggestion, slash continuation, model picker, or effort picker surface is active
- **THEN** the appropriate parser extracts visible candidates and labels without using a local Codex command or model list as source of truth

#### Scenario: Approval choices are parsed
- **WHEN** an approval or permission prompt is active
- **THEN** the parser extracts visible terminal choices and metadata from terminal text/style facts without creating a local approval list

### Requirement: Selection inference is centralized and confidence-aware
The system SHALL infer terminal-owned current row through one shared selection primitive that returns confidence and evidence.

#### Scenario: Unique marker identifies current row
- **WHEN** exactly one candidate row has a terminal-owned visible marker such as `›`
- **THEN** the interaction surface reports a single selected row with marker evidence

#### Scenario: Style identifies current row
- **WHEN** no unique marker is available and terminal style facts identify exactly one current candidate row
- **THEN** the interaction surface reports a single selected row with style evidence

#### Scenario: Selection evidence is missing
- **WHEN** candidate rows exist but terminal facts do not identify a selected row
- **THEN** the interaction surface reports no reliable selected row and does not fabricate one from local array position

#### Scenario: Selection evidence conflicts
- **WHEN** terminal facts identify multiple possible selected rows or conflicting selected rows
- **THEN** the interaction surface reports ambiguous selection with evidence and no confirmable row

#### Scenario: User selects terminal text
- **WHEN** Ghostty has an active mouse text selection
- **THEN** the interaction surface does not treat that text selection as Codex TUI current-row selection

### Requirement: Confirmation is gated by terminal-owned selection confidence
The system SHALL allow GUI confirmation only when the active terminal-owned surface has a fresh, reliable, exactly-one confirmable row.

#### Scenario: Exactly one confirmable row exists
- **WHEN** the active surface reports a fresh single selected candidate that is confirmable
- **THEN** Enter or GUI confirm is routed to Codex through the active PTY

#### Scenario: Selection is ambiguous
- **WHEN** the active surface reports no selected row, ambiguous selected rows, or stale selected-row evidence
- **THEN** Enter or GUI confirm is blocked or consumed by Penggie and is not allowed to fall through as ordinary composer text

#### Scenario: Rows are visible but selection is unreliable
- **WHEN** candidate rows are visible and selection confidence is low
- **THEN** Reading shows the rows and a low-confidence or syncing indication instead of hiding the rows or inventing a highlight

#### Scenario: Confirmation waits after navigation
- **WHEN** the user navigates or filters a terminal-owned surface and Penggie has not yet received fresh terminal-frame evidence for the resulting selected row
- **THEN** Enter remains blocked or consumed while useful candidate rows remain visible

### Requirement: Keyboard interaction remains PTY-routed
The system SHALL route terminal-owned surface navigation and editing through the active Ghostty/Codex PTY.

#### Scenario: User navigates a terminal-owned list
- **WHEN** the user presses arrow keys, Tab, Esc, Backspace, or text filter keys in an active terminal-owned surface
- **THEN** Penggie sends the corresponding input to the active Codex PTY and waits for a new terminal frame

#### Scenario: Chat UI renders native rows
- **WHEN** Reading displays a native projection of a terminal-owned surface
- **THEN** the native UI does not mutate local selection in response to navigation keys

#### Scenario: Input is blocked
- **WHEN** a terminal-owned input policy blocks a key because confirmation is unsafe or stale
- **THEN** the key event is consumed and does not continue into ordinary composer input handling

### Requirement: Raw Terminal and Reading projection agree on selected row
The system SHALL keep Reading projections in parity with the selected row displayed by the same Raw Terminal surface whenever terminal facts are reliable.

#### Scenario: Raw Terminal shows one selected row
- **WHEN** Raw Terminal displays a terminal-owned interaction surface with exactly one current row indicated by marker or style
- **THEN** Reading projection highlights the same terminal row when it renders that surface natively

#### Scenario: Parity cannot be proven
- **WHEN** terminal facts are insufficient for Reading to prove the selected row shown in Raw Terminal
- **THEN** Reading reports low confidence and does not show a potentially wrong selected row

### Requirement: Terminal-owned confirmation has executable safety tests
The system SHALL test that terminal-owned confirmation only succeeds with fresh reliable selected-row evidence.

#### Scenario: Fresh selected row exists
- **WHEN** a terminal-owned surface has exactly one fresh confirmable selected row proven by terminal-frame evidence
- **THEN** Enter, click, or accessibility activation may route confirmation to the PTY

#### Scenario: Selection is stale
- **WHEN** the selected row is based on a previous frame or cannot be matched to the current candidate set
- **THEN** Enter, click, or accessibility activation is blocked or consumed and no local confirmation is performed

#### Scenario: Selection is ambiguous or missing
- **WHEN** rows exist but selected-row evidence is missing or identifies multiple candidates
- **THEN** the surface remains visible when useful, confirmation is unavailable, and the UI does not fabricate a selected index

### Requirement: Terminal-owned navigation remains PTY-routed under tests
The system SHALL test that navigation does not mutate selected state locally before terminal evidence arrives.

#### Scenario: Arrow key is pressed
- **WHEN** the user presses an arrow key in a terminal-owned surface
- **THEN** the key is sent to the PTY, the surface may enter waiting-for-terminal-frame state, and selected highlight does not move from a local array index

#### Scenario: Tab or filter text is entered
- **WHEN** the user presses Tab, Backspace, or filter text in a terminal-owned surface
- **THEN** the input routes to the PTY and metadata, rows, and selected state update only from a subsequent terminal frame

### Requirement: Terminal-owned fixture coverage includes scrolled and blocked states
The system SHALL include terminal interaction fixtures for selected, scrolled, paged, low-confidence, stale, and blocked-confirm states.

#### Scenario: Resume fixture set is reviewed
- **WHEN** resume picker fixture coverage is reviewed
- **THEN** it includes selected, unselected, ambiguous, low-confidence, filtered, sorted, paged, and scrolled selected-row cases

#### Scenario: Approval and permission fixture set is reviewed
- **WHEN** approval and permission fixture coverage is reviewed
- **THEN** it includes visible choices, selected evidence, missing selected evidence, blocked Enter, Esc/cancel, and Raw Terminal parity expectations

#### Scenario: Slash and model fixture set is reviewed
- **WHEN** slash, model, effort, or continuation fixture coverage is reviewed
- **THEN** it includes marker selection, style selection, cursor fallback, stale selection, ambiguous selection, and no-local-index expectations

### Requirement: Selected candidate remains visible in native overlays
The system SHALL keep the terminal-owned selected candidate fully visible when Reading renders a native list projection.

#### Scenario: Selected row is below the visible window
- **WHEN** a terminal-owned list has more candidates than the native visible row count and the selected candidate is below the initial window
- **THEN** the native projection scrolls or windows the candidate list so the selected row is fully visible

#### Scenario: Selected row is near a boundary
- **WHEN** the selected row is near the top or bottom of the candidate list
- **THEN** the native projection keeps the selected row fully visible and avoids clipping the selected background, marker, or text

#### Scenario: Selection is unavailable
- **WHEN** rows exist but no selected candidate can be proven
- **THEN** the native projection may show the first useful rows with a syncing indicator, but it does not fake a selected row

