## ADDED Requirements

### Requirement: Penggie-branded macOS shell
The system SHALL present Penggie as the user-visible macOS app identity.

#### Scenario: App identity is Penggie
- **WHEN** the user opens the app
- **THEN** the app name, bundle display name, menu name, window title, and app icon identify the product as Penggie

#### Scenario: Legacy shell branding is absent
- **WHEN** the user views v0.1 product surfaces
- **THEN** user-visible ShowCLI and Ghostty product shell text is not shown

### Requirement: Codex-only start screen
The system SHALL show a Penggie-branded start/connect screen with a single Codex entry point.

#### Scenario: User opens Penggie without an active session
- **WHEN** no Codex session is running
- **THEN** the user sees a Penggie-branded start screen with `Start with Codex`

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

### Requirement: Product top bar
The system SHALL provide a Penggie-owned top bar during an active session.

#### Scenario: Reading session is active
- **WHEN** the user is in an active Codex session
- **THEN** the top bar exposes session controls including Reading/Terminal mode, New Chat, and Close Session

#### Scenario: Top bar remains Penggie-owned
- **WHEN** the user switches between Reading and Raw Terminal
- **THEN** the visible top bar remains Penggie-owned and does not expose Ghostty product chrome
