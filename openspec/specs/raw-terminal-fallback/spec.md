# raw-terminal-fallback Specification

## Purpose
Define Raw Terminal as a same-PTY fallback view inside the Penggie shell, not the default active-session experience.
## Requirements
### Requirement: Raw Terminal is a fallback view
The system SHALL expose Raw Terminal as a fallback view rather than the default active-session UI.

#### Scenario: Codex starts successfully
- **WHEN** the active Codex session begins
- **THEN** Reading is shown by default and Raw Terminal is available only through an explicit view switch

### Requirement: Raw Terminal uses the same PTY
The system SHALL render Raw Terminal from the same Ghostty surface and Codex PTY used by Reading.

#### Scenario: User switches to Terminal
- **WHEN** the user switches from Reading to Terminal
- **THEN** the Raw Terminal shows the current state of the same active Codex PTY

#### Scenario: User switches back to Reading
- **WHEN** the user switches from Terminal back to Reading
- **THEN** Reading resumes by reading the same PTY/screen state without restarting Codex

#### Scenario: User switches while terminal-owned surface is active
- **WHEN** the user switches Reading to Raw Terminal and back while resume, slash, model, effort, approval, or permission state is active
- **THEN** Penggie keeps the same Ghostty session and reprojects the terminal-owned surface from subsequent frames rather than replacing it with local state

### Requirement: Raw Terminal does not expose Ghostty product shell
The system SHALL keep Raw Terminal inside the Penggie app shell.

#### Scenario: Terminal fallback is visible
- **WHEN** Raw Terminal mode is active
- **THEN** the Penggie top bar and window remain visible and Ghostty command palette, split UI, preferences, and update overlay are not presented as product chrome

### Requirement: Raw Terminal requires an active or inspectable session
The system SHALL only expose Raw Terminal when there is a session state to inspect.

#### Scenario: No Codex session exists
- **WHEN** no Codex session has been started
- **THEN** the Terminal fallback is not presented as a primary start option

#### Scenario: Codex session exits
- **WHEN** Codex exits after a session existed
- **THEN** the app may offer Raw Terminal as a way to inspect the same session's terminal state

#### Scenario: Session is still launching
- **WHEN** Penggie is checking Codex or launching the first terminal frame
- **THEN** Raw Terminal is not exposed as an inspectable fallback until a session surface exists and is safe to inspect

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

### Requirement: Raw Terminal is the visual truth for embedded Ghostty
The system SHALL make Raw Terminal a faithful view of the embedded Ghostty surface's rendered terminal state.

#### Scenario: ANSI probe is rendered
- **WHEN** a user or diagnostic prints ANSI foreground, truecolor, faint, bold, and inverse sequences in Raw Terminal
- **THEN** Raw Terminal renders visibly distinct output according to the active Ghostty theme and terminal style pipeline

#### Scenario: Codex TUI uses color
- **WHEN** Codex emits SGR style for a TUI surface
- **THEN** Raw Terminal displays those styles without Penggie flattening them through an unrelated palette or contrast override

### Requirement: Raw Terminal theme follows embedded Ghostty configuration
The system SHALL configure Raw Terminal colors through the same embedded Ghostty theme configuration used by the active surface.

#### Scenario: Light theme is active
- **WHEN** macOS appearance and embedded Ghostty color scheme resolve to light mode
- **THEN** Raw Terminal uses the configured light Ghostty terminal theme

#### Scenario: Dark theme is active
- **WHEN** macOS appearance and embedded Ghostty color scheme resolve to dark mode
- **THEN** Raw Terminal uses the configured dark Ghostty terminal theme

#### Scenario: Theme config is changed
- **WHEN** Penggie changes embedded Ghostty theme configuration
- **THEN** Raw Terminal remains a same-surface fallback and does not restart or duplicate the Codex PTY solely to apply the visual configuration

#### Scenario: Known TUI control row is rendered
- **WHEN** Codex emits a known explicit RGB background for the active input control row
- **THEN** Raw Terminal renders that control row with Penggie's current terminal-scene active input color while preserving ordinary terminal truecolor output

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
