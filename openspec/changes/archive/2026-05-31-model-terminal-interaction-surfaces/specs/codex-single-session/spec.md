## ADDED Requirements

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
