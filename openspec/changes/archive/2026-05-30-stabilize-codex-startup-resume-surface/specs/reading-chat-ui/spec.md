## ADDED Requirements

### Requirement: Reading renders only display-ready Codex state
The system SHALL render Reading only after the current Codex terminal state is safe to present as a Penggie chat surface.

#### Scenario: Terminal projection is startup status
- **WHEN** Codex is showing startup/status output rather than a chat-ready state
- **THEN** Reading does not hydrate that output into chat transcript content

#### Scenario: Terminal projection is chat-ready
- **WHEN** Codex reaches a stable chat-ready state with no conversation content
- **THEN** Reading shows the empty-state prompt and composer

#### Scenario: Ready signal is transient
- **WHEN** a display-ready signal is observed for only a transient poll frame
- **THEN** Reading remains hidden until the ready state is stable across the configured debounce window

### Requirement: Native resume picker keeps projected rows visible while selected state syncs
The system SHALL show projected Codex-owned resume rows when rows are available, even if the selected row is temporarily unavailable, and SHALL only allow resume confirmation when exactly one selected row is known.

#### Scenario: Resume picker rows are missing
- **WHEN** Codex is showing resume picker chrome but Penggie has not projected session rows
- **THEN** the app keeps the startup hold surface instead of showing an incomplete native picker

#### Scenario: Resume picker selection is missing
- **WHEN** Codex is showing resume picker rows but Penggie cannot determine exactly one selected row
- **THEN** the native resume picker shows the projected rows without a selected highlight and indicates that selection is syncing

#### Scenario: Resume picker selection is known
- **WHEN** Penggie projects resume picker rows and exactly one selected row
- **THEN** the native resume picker shows that selected row with a single visual highlight

#### Scenario: Resume confirmation requires a selected row
- **WHEN** the native resume picker has rows but Penggie cannot determine exactly one selected row
- **THEN** pressing Enter does not resume a session until selection is reliable

### Requirement: Resume picker selection uses terminal marker precedence
The system SHALL prefer the Codex/Ghostty visible `›` marker as the selected-row source for native resume picker projection.

#### Scenario: Visible text contains one resume marker
- **WHEN** visible terminal text contains exactly one resume picker row beginning with `›`
- **THEN** the native resume picker marks the corresponding projected row as selected

#### Scenario: Snapshot lacks marker text
- **WHEN** screen model snapshot rows omit the `›` marker but visible terminal text contains one
- **THEN** the visible marker selection overrides snapshot fallback selection

#### Scenario: Style signals are ambiguous
- **WHEN** snapshot style signals would select multiple resume rows
- **THEN** the native resume picker does not mark multiple rows selected
