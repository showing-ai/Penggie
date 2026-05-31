## ADDED Requirements

### Requirement: Raw Terminal remains the visual reference for terminal-owned surfaces
The system SHALL treat Raw Terminal as the same-session visual reference for terminal-owned interaction surfaces.

#### Scenario: Reading highlights a candidate row
- **WHEN** Reading projects a selected row for a terminal-owned interaction surface
- **THEN** the highlighted row corresponds to the same terminal row indicated by marker or style in Raw Terminal for the same Ghostty frame

#### Scenario: Reading cannot prove selected-row parity
- **WHEN** terminal facts do not allow Reading to prove which Raw Terminal row is selected
- **THEN** Reading shows a low-confidence state rather than a conflicting highlight while Raw Terminal remains available for direct inspection

#### Scenario: Raw Terminal is visible
- **WHEN** Raw Terminal mode is active during a resume picker, slash continuation, model picker, effort picker, approval prompt, or permission prompt
- **THEN** the user sees and controls the same terminal-owned surface that Reading would project natively
