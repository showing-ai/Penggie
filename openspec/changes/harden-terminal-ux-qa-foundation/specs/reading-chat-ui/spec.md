## ADDED Requirements

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
