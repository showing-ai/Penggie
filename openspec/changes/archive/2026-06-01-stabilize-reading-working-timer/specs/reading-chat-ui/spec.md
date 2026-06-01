## ADDED Requirements

### Requirement: Reading active response progress is locally stable
The system SHALL display active response progress from Penggie turn metadata rather than relying on terminal-projected working text.

#### Scenario: Submitted prompt has no visible output yet
- **WHEN** a user submits a prompt and Codex has not produced visible answer content
- **THEN** Reading displays a `Working... Ns` response header whose elapsed seconds advance while the turn remains active

#### Scenario: Terminal working text does not repaint
- **WHEN** the terminal projection contains stale transient text such as `Working... 0s`
- **THEN** Reading still displays the locally computed active response duration as the primary progress indicator

#### Scenario: Terminal activity details exist
- **WHEN** terminal-derived activity rows such as search or tool progress are captured during an active turn
- **THEN** Reading keeps those details available behind the active response disclosure without replacing the local progress timer

### Requirement: Reading completed response duration is frozen
The system SHALL freeze response duration once a Reading turn completes.

#### Scenario: Codex provides completed duration
- **WHEN** Codex output includes a completed duration such as `Worked for 17s`
- **THEN** Reading displays that duration for the completed response and does not keep incrementing it

#### Scenario: Codex duration is unavailable
- **WHEN** a turn completes without a terminal-derived completed duration
- **THEN** Reading displays a fallback `Worked for Ns` duration computed from local turn timing and keeps it stable

### Requirement: Reading progress updates avoid full transcript re-blockization
The system SHALL update active response elapsed time without reparsing the full terminal projection every second.

#### Scenario: Active turn timer ticks
- **WHEN** one second passes while a Reading turn is active
- **THEN** the visible progress duration can update without re-running full terminal projection or blockization work

#### Scenario: Terminal output changes
- **WHEN** Codex produces new terminal output
- **THEN** Reading updates terminal-derived content through the existing projection path
