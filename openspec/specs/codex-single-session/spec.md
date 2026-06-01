# codex-single-session Specification

## Purpose
Define the v0.1 single local Codex session contract: one real Codex CLI process backed by a Ghostty PTY, plus same-window New Chat and Close Session lifecycle.
## Requirements
### Requirement: Single local Codex session
The system SHALL support one active local Codex-backed session in v0.1, launched from a selected session folder.

#### Scenario: Create with Penggie succeeds
- **WHEN** the user activates `Create with Penggie` with a selected session folder and Codex CLI is available
- **THEN** the app launches one real Codex CLI process in a Ghostty-backed PTY using the selected folder as the working directory and enters Reading

#### Scenario: Second simultaneous session is not created
- **WHEN** a Codex session is already active
- **THEN** the app does not create an additional concurrent local session in v0.1

### Requirement: Codex CLI is the backend
The system SHALL use the real Codex CLI as the agent backend.

#### Scenario: User submits a prompt
- **WHEN** the user submits ordinary chat text from Reading
- **THEN** the text is sent to the real Codex CLI through the active PTY

### Requirement: Close Session ends the active session
The system SHALL allow the user to close the current Codex session.

#### Scenario: User closes session
- **WHEN** the user activates `Close Session`
- **THEN** the active Codex session is ended and the app returns to the Penggie start/connect screen

### Requirement: New Chat restarts the same-window session
The system SHALL define `New Chat` as a same-window restart of the single Codex session.

#### Scenario: User starts a new chat
- **WHEN** the user activates `New Chat`
- **THEN** the app ends the current Codex PTY and starts a fresh Codex PTY in the same window

#### Scenario: New Chat does not imply multi-window
- **WHEN** `New Chat` is used in v0.1
- **THEN** the app does not require multi-window or multi-session management

### Requirement: Terminal interaction surfaces preserve one active PTY
The system SHALL keep all terminal-owned interaction surface projections and inputs bound to the single active Codex/Ghostty PTY.

#### Scenario: Reading projects a terminal-owned surface
- **WHEN** Reading renders resume, slash, model, effort, approval, permission, or generic terminal choice UI
- **THEN** the rows, selected state, and confirmation state are derived from the active Codex/Ghostty session rather than a secondary process or local business-state cache

#### Scenario: User confirms a terminal-owned choice
- **WHEN** the user confirms a fresh, reliable, exactly-one terminal-owned choice from Reading
- **THEN** Penggie sends the confirmation to the same active Codex PTY used by Raw Terminal

#### Scenario: User switches views during a picker
- **WHEN** the user switches between Reading and Raw Terminal while a terminal-owned surface is active
- **THEN** both views continue observing and controlling the same Codex PTY without restarting Codex or duplicating the surface state

### Requirement: P0 foundation work preserves one Codex session
The system SHALL keep the first terminal UX QA foundation bound to one real Codex CLI process and Ghostty PTY.

#### Scenario: Fixture or test uses terminal state
- **WHEN** a fixture, test, or manual QA scenario asserts terminal-owned rows, selected state, prompt readiness, approval, permission, or Raw Terminal parity
- **THEN** it treats the live Codex/Ghostty terminal frame as the authority and does not introduce a separate user-visible Codex session

#### Scenario: Local mirror is proposed
- **WHEN** foundation work proposes a local command list, model list, resume list, approval list, permission list, selected index, or second runtime as implementation support
- **THEN** the work is rejected unless the data is explicitly diagnostic-only and cannot drive user-visible state or confirmation

### Requirement: P0 foundation work gates unsafe confirmation
The system SHALL ensure unsafe terminal-owned confirmation remains blocked in the first implementation foundation.

#### Scenario: Confirmation is tested
- **WHEN** Enter, click, or accessibility activation is tested on a terminal-owned choice
- **THEN** the action confirms only when the current terminal frame proves a fresh exactly-one confirmable selected row

#### Scenario: Confirmation is unsafe
- **WHEN** selected-row evidence is stale, missing, ambiguous, or low confidence
- **THEN** the action is blocked or consumed and does not fall through to ordinary composer submission

### Requirement: P0 implementation preserves terminal-owned state authority
The system SHALL keep Codex CLI and the embedded Ghostty terminal frame as the source of truth for terminal-owned interaction state during the first P0 implementation slice.

#### Scenario: Native projection renders a selectable list
- **WHEN** Reading renders resume, slash, model, effort, approval, or permission rows natively
- **THEN** the row list, selected row, confidence, and confirmability come from the current terminal frame and not from a local mirror list or selected index

#### Scenario: Mode switch occurs
- **WHEN** the user switches Reading to Raw Terminal or Raw Terminal to Reading
- **THEN** Penggie does not start a second Codex process, replace the Ghostty session, or fork terminal-owned state

#### Scenario: Implementation proposes local state authority
- **WHEN** a code change introduces a local command/model/resume/approval/permission list, local selected index, or second user-visible Codex runtime
- **THEN** the change is rejected unless the state is diagnostic-only and cannot drive user-visible selection, confirmation, or session routing

### Requirement: Foundation repairs preserve one Codex PTY
The system SHALL apply embedded Ghostty environment, theme, and screen-model foundation changes without creating additional Codex sessions or replacing the active PTY.

#### Scenario: Terminal foundation is initialized
- **WHEN** Penggie starts Codex through embedded Ghostty
- **THEN** the environment, theme, and screen-model configuration are applied to the same single Codex process and Ghostty surface used by Reading and Raw Terminal

#### Scenario: User switches views after foundation changes
- **WHEN** the user switches between Reading and Raw Terminal
- **THEN** both views continue to observe the same active Codex PTY and Ghostty surface

### Requirement: Codex remains the source of TUI-owned state
The system SHALL keep Codex and the embedded terminal as the source of keyboard-owned TUI state.

#### Scenario: Resume picker is shown
- **WHEN** Penggie projects the Codex resume picker natively
- **THEN** the resume rows, filter text, sort text, and selected-row facts are derived from the active Codex/Ghostty terminal state

#### Scenario: TUI navigation occurs
- **WHEN** the user presses navigation or confirmation keys in a Codex-owned TUI surface
- **THEN** the input is routed to the active Codex PTY rather than applied to a Penggie-maintained selected index

### Requirement: Session folder is selected before launch
The system SHALL determine the Codex working directory before launching the Codex process.

#### Scenario: No folder is selected
- **WHEN** the user has not selected a session folder on the start screen
- **THEN** the app does not launch Codex as an active session

#### Scenario: User selects a folder
- **WHEN** the user chooses a readable local folder before launch
- **THEN** the app treats that folder as the pending working directory for the next Codex session

#### Scenario: Remembered folder exists
- **WHEN** Penggie has a remembered folder from a previous run and that folder is still readable
- **THEN** the app may preselect it but still displays it before launch

### Requirement: Active session folder is immutable
The system SHALL treat the Codex working directory as immutable for an active session.

#### Scenario: Session is active
- **WHEN** a Codex session is already running
- **THEN** the app displays the active session folder as read-only context rather than a mutable setting

#### Scenario: User wants a different folder
- **WHEN** the user needs to use a different working directory
- **THEN** the app requires starting a new Codex session instead of changing the active PTY working directory in place
