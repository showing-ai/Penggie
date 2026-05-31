## ADDED Requirements

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
