## ADDED Requirements

### Requirement: P0 foundation work preserves one Codex session
The system SHALL keep the first terminal UX QA foundation bound to one real Codex CLI process and Ghostty PTY.

#### Scenario: Fixture or test uses terminal state
- **WHEN** a fixture, test, or manual QA scenario asserts terminal-owned rows, selected state, prompt readiness, approval, permission, or Raw Terminal parity
- **THEN** it treats the live Codex/Ghostty terminal frame as the authority and does not introduce a separate user-visible Codex session

#### Scenario: Local mirror is proposed
- **WHEN** foundation work proposes a local command list, model list, resume list, approval list, permission list, selected index, or second runtime as implementation support
- **THEN** the work is rejected unless the data is explicitly diagnostic-only and cannot drive user-visible state or confirmation

### Requirement: P0 foundation work gates unsafe confirmation
The system SHALL ensure unsafe terminal-owned confirmation remains blocked in the first implementation foundation.

#### Scenario: Confirmation is tested
- **WHEN** Enter, click, or accessibility activation is tested on a terminal-owned choice
- **THEN** the action confirms only when the current terminal frame proves a fresh exactly-one confirmable selected row

#### Scenario: Confirmation is unsafe
- **WHEN** selected-row evidence is stale, missing, ambiguous, or low confidence
- **THEN** the action is blocked or consumed and does not fall through to ordinary composer submission
