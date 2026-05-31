# codex-single-session Specification

## Purpose
Define the v0.1 single local Codex session contract: one real Codex CLI process backed by a Ghostty PTY, plus same-window New Chat and Close Session lifecycle.
## Requirements
### Requirement: Single local Codex session
The system SHALL support one active local Codex-backed session in v0.1.

#### Scenario: Start with Codex succeeds
- **WHEN** the user clicks `Start with Codex` and Codex CLI is available
- **THEN** the app launches one real Codex CLI process in a Ghostty-backed PTY and enters Reading

#### Scenario: Second simultaneous session is not created
- **WHEN** a Codex session is already active
- **THEN** the app does not create an additional concurrent local session in v0.1

### Requirement: Codex CLI is the backend
The system SHALL use the real Codex CLI as the agent backend.

#### Scenario: User submits a prompt
- **WHEN** the user submits ordinary chat text from Reading
- **THEN** the text is sent to the real Codex CLI through the active PTY

### Requirement: Close Session ends the active session
The system SHALL allow the user to close the current Codex session.

#### Scenario: User closes session
- **WHEN** the user activates `Close Session`
- **THEN** the active Codex session is ended and the app returns to the Penggie start/connect screen

### Requirement: New Chat restarts the same-window session
The system SHALL define `New Chat` as a same-window restart of the single Codex session.

#### Scenario: User starts a new chat
- **WHEN** the user activates `New Chat`
- **THEN** the app ends the current Codex PTY and starts a fresh Codex PTY in the same window

#### Scenario: New Chat does not imply multi-window
- **WHEN** `New Chat` is used in v0.1
- **THEN** the app does not require multi-window or multi-session management

### Requirement: Terminal interaction surfaces preserve one active PTY
The system SHALL keep all terminal-owned interaction surface projections and inputs bound to the single active Codex/Ghostty PTY.

#### Scenario: Reading projects a terminal-owned surface
- **WHEN** Reading renders resume, slash, model, effort, approval, permission, or generic terminal choice UI
- **THEN** the rows, selected state, and confirmation state are derived from the active Codex/Ghostty session rather than a secondary process or local business-state cache

#### Scenario: User confirms a terminal-owned choice
- **WHEN** the user confirms a fresh, reliable, exactly-one terminal-owned choice from Reading
- **THEN** Penggie sends the confirmation to the same active Codex PTY used by Raw Terminal

#### Scenario: User switches views during a picker
- **WHEN** the user switches between Reading and Raw Terminal while a terminal-owned surface is active
- **THEN** both views continue observing and controlling the same Codex PTY without restarting Codex or duplicating the surface state
