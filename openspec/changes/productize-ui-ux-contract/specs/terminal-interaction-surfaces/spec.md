## ADDED Requirements

### Requirement: Terminal-owned overlay implementation covers geometry and freshness
The system SHALL productize terminal-owned overlays with explicit geometry, scrolling, clipping, freshness, and confirmation acceptance criteria.

#### Scenario: Selectable overlay is changed
- **WHEN** slash, model, effort, resume, approval, permission, or modal choice projection or UI is changed
- **THEN** the task verifies row parsing, selected-row evidence, freshness, confirmability, visible row geometry, clipping, auto-scroll, footer/help placement, and low-confidence state

#### Scenario: Selection moves beyond visible bounds
- **WHEN** terminal-owned selection moves past the visible list region
- **THEN** the projected native surface scrolls or repositions so the proven selected row remains fully visible without clipped highlight, partial row state, or layout jump

#### Scenario: Surface updates rapidly
- **WHEN** consecutive terminal frames update rows, selected evidence, filter/sort metadata, or pager state
- **THEN** the native surface does not flash an old selected row as authoritative and does not locally animate selection ahead of terminal evidence

### Requirement: Terminal-owned overlay implementation uses fixture-backed evidence
The system SHALL require fixture or diagnostic evidence for terminal-owned overlay behavior changes.

#### Scenario: Resume picker changes
- **WHEN** resume picker projection, scroll, filter, sort, pager, or selection behavior changes
- **THEN** the task adds or updates fixtures covering selected, unselected, ambiguous, filtered, sorted, paged, scrolled, and low-confidence states

#### Scenario: Slash or model picker changes
- **WHEN** slash suggestions, continuation menus, model picker, effort picker, or command-prefix behavior changes
- **THEN** the task adds or updates fixtures covering marker selection, style selection, cursor fallback, ambiguous selection, and stale selection

#### Scenario: Approval or permission changes
- **WHEN** approval, permission, or safety-sensitive modal choice behavior changes
- **THEN** the task adds or updates fixtures covering visible choices, selected evidence, confirmable state, blocked Enter, Esc/cancel behavior, and Raw Terminal parity

### Requirement: Terminal-owned overlay implementation includes accessibility gates
The system SHALL validate accessibility state for terminal-owned candidates as part of each implementation milestone.

#### Scenario: Candidate row is reviewed
- **WHEN** a candidate row appears in a native terminal-owned surface
- **THEN** it exposes row text, selected/not selected state, confirmable/unavailable state, syncing/unknown state when applicable, and a non-color selected affordance

#### Scenario: Confirmation is attempted through accessibility
- **WHEN** VoiceOver or keyboard activation attempts to confirm a terminal-owned candidate
- **THEN** the activation follows the same fresh exactly-one confirmable selected-row gate as Enter

### Requirement: Terminal-owned overlay implementation forbids local state ownership
The system SHALL reject implementation shortcuts that make native overlays own Codex TUI state.

#### Scenario: Local selected index is proposed
- **WHEN** an implementation proposes changing highlighted rows immediately on arrow key before a fresh terminal frame proves selection
- **THEN** the implementation is rejected or rewritten to route the key to PTY and wait for terminal evidence

#### Scenario: Local row list is proposed
- **WHEN** an implementation proposes local resume, command, model, approval, permission, or modal choice rows as authoritative product data
- **THEN** the implementation is rejected unless the rows are diagnostic-only and never drive UI confirmation or selected state
