## ADDED Requirements

### Requirement: Reading implementation milestones preserve transcript hierarchy
The system SHALL implement Reading transcript productization through explicit roles, stability checks, and fallback behavior.

#### Scenario: Transcript hierarchy is planned
- **WHEN** Reading transcript rendering is changed
- **THEN** the task identifies user prompt, working/tool summary, assistant answer, collapsible detail, and raw/preformatted fallback roles and includes acceptance criteria for each role

#### Scenario: Completed turns are validated
- **WHEN** repaint, resize, Raw Terminal switching, later output, or long-session updates occur
- **THEN** completed turns remain stable and do not duplicate, disappear, reorder, rewrite, or absorb active terminal-owned surfaces

#### Scenario: Terminal-sensitive output is validated
- **WHEN** CJK, tables, box drawing, code, warnings, tool-heavy output, or low-confidence display is rendered
- **THEN** Reading uses Display AST or raw/preformatted fallback to preserve visible evidence and includes fixture coverage

### Requirement: Composer implementation milestones cover IME and focus
The system SHALL productize composer behavior with IME, focus, paste, keyboard, and terminal-owned handoff acceptance criteria.

#### Scenario: IME behavior is changed
- **WHEN** composer text handling, placeholder behavior, Enter, Shift-Enter, paste, or send enablement is changed
- **THEN** the task includes manual IME QA for marked text, committed text, placeholder visibility, draft preservation, and submit prevention while marked text exists

#### Scenario: Focus behavior is changed
- **WHEN** Reading, Raw Terminal, terminal-owned overlay, confirmation, setup, or recovery transitions are changed
- **THEN** the task defines expected first responder, keyboard owner, focus restoration, VoiceOver order, and cases where composer focus must not be restored

#### Scenario: Slash handoff is validated
- **WHEN** slash or command-prefix input begins from the composer
- **THEN** Penggie sends input to Codex, switches to terminal-owned projection, and does not keep local composer selection or command state as the source of truth

### Requirement: Reading implementation includes accessibility and dynamic state announcements
The system SHALL include accessibility labels, values, focus behavior, and announcements in Reading productization work.

#### Scenario: Reading accessibility is reviewed
- **WHEN** a Reading milestone changes transcript blocks, composer, tool disclosure, fallback, or terminal-owned overlay placement
- **THEN** VoiceOver reading order, role names, disclosure state, selected/unavailable/syncing values, keyboard-only completion, and reduced motion behavior are manually checked

#### Scenario: Dynamic announcement is reviewed
- **WHEN** Codex starts working, a tool runs, approval is required, permission is required, selection becomes low confidence, projection degrades, launch fails, or the process exits
- **THEN** the implementation defines the announcement content and whether it is polite or assertive

### Requirement: Reading visual QA covers density and theme
The system SHALL validate Reading visual polish through repeatable light/dark, density, and content-stress scenarios.

#### Scenario: Visual capture is reviewed
- **WHEN** Reading visuals are changed
- **THEN** QA includes setup, empty Reading, long transcript, tool-heavy turn, CJK/table/code fallback, composer focus, overlay active, recovery, light mode, dark mode, narrow window, and large text captures

#### Scenario: Token usage is reviewed
- **WHEN** Reading visuals are changed
- **THEN** feature views use approved theme tokens for backgrounds, text, borders, focus, selected state, disabled state, and shadows instead of scattered raw colors or system backgrounds
