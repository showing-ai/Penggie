## MODIFIED Requirements

### Requirement: Codex-only start screen
The system SHALL show a Penggie-branded start/connect screen with a single Codex entry point.

#### Scenario: User opens Penggie without an active session
- **WHEN** no Codex session is running
- **THEN** the user sees a Penggie-branded start screen with `Start with Codex`

#### Scenario: Unsupported providers are hidden
- **WHEN** the start screen is shown in v0.1
- **THEN** provider options other than Codex are not presented as selectable product paths

#### Scenario: Create starts the create path
- **WHEN** the user activates `Create with Penggie`
- **THEN** Penggie starts the intended new/create Codex session path and does not invoke a resume-specific command unless a separate explicit resume entry is selected

### Requirement: Productized session states
The system SHALL show Penggie-owned state pages for session setup and failure conditions.

#### Scenario: Codex is missing
- **WHEN** Codex CLI cannot be found
- **THEN** the app shows a clear Penggie-branded `Codex CLI not found` state with a retry path

#### Scenario: Codex launch fails
- **WHEN** starting Codex fails
- **THEN** the app shows a Penggie-branded launch failure state instead of dropping the user into terminal output

#### Scenario: Codex process exits
- **WHEN** the active Codex process exits
- **THEN** the app shows a Penggie-branded ended-session state with paths to start again or view Raw Terminal when available

#### Scenario: Launching blocks inspect-only actions
- **WHEN** Penggie is checking Codex or launching a session
- **THEN** prompt submission, Raw Terminal switching, New Chat, and Close Session are unavailable until an inspectable session or recovery state exists
