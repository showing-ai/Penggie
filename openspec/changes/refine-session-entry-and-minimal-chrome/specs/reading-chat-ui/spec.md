## ADDED Requirements

### Requirement: Composer footer avoids fake or duplicated context
The system SHALL avoid fake command affordances and duplicated session context in the Reading composer footer.

#### Scenario: Reading composer is shown
- **WHEN** the Reading composer is visible during an active session
- **THEN** the footer does not show `/ commands` as a clickable-looking control

#### Scenario: Session folder context is already in titlebar
- **WHEN** the titlebar shows the active session folder
- **THEN** the composer footer does not duplicate that folder path

## MODIFIED Requirements

### Requirement: Native slash overlay uses Codex as source of truth
The system SHALL render native slash suggestions as a GUI projection of the real Codex terminal screen model.

#### Scenario: User types slash in empty composer
- **WHEN** the user types `/` as the first untrimmed composer character
- **THEN** the app enters native interaction mode and sends `/` to the active Codex PTY

#### Scenario: User filters slash suggestions
- **WHEN** the user types `/m`
- **THEN** the overlay displays suggestions derived from the real Codex screen model, not a local command list

#### Scenario: User opens model menu
- **WHEN** the user enters `/model` and confirms through Enter
- **THEN** model selection is driven by the real Codex CLI state and rendered from the terminal screen model

#### Scenario: User navigates native menu
- **WHEN** the user presses arrow keys, Enter, Esc, or Backspace during native interaction
- **THEN** the key events are routed to the real PTY and Penggie does not maintain local selected-index state

#### Scenario: User backspaces within native slash input
- **WHEN** the user backspaces from `/m` to `/`
- **THEN** native slash mode remains active and the menu remains sourced from Codex CLI

#### Scenario: User clears native slash input
- **WHEN** the user backspaces from `/` to empty
- **THEN** native interaction exits cleanly

#### Scenario: Slash commands are input-driven
- **WHEN** the composer footer no longer shows a `/ commands` control
- **THEN** typing `/` remains the way to open the native slash overlay
