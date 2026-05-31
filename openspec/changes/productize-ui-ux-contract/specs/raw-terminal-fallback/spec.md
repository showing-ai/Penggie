## ADDED Requirements

### Requirement: Raw Terminal productization validates same-session audit and control
The system SHALL include Raw Terminal parity checks in product-grade UI/UX implementation milestones.

#### Scenario: View switch is tested
- **WHEN** the user switches from Reading to Raw Terminal and back
- **THEN** the same Codex process, cwd, Ghostty session, scrollback, terminal-owned surface, process state, draft state, and transcript state are preserved

#### Scenario: Terminal-owned surface is active
- **WHEN** Raw Terminal is opened while slash, model, resume, approval, permission, or modal choice state is active
- **THEN** Raw Terminal shows and controls the same terminal-owned state that Reading projects

#### Scenario: Projection is uncertain
- **WHEN** Reading has low-confidence display or selected-row projection
- **THEN** Raw Terminal remains available for audit whenever an inspectable terminal surface exists

### Requirement: Raw Terminal productization covers copy, paste, mouse, and focus
The system SHALL include control-surface QA for Raw Terminal keyboard and pointer behavior.

#### Scenario: Text selection is tested
- **WHEN** the user selects terminal text with mouse or platform-supported modifier behavior
- **THEN** the selection, copy action, pasteboard result, and interaction with Codex mouse reporting are documented and verified

#### Scenario: Raw Terminal focus is tested
- **WHEN** Raw Terminal becomes visible
- **THEN** the Ghostty host receives keyboard focus and the local Reading composer does not capture terminal keystrokes

#### Scenario: Returning from Raw Terminal is tested
- **WHEN** the user returns to Reading
- **THEN** focus restores to the terminal-owned key capture if a surface is active, otherwise to the composer only when the session is ready for prompt input

### Requirement: Raw Terminal productization covers visual and theme parity
The system SHALL validate Raw Terminal visuals against Penggie shell and terminal renderer contracts.

#### Scenario: Terminal theme is reviewed
- **WHEN** light mode or dark mode is active
- **THEN** Raw Terminal canvas, titlebar chrome, active input, cursor, selection, ANSI palette, and native overlay selected state are visually coherent without flattening terminal style fidelity

#### Scenario: Theme implementation is reviewed
- **WHEN** terminal scene or renderer palette code changes
- **THEN** QA verifies that Ghostty configuration, host fallback background, window chrome, and native overlay tokens are generated from the approved theme model rather than scattered local color patches
