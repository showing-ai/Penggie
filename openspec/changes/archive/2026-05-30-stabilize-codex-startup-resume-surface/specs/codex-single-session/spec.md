## ADDED Requirements

### Requirement: Startup and resume gating preserve one Codex PTY
The system SHALL gate product surface display without creating additional Codex sessions or replacing the active PTY.

#### Scenario: Startup is held behind Penggie surface
- **WHEN** Codex has launched but the terminal state is not display-ready
- **THEN** the app keeps the same Codex process running while holding the Penggie start surface

#### Scenario: Resume picker is projected natively
- **WHEN** the native resume picker is shown
- **THEN** navigation and confirmation input are routed to the real active Codex PTY

#### Scenario: Raw Terminal is hidden during startup hold
- **WHEN** Raw Terminal is not visible during startup or resume hold
- **THEN** the underlying Codex PTY continues running and remains available for later Reading or Terminal display

### Requirement: Resume session list remains Codex-owned
The system SHALL NOT maintain a separate local resume session list or selected index to implement the native resume picker.

#### Scenario: Resume picker rows are displayed
- **WHEN** Penggie shows saved sessions in the native resume picker
- **THEN** the rows are projected from the real Codex terminal state

#### Scenario: User navigates resume picker
- **WHEN** the user types search text or presses arrow keys, Tab, Enter, or Esc in the native resume picker
- **THEN** the input is sent to the active Codex PTY rather than applied to a local selected index
