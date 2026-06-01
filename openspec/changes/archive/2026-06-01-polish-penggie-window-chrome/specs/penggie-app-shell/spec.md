## MODIFIED Requirements

### Requirement: Product top bar
The system SHALL provide Penggie-owned active-session controls as native-feeling window chrome rather than as a separate in-content toolbar row.

#### Scenario: Reading session is active
- **WHEN** the user is in an active Codex Reading session
- **THEN** the window chrome exposes Penggie identity, Codex session label, a Raw Terminal destination icon, New Chat, and Close Session

#### Scenario: Terminal session is active
- **WHEN** the user is viewing Raw Terminal for an active Codex session
- **THEN** the window chrome exposes Penggie identity, Codex session label, a Reading destination icon, New Chat, and Close Session

#### Scenario: Top bar remains Penggie-owned
- **WHEN** the user switches between Reading and Raw Terminal
- **THEN** the visible window chrome remains Penggie-owned and does not expose Ghostty product chrome

#### Scenario: Content does not render a duplicate top bar
- **WHEN** Reading or Raw Terminal is visible
- **THEN** the main content area starts below one Penggie window chrome strip and does not render a second full-width top bar row

## ADDED Requirements

### Requirement: Icon-only chrome controls are accessible
The system SHALL make icon-only active-session controls discoverable and operable without relying on visible text labels.

#### Scenario: User hovers an icon-only control
- **WHEN** the user hovers the mode switch, New Chat, or Close Session control
- **THEN** the app shows a tooltip that names the action

#### Scenario: Assistive technology reads an icon-only control
- **WHEN** assistive technology focuses the mode switch, New Chat, or Close Session control
- **THEN** the app exposes an accessibility label that names the action

#### Scenario: User targets an icon-only control
- **WHEN** the user points at an icon-only window chrome control
- **THEN** the hit target is large enough for reliable desktop interaction and has visible hover, focus, pressed, and disabled states
