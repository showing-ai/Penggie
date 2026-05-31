## ADDED Requirements

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
