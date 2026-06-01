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
The system SHALL display Codex output as Reading transcript content after interaction begins, using Display AST projection when available and preserving terminal-derived fallback when classification confidence is low.

#### Scenario: User submits first prompt
- **WHEN** the user submits a prompt
- **THEN** Reading displays the submitted user input and Codex output in transcript flow using Display AST blocks where they are confidently derived from terminal display state

#### Scenario: Conversation content exists
- **WHEN** Reading has submitted prompt or transcript content
- **THEN** the composer remains available for continued chat input without switching to Raw Terminal

#### Scenario: Display AST classification degrades
- **WHEN** a Codex output shape is unrecognized, low confidence, or affected by an unsupported CLI/theme change
- **THEN** Reading falls back to raw/preformatted terminal-derived display while keeping Raw Terminal available for the same PTY session

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

#### Scenario: Slash commands are input-driven
- **WHEN** the composer footer no longer shows a `/ commands` control
- **THEN** typing `/` remains the way to open the native slash overlay

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

### Requirement: Display fallback foundation has executable fixtures
The system SHALL add fixture coverage for Display AST fallback before broad Reading UI productization begins.

#### Scenario: Long session fixture is reviewed
- **WHEN** long-session fixture coverage is reviewed
- **THEN** it includes completed turns, later output, working/tool rows, and expected stable Reading blocks without duplicate or polluted turns

#### Scenario: CJK table and code fixture is reviewed
- **WHEN** terminal-sensitive fixture coverage is reviewed
- **THEN** it includes CJK prose, CJK-aligned rows, table or box drawing, code/preformatted content, and expected fallback that preserves visible terminal evidence

#### Scenario: Low-confidence display fixture is reviewed
- **WHEN** a fixture cannot prove semantic Reading classification
- **THEN** it asserts raw/preformatted fallback rather than invented Markdown or hidden output

### Requirement: Reading transcript pollution is regression-tested
The system SHALL test that transient terminal UI rows are not sealed as assistant answer content.

#### Scenario: Terminal footer appears
- **WHEN** terminal footer, status line, model line, active input row, slash menu, resume picker, approval prompt, or permission prompt appears in terminal output
- **THEN** fixture expectations prevent those rows from becoming ordinary assistant answer blocks

#### Scenario: Raw fallback is required
- **WHEN** terminal-derived content is low confidence but visible to the user
- **THEN** Reading preserves it through raw/preformatted fallback and keeps the Raw Terminal audit path available

### Requirement: Native TUI projections use terminal-owned style facts
The system SHALL derive native Codex TUI projections from terminal marker and style facts exported by the embedded Ghostty screen model.

#### Scenario: Resume picker marker is visible
- **WHEN** the current viewport contains exactly one visible Codex resume picker marker
- **THEN** the native resume picker projects the corresponding row as selected

#### Scenario: Screen model style identifies current row
- **WHEN** the visible marker is unavailable and the screen model exposes a unique current-row style among candidate resume rows
- **THEN** the native resume picker projects that row as selected

#### Scenario: Selection facts are ambiguous
- **WHEN** terminal marker and style facts do not identify exactly one selected resume row
- **THEN** the native resume picker shows projected rows without confirming a resume through Enter

### Requirement: Native TUI projections do not maintain local selected indexes
The system SHALL NOT maintain local selected-index state for Codex-owned keyboard TUI surfaces.

#### Scenario: User navigates resume picker
- **WHEN** the user presses arrow keys, Tab, search text, Enter, or Esc in the native resume picker
- **THEN** Penggie sends input to Codex and waits for terminal-owned marker/style facts to update the projection

#### Scenario: User navigates slash overlay
- **WHEN** the user navigates a native slash or continuation menu
- **THEN** Penggie sends input to Codex and derives the selected row from terminal-owned marker/style facts

### Requirement: Resume picker and slash overlay share selection projection primitives
The system SHALL share terminal-owned selected line or region inference primitives across native Codex TUI projections while preserving each surface's parser.

#### Scenario: Resume picker rows are parsed
- **WHEN** Penggie parses resume picker rows
- **THEN** it uses resume-specific row parsing for age and title while using shared terminal selection projection for selected-row inference

#### Scenario: Slash suggestions are parsed
- **WHEN** Penggie parses slash suggestions or continuation menus
- **THEN** it uses slash-specific parsing and input anchoring while using shared terminal selection projection for selected-row inference where applicable

### Requirement: Reading compiles terminal display into Display AST
The system SHALL compile Ghostty terminal display state into a Penggie Display AST before rendering Reading transcript content.

#### Scenario: Terminal output contains Markdown-ish visible markers
- **WHEN** Codex output includes visible markers such as list prefixes, backticks, fences, or `**` emphasis markers
- **THEN** Reading preserves those visible markers as display evidence in the Display AST rather than treating the row as plain undifferentiated text

#### Scenario: Terminal output contains styled spans
- **WHEN** Ghostty screen state includes foreground, background, bold, faint, underline, inverse, or selection styles
- **THEN** Reading may use those styles as auxiliary display hints without treating color or style alone as a semantic contract

#### Scenario: Terminal output cannot be confidently classified
- **WHEN** the Display AST compiler cannot classify terminal output with sufficient confidence
- **THEN** Reading preserves the visible text as a raw or preformatted fallback block rather than hiding or over-interpreting the output

### Requirement: Display AST preserves source traceability
The system SHALL retain enough source metadata on Display AST nodes to explain and debug terminal-to-Reading projection decisions.

#### Scenario: A Display AST block is produced
- **WHEN** Reading creates a Display AST block from terminal state
- **THEN** the block records source row/column range, source fingerprint, confidence, and rule hits

#### Scenario: A fallback block is produced
- **WHEN** Reading produces a low-confidence fallback block
- **THEN** the block records a fallback reason and preserves all visible source text

### Requirement: Reading uses cell-aware rendering for terminal-sensitive blocks
The system SHALL render terminal-sensitive output with cell-aware layout when proportional text would damage readability.

#### Scenario: Output contains table or box drawing content
- **WHEN** terminal output contains pipe tables, ASCII tables, box drawing tables, or aligned columnar output
- **THEN** Reading renders the content as table/preformatted display with preserved column alignment

#### Scenario: Output mixes CJK and ASCII content
- **WHEN** terminal output contains CJK wide characters mixed with ASCII in aligned or preformatted content
- **THEN** Reading preserves terminal cell alignment rather than relying on proportional SwiftUI text layout

### Requirement: Agent-specific terminal rules are isolated from generic terminal rules
The system SHALL separate generic terminal display facts from Codex-specific display conventions.

#### Scenario: Generic terminal facts are extracted
- **WHEN** Penggie analyzes Ghostty screen state
- **THEN** generic extraction identifies visible text, rows, columns, indentation, wrapping, dividers, boxes, and style summaries without relying on Codex-specific words

#### Scenario: Codex-specific display is interpreted
- **WHEN** Penggie classifies Codex display conventions such as `Working`, `Worked for`, slash menus, model menus, or Codex footer metadata
- **THEN** those interpretations are performed by a Codex-specific adapter rule pack

### Requirement: Display AST does not replace native interaction source of truth
The system SHALL keep native slash/model interaction sourced from the real terminal screen model and PTY key path.

#### Scenario: Slash menu appears
- **WHEN** the user is in native slash interaction
- **THEN** the native overlay is rendered from current Ghostty screen model rows and not from a local command table or Display AST command list

#### Scenario: Historical slash text appears in transcript
- **WHEN** prior transcript content includes `/model`, slash commands, or examples of slash usage
- **THEN** Reading does not treat that historical content as an active native overlay

#### Scenario: User navigates a native menu
- **WHEN** the user presses arrow keys, Enter, Esc, or Backspace during native interaction
- **THEN** the key event is sent to the PTY and Penggie does not maintain local selected-index state

### Requirement: Reading active response progress is locally stable
The system SHALL display active response progress from Penggie turn metadata rather than relying on terminal-projected working text.

#### Scenario: Submitted prompt has no visible output yet
- **WHEN** a user submits a prompt and Codex has not produced visible answer content
- **THEN** Reading displays a `Working... Ns` response header whose elapsed seconds advance while the turn remains active

#### Scenario: Terminal working text does not repaint
- **WHEN** the terminal projection contains stale transient text such as `Working... 0s`
- **THEN** Reading still displays the locally computed active response duration as the primary progress indicator

#### Scenario: Terminal activity details exist
- **WHEN** terminal-derived activity rows such as search or tool progress are captured during an active turn
- **THEN** Reading keeps those details available behind the active response disclosure without replacing the local progress timer

### Requirement: Reading completed response duration is frozen
The system SHALL freeze response duration once a Reading turn completes.

#### Scenario: Codex provides completed duration
- **WHEN** Codex output includes a completed duration such as `Worked for 17s`
- **THEN** Reading displays that duration for the completed response and does not keep incrementing it

#### Scenario: Codex duration is unavailable
- **WHEN** a turn completes without a terminal-derived completed duration
- **THEN** Reading displays a fallback `Worked for Ns` duration computed from local turn timing and keeps it stable

### Requirement: Reading progress updates avoid full transcript re-blockization
The system SHALL update active response elapsed time without reparsing the full terminal projection every second.

#### Scenario: Active turn timer ticks
- **WHEN** one second passes while a Reading turn is active
- **THEN** the visible progress duration can update without re-running full terminal projection or blockization work

#### Scenario: Terminal output changes
- **WHEN** Codex produces new terminal output
- **THEN** Reading updates terminal-derived content through the existing projection path

### Requirement: Composer footer avoids fake or duplicated context
The system SHALL avoid fake command affordances and duplicated session context in the Reading composer footer.

#### Scenario: Reading composer is shown
- **WHEN** the Reading composer is visible during an active session
- **THEN** the footer does not show `/ commands` as a clickable-looking control

#### Scenario: Session folder context is already in titlebar
- **WHEN** the titlebar shows the active session folder
- **THEN** the composer footer does not duplicate that folder path
