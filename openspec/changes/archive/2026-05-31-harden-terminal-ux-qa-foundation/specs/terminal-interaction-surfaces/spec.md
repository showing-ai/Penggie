## ADDED Requirements

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
