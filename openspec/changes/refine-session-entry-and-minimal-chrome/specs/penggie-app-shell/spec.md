## MODIFIED Requirements

### Requirement: Codex-only start screen
The system SHALL show a Penggie-branded start/connect screen with a single Codex agent entry path and explicit pre-launch session folder selection.

#### Scenario: User opens Penggie without an active session
- **WHEN** no Codex session is running
- **THEN** the user sees a Penggie-branded start screen with Codex as the v0.1 agent CLI and a session folder selection before launch

#### Scenario: User starts Reading from configured start screen
- **WHEN** the user has selected a session folder and activates `Create with Penggie`
- **THEN** the app starts the Codex-backed session in that folder and enters Reading

#### Scenario: Unsupported providers are hidden
- **WHEN** the start screen is shown in v0.1
- **THEN** provider options other than Codex are not presented as selectable product paths

### Requirement: Product top bar
The system SHALL provide Penggie-owned active-session chrome aligned with the macOS titlebar region.

#### Scenario: Reading session is active
- **WHEN** the user is in an active Codex session
- **THEN** the chrome exposes a destination mode icon for switching between Reading and Terminal without rendering a duplicate in-content top bar

#### Scenario: Top bar remains Penggie-owned
- **WHEN** the user switches between Reading and Raw Terminal
- **THEN** the visible chrome remains Penggie-owned and does not expose Ghostty product chrome

#### Scenario: Active chrome is minimal
- **WHEN** an active session is shown
- **THEN** redundant provider branding, extra text tabs, and nonessential actions are not shown as a heavy toolbar

#### Scenario: Mode icon is accessible
- **WHEN** the user navigates to the mode switch
- **THEN** the icon has a clear tooltip, accessibility label, and sufficient hit area
