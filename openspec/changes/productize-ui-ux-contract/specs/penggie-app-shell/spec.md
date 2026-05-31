## ADDED Requirements

### Requirement: App shell implementation milestones cover setup and lifecycle
The system SHALL productize setup, launch, active session, exit, and recovery states through explicit implementation milestones and acceptance criteria.

#### Scenario: Setup milestone is planned
- **WHEN** the setup/start surface is implemented or refined
- **THEN** the task covers folder validity, `Create with Penggie`, disabled/enabled states, keyboard order, VoiceOver labels, invalid folder recovery, and no terminal startup noise leakage

#### Scenario: Create action is validated
- **WHEN** the user activates `Create with Penggie`
- **THEN** the implementation validates that the action starts the intended create/new-session path and does not accidentally enter a resume picker unless Codex itself is launched in resume mode or the user explicitly chooses a resume path

#### Scenario: Lifecycle milestone is planned
- **WHEN** launch, checking, active, exited, failed, New Chat, or Close Session behavior is changed
- **THEN** the task identifies the expected visible state, allowed actions, blocked actions, keyboard owner, Raw Terminal availability, recovery path, and manual QA steps

### Requirement: App shell implementation preserves low-chrome session identity
The system SHALL implement shell polish without turning active work into a toolbar-heavy interface or hiding project/session identity.

#### Scenario: Active session chrome is reviewed
- **WHEN** Reading or Raw Terminal is visible
- **THEN** the shell shows project folder identity, destination mode, and session-level action availability without adding competing provider chrome or destructive always-visible primary buttons

#### Scenario: Chrome visuals are reviewed
- **WHEN** light mode, dark mode, Reading, Raw Terminal, setup, and recovery states are visually reviewed
- **THEN** topbar, canvas, separators, icon states, focus rings, and titlebar safe area use approved theme tokens and do not create unintended visual seams

### Requirement: App shell QA includes recovery and destructive actions
The system SHALL verify recovery and destructive session actions through manual QA and testable acceptance criteria.

#### Scenario: Recovery state is tested
- **WHEN** missing Codex, launch failure, invalid folder, process exit, or projection degraded state is triggered
- **THEN** the user sees specific copy, a safe next action, correct Raw Terminal availability, and no enabled prompt path to a dead or unavailable process

#### Scenario: Destructive action is tested
- **WHEN** the user requests New Chat or Close Session
- **THEN** the implementation presents confirmation, traps focus inside the confirmation, preserves the active session until confirmation, and restores the previous focus owner on cancel
