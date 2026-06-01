## ADDED Requirements

### Requirement: Reading is a high-signal transcript over the real Codex session
The system SHALL make Reading easier to understand than Raw Terminal while preserving terminal-derived trust and same-session continuity.

#### Scenario: Assistant response completes
- **WHEN** Codex completes a response
- **THEN** Reading shows the final answer as stable assistant transcript content without terminal footers, active input rows, current menus, or transient status chrome polluting the answer

#### Scenario: Tool or command detail exists
- **WHEN** a turn includes tool activity, command output, trace detail, or working status
- **THEN** Reading summarizes it near the turn and allows inspection without expanding verbose logs by default

#### Scenario: Completed history is reviewed
- **WHEN** terminal repaint, window resize, Raw Terminal switching, or later turns occur
- **THEN** completed Reading turns do not unexpectedly duplicate, disappear, reorder, or rewrite

### Requirement: Reading transcript has explicit turn anatomy
The system SHALL separate user prompt, working/tool summary, assistant answer, collapsible details, and raw/preformatted fallback into recognizable transcript roles.

#### Scenario: User submits a prompt
- **WHEN** the user sends composer text to Codex
- **THEN** Reading records the prompt as user-owned content and associates subsequent terminal-derived output with that turn when evidence is sufficient

#### Scenario: Terminal-sensitive output is shown
- **WHEN** output contains code, tables, box drawing, CJK-aligned text, or low-confidence display classification
- **THEN** Reading uses preformatted, monospace, horizontal-scroll, cell-aware, or raw fallback rendering as needed to preserve readability and visible evidence

#### Scenario: Active terminal-owned surface appears
- **WHEN** the current terminal frame contains a slash/model/resume/approval/permission/modal interaction surface
- **THEN** Reading projects the surface through native interaction UI and does not seal it as ordinary assistant transcript content

### Requirement: Composer is a native prompt surface, not a local command interpreter
The system SHALL preserve reliable macOS text entry while routing prompt and command input to the active Codex PTY.

#### Scenario: User composes with IME
- **WHEN** the user has active marked text
- **THEN** placeholder text is hidden, SwiftUI state does not overwrite the marked text, and Enter does not prematurely submit it

#### Scenario: User submits ordinary text
- **WHEN** the composer has committed submittable text and no terminal-owned interaction is active
- **THEN** Enter or the send affordance submits the prompt to the active Codex PTY-backed session

#### Scenario: User types a slash prefix
- **WHEN** slash input is entered through the active composer path
- **THEN** Penggie begins terminal-owned interaction by sending the prefix to Codex and projecting candidates from terminal state rather than a local command table

### Requirement: Terminal-owned surfaces use one native interaction system
The system SHALL present slash, model, effort, resume, approval, permission, and modal choice surfaces through one terminal-owned interaction contract.

#### Scenario: Candidate rows are projected
- **WHEN** a terminal-owned surface is active
- **THEN** candidate rows, selected row, confidence, freshness, confirmability, help text, and metadata are derived from the current terminal frame evidence

#### Scenario: User navigates a surface
- **WHEN** the user presses arrows, Tab, Esc, Enter, Backspace, or text input while a terminal-owned surface is active
- **THEN** the input routes to Codex through the PTY and Reading waits for a fresh terminal frame before changing projected selection

#### Scenario: Selection is projected
- **WHEN** Reading shows a selected terminal-owned candidate
- **THEN** that selected state is backed by frame id, candidate row id, evidence kind, freshness, and confidence rather than a temporary local cursor

#### Scenario: Selection is ambiguous or stale
- **WHEN** Penggie cannot prove a fresh exactly-one confirmable selected row
- **THEN** Reading shows a low-confidence/syncing state, blocks or consumes unsafe Enter, and does not fabricate a local selected index

#### Scenario: Permission surface appears
- **WHEN** Codex renders a permission prompt
- **THEN** Reading treats it as a safety-sensitive terminal-owned surface with explicit choices, selected-state evidence, unsafe-confirm blocking, and Raw Terminal parity rather than merging it into generic transcript prose

### Requirement: Reading quality is validated by scenario matrix
The system SHALL be reviewed using concrete user-visible scenarios rather than only high-level design questions.

#### Scenario: QA matrix is run
- **WHEN** Reading is evaluated for launch maturity
- **THEN** QA covers normal turns, long tasks, tool disclosures, slash/model/resume/approval surfaces, low-confidence projection, Raw Terminal round trips, CJK/table/code output, IME, focus, paste, resize, and long-session stability
