# reading-chat-ui Specification

## Purpose
Define Reading as Penggie's default chat UI, including composer, transcript projection, IME behavior, and native slash overlay boundaries.
## Requirements
### Requirement: Reading is the default active-session UI
The system SHALL enter Reading as the default UI after Codex starts successfully.

#### Scenario: Codex starts
- **WHEN** Codex launches successfully from the start screen
- **THEN** the app displays the Reading chat UI rather than Raw Terminal

### Requirement: Reading empty state is a chat surface
The system SHALL present Reading empty state as a centered chat UI with headline and composer.

#### Scenario: No conversation content exists
- **WHEN** the Codex session is active and no submitted prompt or visible transcript content exists
- **THEN** Reading shows a centered empty-state prompt and composer

### Requirement: Reading transcript state preserves chat workflow
The system SHALL display terminal-derived Codex output as Reading transcript content after interaction begins.

#### Scenario: User submits first prompt
- **WHEN** the user submits a prompt
- **THEN** Reading displays the submitted user input and terminal-derived Codex output in the transcript flow

#### Scenario: Conversation content exists
- **WHEN** Reading has submitted prompt or transcript content
- **THEN** the composer remains available for continued chat input without switching to Raw Terminal

### Requirement: Composer supports ordinary prompt submission
The system SHALL provide a stable composer with placeholder, send button, and ordinary prompt submission.

#### Scenario: User enters ordinary text
- **WHEN** the user enters non-command text and presses send or Enter
- **THEN** the text is submitted to the real Codex CLI through the active PTY

#### Scenario: Composer is empty
- **WHEN** the composer has no visible text or marked text
- **THEN** placeholder text is visible

### Requirement: Composer supports IME marked text
The system SHALL avoid overlapping placeholder text with active IME marked text.

#### Scenario: User composes Chinese text
- **WHEN** the composer has IME marked text
- **THEN** the placeholder is hidden and SwiftUI does not overwrite the active NSTextView marked text

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

### Requirement: Reading blockizer remains independent from native overlay
The system SHALL NOT alter Reading output/blockizer behavior to implement or repair native slash overlay behavior.

#### Scenario: Native overlay changes
- **WHEN** slash overlay behavior is changed or fixed
- **THEN** Reading transcript extraction remains terminal-derived and is not coupled to slash command parsing

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
