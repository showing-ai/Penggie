## ADDED Requirements

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
