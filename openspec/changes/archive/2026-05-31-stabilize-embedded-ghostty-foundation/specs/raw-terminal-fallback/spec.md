## ADDED Requirements

### Requirement: Raw Terminal is the visual truth for embedded Ghostty
The system SHALL make Raw Terminal a faithful view of the embedded Ghostty surface's rendered terminal state.

#### Scenario: ANSI probe is rendered
- **WHEN** a user or diagnostic prints ANSI foreground, truecolor, faint, bold, and inverse sequences in Raw Terminal
- **THEN** Raw Terminal renders visibly distinct output according to the active Ghostty theme and terminal style pipeline

#### Scenario: Codex TUI uses color
- **WHEN** Codex emits SGR style for a TUI surface
- **THEN** Raw Terminal displays those styles without Penggie flattening them through an unrelated palette or contrast override

### Requirement: Raw Terminal theme follows embedded Ghostty configuration
The system SHALL configure Raw Terminal colors through the same embedded Ghostty theme configuration used by the active surface.

#### Scenario: Light theme is active
- **WHEN** macOS appearance and embedded Ghostty color scheme resolve to light mode
- **THEN** Raw Terminal uses the configured light Ghostty terminal theme

#### Scenario: Dark theme is active
- **WHEN** macOS appearance and embedded Ghostty color scheme resolve to dark mode
- **THEN** Raw Terminal uses the configured dark Ghostty terminal theme

#### Scenario: Theme config is changed
- **WHEN** Penggie changes embedded Ghostty theme configuration
- **THEN** Raw Terminal remains a same-surface fallback and does not restart or duplicate the Codex PTY solely to apply the visual configuration

#### Scenario: Known TUI control row is rendered
- **WHEN** Codex emits a known explicit RGB background for the active input control row
- **THEN** Raw Terminal renders that control row with Penggie's current terminal-scene active input color while preserving ordinary terminal truecolor output
