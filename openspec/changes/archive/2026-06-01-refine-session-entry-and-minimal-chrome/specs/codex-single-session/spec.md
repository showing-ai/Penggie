## MODIFIED Requirements

### Requirement: Single local Codex session
The system SHALL support one active local Codex-backed session in v0.1, launched from a selected session folder.

#### Scenario: Create with Penggie succeeds
- **WHEN** the user activates `Create with Penggie` with a selected session folder and Codex CLI is available
- **THEN** the app launches one real Codex CLI process in a Ghostty-backed PTY using the selected folder as the working directory and enters Reading

#### Scenario: Second simultaneous session is not created
- **WHEN** a Codex session is already active
- **THEN** the app does not create an additional concurrent local session in v0.1

## ADDED Requirements

### Requirement: Session folder is selected before launch
The system SHALL determine the Codex working directory before launching the Codex process.

#### Scenario: No folder is selected
- **WHEN** the user has not selected a session folder on the start screen
- **THEN** the app does not launch Codex as an active session

#### Scenario: User selects a folder
- **WHEN** the user chooses a readable local folder before launch
- **THEN** the app treats that folder as the pending working directory for the next Codex session

#### Scenario: Remembered folder exists
- **WHEN** Penggie has a remembered folder from a previous run and that folder is still readable
- **THEN** the app may preselect it but still displays it before launch

### Requirement: Active session folder is immutable
The system SHALL treat the Codex working directory as immutable for an active session.

#### Scenario: Session is active
- **WHEN** a Codex session is already running
- **THEN** the app displays the active session folder as read-only context rather than a mutable setting

#### Scenario: User wants a different folder
- **WHEN** the user needs to use a different working directory
- **THEN** the app requires starting a new Codex session instead of changing the active PTY working directory in place
