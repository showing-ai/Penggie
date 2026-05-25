## ADDED Requirements

### Requirement: Raw Terminal is a fallback view
The system SHALL expose Raw Terminal as a fallback view rather than the default active-session UI.

#### Scenario: Codex starts successfully
- **WHEN** the active Codex session begins
- **THEN** Reading is shown by default and Raw Terminal is available only through an explicit view switch

### Requirement: Raw Terminal uses the same PTY
The system SHALL render Raw Terminal from the same Ghostty surface and Codex PTY used by Reading.

#### Scenario: User switches to Terminal
- **WHEN** the user switches from Reading to Terminal
- **THEN** the Raw Terminal shows the current state of the same active Codex PTY

#### Scenario: User switches back to Reading
- **WHEN** the user switches from Terminal back to Reading
- **THEN** Reading resumes by reading the same PTY/screen state without restarting Codex

### Requirement: Raw Terminal does not expose Ghostty product shell
The system SHALL keep Raw Terminal inside the Penggie app shell.

#### Scenario: Terminal fallback is visible
- **WHEN** Raw Terminal mode is active
- **THEN** the Penggie top bar and window remain visible and Ghostty command palette, split UI, preferences, and update overlay are not presented as product chrome

### Requirement: Raw Terminal requires an active or inspectable session
The system SHALL only expose Raw Terminal when there is a session state to inspect.

#### Scenario: No Codex session exists
- **WHEN** no Codex session has been started
- **THEN** the Terminal fallback is not presented as a primary start option

#### Scenario: Codex session exits
- **WHEN** Codex exits after a session existed
- **THEN** the app may offer Raw Terminal as a way to inspect the same session's terminal state
