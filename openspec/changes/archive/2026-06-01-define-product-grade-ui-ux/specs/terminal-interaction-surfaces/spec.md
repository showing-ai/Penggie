## ADDED Requirements

### Requirement: Product UX requires proof-backed selected rows
The system SHALL expose selected-row state for terminal-owned interaction surfaces only when it is backed by explicit terminal-frame evidence.

#### Scenario: Selected row is projected
- **WHEN** Reading displays a selected row for slash, model, effort, resume, approval, permission, or modal choice UI
- **THEN** the selected state includes frame id, candidate row id, source row/column or line index, evidence kind, freshness, and confidence

#### Scenario: Navigation key is pressed
- **WHEN** the user presses arrow keys or Tab in a terminal-owned surface
- **THEN** Penggie may enter a waiting-for-terminal-frame state but does not move the visible selected highlight locally before a fresh terminal frame proves the new selected row

#### Scenario: Evidence is stale
- **WHEN** selected-row evidence is from a prior frame or cannot be matched to the current candidate set
- **THEN** the surface reports stale or low-confidence selection and has no confirmable row

### Requirement: Permission prompts are safety-sensitive terminal-owned surfaces
The system SHALL treat permission prompts as first-class terminal-owned surfaces with their own confirmation safety requirements.

#### Scenario: Permission prompt is visible
- **WHEN** the terminal frame contains a permission prompt or equivalent safety-sensitive choice surface
- **THEN** Penggie extracts visible choices, selected-state evidence, confirmability, and low-confidence state from terminal facts rather than treating the prompt as ordinary transcript prose

#### Scenario: Permission selection is uncertain
- **WHEN** a permission prompt has visible choices but no fresh exactly-one confirmable selected row
- **THEN** Enter or GUI confirmation is blocked or consumed and Raw Terminal remains available for inspection

### Requirement: Terminal-owned surfaces define accessibility state
The system SHALL expose accessibility state for projected terminal-owned candidates without making accessibility a separate source of interaction truth.

#### Scenario: Candidate row is accessible
- **WHEN** VoiceOver or keyboard-only navigation reaches a projected candidate row
- **THEN** the row exposes selected/not selected, confirmable/unavailable, syncing/unknown when applicable, and row text derived from terminal facts

#### Scenario: Accessibility action confirms a row
- **WHEN** an accessibility activation attempts to confirm a terminal-owned candidate
- **THEN** the confirmation follows the same fresh exactly-one confirmable selected-row gate as keyboard Enter

## MODIFIED Requirements

### Requirement: Selection inference is centralized and confidence-aware
The system SHALL infer terminal-owned current row through one shared selection primitive that returns confidence, freshness, and evidence.

#### Scenario: Unique marker identifies current row
- **WHEN** exactly one candidate row has a terminal-owned visible marker such as `›`
- **THEN** the interaction surface reports a single selected row with marker evidence tied to the current frame

#### Scenario: Style identifies current row
- **WHEN** no unique marker is available and terminal style facts identify exactly one current candidate row
- **THEN** the interaction surface reports a single selected row with style evidence tied to the current frame

#### Scenario: Selection evidence is missing
- **WHEN** candidate rows exist but terminal facts do not identify a selected row
- **THEN** the interaction surface reports no reliable selected row and does not fabricate one from local array position, prior selected state, or a temporary local cursor

#### Scenario: Selection evidence conflicts
- **WHEN** terminal facts identify multiple possible selected rows or conflicting selected rows
- **THEN** the interaction surface reports ambiguous selection with evidence and no confirmable row

#### Scenario: User selects terminal text
- **WHEN** Ghostty has an active mouse text selection
- **THEN** the interaction surface does not treat that text selection as Codex TUI current-row selection
