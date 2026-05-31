## ADDED Requirements

### Requirement: Startup transition holds a stable Penggie surface
The system SHALL keep a Penggie-owned start surface visible while Codex startup or resume output is not yet display-ready.

#### Scenario: Codex launch is still initializing
- **WHEN** the user activates `Create with Penggie` and Codex is producing shell, startup, or status output
- **THEN** the app keeps the start surface visible instead of showing terminal startup text, Raw Terminal, or an intermediate Reading state

#### Scenario: Codex reaches a display-ready Reading state
- **WHEN** Codex reaches a stable Reading-ready state
- **THEN** the app transitions directly from the start surface to the Reading product surface

#### Scenario: Codex reaches a display-ready resume picker
- **WHEN** Codex reaches a stable resume picker projection with rows
- **THEN** the app transitions directly from the start surface to the native resume picker product surface

### Requirement: Codex startup status is not a product page
The system SHALL treat Codex startup/status progress as a blocking launch state rather than user-visible Reading content.

#### Scenario: MCP server startup is visible in the terminal
- **WHEN** the terminal projection contains Codex startup progress such as `Starting MCP servers` or `esc to interrupt`
- **THEN** the app does not show that text as Reading transcript content with a composer

#### Scenario: Startup status later resolves
- **WHEN** Codex startup/status progress resolves into a display-ready state
- **THEN** the app shows the corresponding Penggie product surface without exposing the previous transient status frame
