## ADDED Requirements

### Requirement: Inactive Raw Terminal does not visually leak
The system SHALL prevent inactive Raw Terminal from drawing over or through Reading and startup/resume hold surfaces.

#### Scenario: Reading is active
- **WHEN** the active session is in Reading mode
- **THEN** the Raw Terminal Ghostty host view is not visible to the user

#### Scenario: Startup hold is active
- **WHEN** the app is holding the start surface during Codex startup or resume projection
- **THEN** the Raw Terminal fallback is not visible even if the Ghostty surface is running

#### Scenario: Terminal mode is explicitly selected
- **WHEN** the user explicitly switches to Terminal mode after the session is inspectable
- **THEN** the Raw Terminal shows the same active Ghostty surface and Codex PTY

### Requirement: Raw Terminal remains same-session fallback
The system SHALL preserve Raw Terminal as a fallback view over the same Codex PTY while hiding inactive frames.

#### Scenario: User switches between Reading and Terminal
- **WHEN** the user switches Reading to Terminal and back
- **THEN** the same Codex PTY remains active and is not restarted or duplicated

#### Scenario: Raw Terminal is inactive
- **WHEN** Raw Terminal is not the selected mode
- **THEN** it does not receive focus or key input
