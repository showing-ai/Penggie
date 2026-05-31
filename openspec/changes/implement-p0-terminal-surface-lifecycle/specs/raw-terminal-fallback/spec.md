## MODIFIED Requirements

### Requirement: Raw Terminal uses the same PTY
The system SHALL render Raw Terminal from the same Ghostty surface and Codex PTY used by Reading.

#### Scenario: User switches to Terminal
- **WHEN** the user switches from Reading to Terminal
- **THEN** the Raw Terminal shows the current state of the same active Codex PTY

#### Scenario: User switches back to Reading
- **WHEN** the user switches from Terminal back to Reading
- **THEN** Reading resumes by reading the same PTY/screen state without restarting Codex

#### Scenario: User switches while terminal-owned surface is active
- **WHEN** the user switches Reading to Raw Terminal and back while resume, slash, model, effort, approval, or permission state is active
- **THEN** Penggie keeps the same Ghostty session and reprojects the terminal-owned surface from subsequent frames rather than replacing it with local state

### Requirement: Raw Terminal requires an active or inspectable session
The system SHALL only expose Raw Terminal when there is a session state to inspect.

#### Scenario: No Codex session exists
- **WHEN** no Codex session has been started
- **THEN** the Terminal fallback is not presented as a primary start option

#### Scenario: Codex session exits
- **WHEN** Codex exits after a session existed
- **THEN** the app may offer Raw Terminal as a way to inspect the same session's terminal state

#### Scenario: Session is still launching
- **WHEN** Penggie is checking Codex or launching the first terminal frame
- **THEN** Raw Terminal is not exposed as an inspectable fallback until a session surface exists and is safe to inspect
