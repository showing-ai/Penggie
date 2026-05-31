## ADDED Requirements

### Requirement: Reading renders terminal-owned interaction surfaces from the unified contract
The system SHALL render native Chat UI projections for active Codex terminal-owned interaction surfaces from the unified terminal interaction surface contract.

#### Scenario: Resume picker is projected
- **WHEN** the terminal interaction surface is a resume picker
- **THEN** Reading renders visible resume candidates, filter/sort labels, pager/footer hints, selected-row state, confidence, and confirmability from the surface projection

#### Scenario: Slash continuation is projected
- **WHEN** the terminal interaction surface is a slash continuation, model picker, or effort picker
- **THEN** Reading renders visible candidates and selected-row state from terminal-owned projection facts rather than local selected-index state

#### Scenario: Approval or permission prompt is projected
- **WHEN** the terminal interaction surface is an approval, permission, or confirmation prompt
- **THEN** Reading renders the available choices from terminal facts and does not merge the prompt into ordinary assistant transcript content

### Requirement: Reading does not own terminal surface selection
The system SHALL NOT maintain Chat UI selected-index state for Codex terminal-owned surfaces.

#### Scenario: User navigates in Reading projection
- **WHEN** the user presses arrow keys, Tab, Esc, Backspace, or filter text while a terminal-owned surface is active in Reading
- **THEN** Reading routes the input to the active Codex PTY and waits for the next terminal frame before changing the projected selected row

#### Scenario: Selection confidence is low
- **WHEN** the active surface has visible candidates but no reliable selected row
- **THEN** Reading keeps the candidates visible and shows low-confidence state without fabricating a highlighted row

#### Scenario: Confirmation is unsafe
- **WHEN** the active surface has no fresh exactly-one confirmable terminal-owned selected row
- **THEN** Reading consumes or blocks Enter and does not submit ordinary composer text as a side effect

### Requirement: Reading transcript remains separated from active terminal surfaces
The system SHALL keep active terminal-owned surfaces outside Reading transcript blockization.

#### Scenario: Active terminal surface appears
- **WHEN** the current terminal frame contains a keyboard-selectable list, modal choice, pager, or footer/help region for an active surface
- **THEN** Reading projects that surface through the interaction surface renderer instead of adding it to permanent transcript blocks

#### Scenario: Surface ends
- **WHEN** Codex returns from an active terminal-owned surface to ordinary chat transcript or idle composer state
- **THEN** Reading resumes transcript projection from terminal output without preserving the inactive surface as current UI state
