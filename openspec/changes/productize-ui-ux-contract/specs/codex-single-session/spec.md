## ADDED Requirements

### Requirement: Productization milestones preserve Codex and Ghostty as runtime authority
The system SHALL require every product-grade UI/UX implementation milestone to preserve the real Codex CLI process and Ghostty-backed PTY as the only user-visible runtime authority.

#### Scenario: UI polish is planned
- **WHEN** an implementation milestone changes Reading, Raw Terminal, setup, overlays, composer, recovery, theme, accessibility, or QA behavior
- **THEN** it documents how the change preserves the same Codex process, cwd, PTY, Ghostty surface, terminal frame, and terminal-owned state

#### Scenario: Alternative runtime is proposed
- **WHEN** a task proposes using a separate SDK session, `codex exec --json` session, headless semantic session, local provider session, or forked Raw Terminal session for the user-visible workflow
- **THEN** the task is rejected unless it is explicitly non-authoritative diagnostic tooling outside the active user session

### Requirement: Productization milestones keep terminal-owned decisions in the PTY path
The system SHALL preserve PTY-routed input and terminal-frame evidence for terminal-owned decisions throughout productization.

#### Scenario: Terminal-owned interaction is changed
- **WHEN** slash, model, effort, resume, approval, permission, or modal choice behavior is implemented or refined
- **THEN** navigation, text input, confirmation, and cancel actions route to the Codex PTY and visible state updates only after terminal-frame evidence

#### Scenario: Confirmation safety is reviewed
- **WHEN** a productized UI offers Enter, click, or accessibility activation for a terminal-owned choice
- **THEN** the confirmation is blocked unless the current terminal frame proves a fresh exactly-one confirmable selected row

### Requirement: Productization milestones keep Raw Terminal as same-session proof
The system SHALL treat Raw Terminal as the proof surface for every milestone that affects Reading or terminal-owned projection.

#### Scenario: Reading behavior is reviewed
- **WHEN** Reading renders transcript content, low-confidence fallback, terminal-owned overlay, or recovery state
- **THEN** QA includes a Raw Terminal parity check whenever a live or inspectable Ghostty session exists

#### Scenario: Raw Terminal parity fails
- **WHEN** Reading and Raw Terminal disagree about process, cwd, terminal-owned rows, selected row, prompt readiness, or process state
- **THEN** the implementation is not accepted until the discrepancy is explained and fixed or the Reading surface degrades visibly with Raw Terminal inspection available
