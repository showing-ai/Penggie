## ADDED Requirements

### Requirement: Embedded Codex environment is explicit and color-capable
The system SHALL launch Codex through embedded Ghostty with an explicit terminal/color environment contract.

#### Scenario: Codex surface starts
- **WHEN** Penggie creates an embedded Ghostty surface for Codex
- **THEN** the launched Codex process receives a color-capable terminal environment without inheriting host-level color-disabling variables

#### Scenario: Environment is diagnosed
- **WHEN** Raw Terminal color behavior is investigated
- **THEN** Penggie provides or documents a repeatable probe for `TERM`, `COLORTERM`, `TERM_PROGRAM`, `NO_COLOR`, `CLICOLOR`, `CLICOLOR_FORCE`, and `FORCE_COLOR`

#### Scenario: Per-surface overrides are available
- **WHEN** Penggie needs to control Codex color-related environment variables
- **THEN** the overrides are applied through the embedded surface environment contract rather than relying on long-lived global process environment mutation

### Requirement: Raw Terminal color pipeline follows Ghostty theme semantics
The system SHALL configure embedded Ghostty terminal colors through Ghostty theme semantics unless a probe proves a narrower override is required.

#### Scenario: Embedded config is generated
- **WHEN** Penggie writes Ghostty config for the embedded terminal
- **THEN** top-level `background`, `foreground`, and `palette` overrides do not suppress the selected Ghostty terminal theme

#### Scenario: Contrast is configured
- **WHEN** Penggie sets terminal minimum contrast
- **THEN** the value preserves ANSI foreground, faint, bold, inverse, and selection distinctions unless a higher value is justified by verification

#### Scenario: System appearance changes
- **WHEN** macOS effective appearance changes between light and dark
- **THEN** Penggie synchronizes the corresponding color scheme to embedded Ghostty app and active surfaces

### Requirement: Embedded renderer normalizes known TUI control RGB backgrounds
The system SHALL allow Penggie embedded Ghostty surfaces to map known explicit RGB terminal-control backgrounds to Penggie terminal scene tokens when theme semantics cannot affect those cells.

#### Scenario: Active input uses explicit RGB
- **WHEN** Codex renders a TUI active input row using the known explicit RGB control background observed in diagnostics
- **THEN** the embedded renderer displays that background using the current Penggie terminal scene active-input color

#### Scenario: Raw style facts are preserved
- **WHEN** Penggie reads the screen model for a normalized row
- **THEN** the raw terminal style facts still report the original RGB cell state rather than a fabricated business-level selection

#### Scenario: Arbitrary truecolor remains terminal-owned
- **WHEN** terminal output uses explicit RGB that is not a configured known TUI control background
- **THEN** the embedded renderer preserves that RGB output instead of applying Penggie semantic colors

### Requirement: Screen model exports terminal style facts
The system SHALL expose terminal viewport text and cell style facts sufficient for native projections to infer terminal-owned selection.

#### Scenario: Screen model is read
- **WHEN** Penggie reads the embedded Ghostty screen model
- **THEN** the model includes viewport row text and structured style data for foreground, background, bold, faint, inverse, and text/background cell coverage

#### Scenario: TUI row is highlighted by style
- **WHEN** Codex renders a selected TUI row using SGR style rather than a business-level selected flag
- **THEN** the screen model exposes the underlying terminal style facts without inventing a Codex-specific selected-row property

#### Scenario: Background extends beyond text
- **WHEN** a terminal row has background styling on cells without text
- **THEN** the screen model preserves that background coverage so native projections can distinguish row highlights

### Requirement: Terminal selection terms are not overloaded
The system SHALL distinguish Ghostty text selection from application TUI current-row styling.

#### Scenario: User selects terminal text
- **WHEN** Ghostty has an active text selection
- **THEN** the screen model may expose it as terminal text selection data with explicit naming

#### Scenario: Codex picker changes current row
- **WHEN** Codex changes the current row in a TUI picker
- **THEN** Penggie derives that current row from terminal marker/style facts and does not treat Ghostty text selection as the picker selected row
