## ADDED Requirements

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

## MODIFIED Requirements

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
