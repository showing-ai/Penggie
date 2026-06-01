# penggie-app-shell Specification

## Purpose
Define the Penggie-owned macOS shell, branding, start/connect flow, session states, and top bar responsibilities for v0.1.
## Requirements
### Requirement: Penggie-branded macOS shell
The system SHALL present Penggie as the user-visible macOS app identity.

#### Scenario: App identity is Penggie
- **WHEN** the user opens the app
- **THEN** the app name, bundle display name, menu name, window title, and app icon identify the product as Penggie

#### Scenario: Legacy shell branding is absent
- **WHEN** the user views v0.1 product surfaces
- **THEN** user-visible ShowCLI and Ghostty product shell text is not shown

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

### Requirement: Productized session states
The system SHALL show Penggie-owned state pages for session setup and failure conditions.

#### Scenario: Codex is missing
- **WHEN** Codex CLI cannot be found
- **THEN** the app shows a clear Penggie-branded `Codex CLI not found` state with a retry path

#### Scenario: Codex launch fails
- **WHEN** starting Codex fails
- **THEN** the app shows a Penggie-branded launch failure state instead of dropping the user into terminal output

#### Scenario: Codex process exits
- **WHEN** the active Codex process exits
- **THEN** the app shows a Penggie-branded ended-session state with paths to start again or view Raw Terminal when available

#### Scenario: Launching blocks inspect-only actions
- **WHEN** Penggie is checking Codex or launching a session
- **THEN** prompt submission, Raw Terminal switching, New Chat, and Close Session are unavailable until an inspectable session or recovery state exists

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

### Requirement: P0 manual QA covers setup and lifecycle safety
The system SHALL include setup and lifecycle scenarios in the first product-grade manual QA foundation.

#### Scenario: Create path is tested
- **WHEN** the user activates `Create with Penggie`
- **THEN** QA verifies the app starts the intended create/new-session path and does not enter resume picker unless Codex is explicitly launched in resume mode or the user explicitly chooses resume

#### Scenario: Failure states are tested
- **WHEN** missing Codex, launch failure, invalid folder, process exited with terminal surface, or process exited without terminal surface is triggered
- **THEN** QA verifies specific recovery copy, enabled actions, blocked actions, keyboard owner, and Raw Terminal availability

#### Scenario: Destructive actions are tested
- **WHEN** New Chat or Close Session is invoked
- **THEN** QA verifies confirmation, focus trap, cancel restoration, and no session discard before confirmation

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
