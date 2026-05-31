## ADDED Requirements

### Requirement: Foundation repairs preserve one Codex PTY
The system SHALL apply embedded Ghostty environment, theme, and screen-model foundation changes without creating additional Codex sessions or replacing the active PTY.

#### Scenario: Terminal foundation is initialized
- **WHEN** Penggie starts Codex through embedded Ghostty
- **THEN** the environment, theme, and screen-model configuration are applied to the same single Codex process and Ghostty surface used by Reading and Raw Terminal

#### Scenario: User switches views after foundation changes
- **WHEN** the user switches between Reading and Raw Terminal
- **THEN** both views continue to observe the same active Codex PTY and Ghostty surface

### Requirement: Codex remains the source of TUI-owned state
The system SHALL keep Codex and the embedded terminal as the source of keyboard-owned TUI state.

#### Scenario: Resume picker is shown
- **WHEN** Penggie projects the Codex resume picker natively
- **THEN** the resume rows, filter text, sort text, and selected-row facts are derived from the active Codex/Ghostty terminal state

#### Scenario: TUI navigation occurs
- **WHEN** the user presses navigation or confirmation keys in a Codex-owned TUI surface
- **THEN** the input is routed to the active Codex PTY rather than applied to a Penggie-maintained selected index
