## ADDED Requirements

### Requirement: Native TUI projections use terminal-owned style facts
The system SHALL derive native Codex TUI projections from terminal marker and style facts exported by the embedded Ghostty screen model.

#### Scenario: Resume picker marker is visible
- **WHEN** the current viewport contains exactly one visible Codex resume picker marker
- **THEN** the native resume picker projects the corresponding row as selected

#### Scenario: Screen model style identifies current row
- **WHEN** the visible marker is unavailable and the screen model exposes a unique current-row style among candidate resume rows
- **THEN** the native resume picker projects that row as selected

#### Scenario: Selection facts are ambiguous
- **WHEN** terminal marker and style facts do not identify exactly one selected resume row
- **THEN** the native resume picker shows projected rows without confirming a resume through Enter

### Requirement: Native TUI projections do not maintain local selected indexes
The system SHALL NOT maintain local selected-index state for Codex-owned keyboard TUI surfaces.

#### Scenario: User navigates resume picker
- **WHEN** the user presses arrow keys, Tab, search text, Enter, or Esc in the native resume picker
- **THEN** Penggie sends input to Codex and waits for terminal-owned marker/style facts to update the projection

#### Scenario: User navigates slash overlay
- **WHEN** the user navigates a native slash or continuation menu
- **THEN** Penggie sends input to Codex and derives the selected row from terminal-owned marker/style facts

### Requirement: Resume picker and slash overlay share selection projection primitives
The system SHALL share terminal-owned selected line or region inference primitives across native Codex TUI projections while preserving each surface's parser.

#### Scenario: Resume picker rows are parsed
- **WHEN** Penggie parses resume picker rows
- **THEN** it uses resume-specific row parsing for age and title while using shared terminal selection projection for selected-row inference

#### Scenario: Slash suggestions are parsed
- **WHEN** Penggie parses slash suggestions or continuation menus
- **THEN** it uses slash-specific parsing and input anchoring while using shared terminal selection projection for selected-row inference where applicable
