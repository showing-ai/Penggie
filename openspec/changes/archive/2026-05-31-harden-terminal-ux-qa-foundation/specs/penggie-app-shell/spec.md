## ADDED Requirements

### Requirement: P0 manual QA covers setup and lifecycle safety
The system SHALL include setup and lifecycle scenarios in the first product-grade manual QA foundation.

#### Scenario: Create path is tested
- **WHEN** the user activates `Create with Penggie`
- **THEN** QA verifies the app starts the intended create/new-session path and does not enter resume picker unless Codex is explicitly launched in resume mode or the user explicitly chooses resume

#### Scenario: Failure states are tested
- **WHEN** missing Codex, launch failure, invalid folder, process exited with terminal surface, or process exited without terminal surface is triggered
- **THEN** QA verifies specific recovery copy, enabled actions, blocked actions, keyboard owner, and Raw Terminal availability

#### Scenario: Destructive actions are tested
- **WHEN** New Chat or Close Session is invoked
- **THEN** QA verifies confirmation, focus trap, cancel restoration, and no session discard before confirmation
