## ADDED Requirements

### Requirement: Raw Terminal round trip is included in P0 manual QA
The system SHALL verify same-session Raw Terminal parity as part of the first terminal UX foundation.

#### Scenario: Ordinary Reading round trip is tested
- **WHEN** the user switches from Reading to Raw Terminal and back during an ordinary active session
- **THEN** QA verifies the same process, cwd, Ghostty session, prompt readiness, draft state, and transcript stability

#### Scenario: Terminal-owned surface round trip is tested
- **WHEN** the user switches from Reading to Raw Terminal and back while slash, model, resume, approval, or permission state is active
- **THEN** QA verifies the same rows, selected state, confirmation state, keyboard owner, and PTY control path

#### Scenario: Low-confidence projection is tested
- **WHEN** Reading reports stale, ambiguous, or low-confidence terminal-owned projection
- **THEN** QA verifies Raw Terminal remains available and shows the same underlying terminal state when an inspectable session exists
