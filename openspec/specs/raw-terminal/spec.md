# raw-terminal Specification

## Purpose
TBD - created by archiving change refine-session-entry-and-minimal-chrome. Update Purpose after archive.
## Requirements
### Requirement: Raw Terminal uses Penggie light theme
The system SHALL present the Raw Terminal fallback with a Penggie-controlled light terminal theme while preserving the same Ghostty PTY/session.

#### Scenario: User switches to Raw Terminal
- **WHEN** the user switches from Reading to Raw Terminal during an active session
- **THEN** the terminal uses a light Penggie background, dark readable text, and a readable ANSI palette
- **AND** it displays the same session state and scrollback rather than launching a new process

#### Scenario: Terminal theme does not affect source of truth
- **WHEN** Raw Terminal is shown with the light theme
- **THEN** Reading transcript extraction, native slash overlay data, and PTY key routing still come from the same Ghostty screen model and process

