## ADDED Requirements

### Requirement: Raw Terminal is the same-session audit and control surface
The system SHALL expose Raw Terminal as the faithful Ghostty view of the same live Codex session used by Reading.

#### Scenario: User switches from Reading to Raw Terminal
- **WHEN** the user opens Raw Terminal
- **THEN** Raw Terminal shows the same Codex process, cwd, model state, terminal scrollback, active terminal-owned surface, and process state rather than a restarted or forked session

#### Scenario: User switches back to Reading
- **WHEN** the user returns from Raw Terminal to Reading
- **THEN** Penggie does not replay, duplicate, restart, fork, or lose the session, transcript, or active terminal-owned state

#### Scenario: Terminal-owned picker is active
- **WHEN** slash, model, resume, approval, permission, or modal choice state is active
- **THEN** Raw Terminal remains a valid visual reference for the same rows, selection, and confirmation state projected by Reading

### Requirement: Raw Terminal remains available for uncertain projection
The system SHALL make Raw Terminal available whenever Reading projection cannot confidently represent terminal state.

#### Scenario: Reading display confidence is low
- **WHEN** Reading cannot confidently classify output, preserve layout, or prove selected state
- **THEN** Penggie keeps the visible terminal-derived content available and allows the user to inspect the same session in Raw Terminal

#### Scenario: Process has exited after a terminal session existed
- **WHEN** Codex exits but the terminal surface remains inspectable
- **THEN** Raw Terminal may remain available so the user can inspect the final terminal state

### Requirement: Raw Terminal is not a separate Ghostty product shell
The system SHALL keep Raw Terminal inside Penggie's product shell while preserving terminal rendering fidelity.

#### Scenario: Raw Terminal is visible
- **WHEN** the user is in Raw Terminal
- **THEN** Penggie chrome remains active, Ghostty app product chrome is not exposed, and terminal colors/styles are not flattened into unrelated Reading styling
