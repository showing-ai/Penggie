## MODIFIED Requirements

### Requirement: Confirmation is gated by terminal-owned selection confidence
The system SHALL allow GUI confirmation only when the active terminal-owned surface has a fresh, reliable, exactly-one confirmable row.

#### Scenario: Exactly one confirmable row exists
- **WHEN** the active surface reports a fresh single selected candidate that is confirmable
- **THEN** Enter or GUI confirm is routed to Codex through the active PTY

#### Scenario: Selection is ambiguous
- **WHEN** the active surface reports no selected row, ambiguous selected rows, or stale selected-row evidence
- **THEN** Enter or GUI confirm is blocked or consumed by Penggie and is not allowed to fall through as ordinary composer text

#### Scenario: Rows are visible but selection is unreliable
- **WHEN** candidate rows are visible and selection confidence is low
- **THEN** Reading shows the rows and a low-confidence or syncing indication instead of hiding the rows or inventing a highlight

#### Scenario: Confirmation waits after navigation
- **WHEN** the user navigates or filters a terminal-owned surface and Penggie has not yet received fresh terminal-frame evidence for the resulting selected row
- **THEN** Enter remains blocked or consumed while useful candidate rows remain visible

### Requirement: Keyboard interaction remains PTY-routed
The system SHALL route terminal-owned surface navigation and editing through the active Ghostty/Codex PTY.

#### Scenario: User navigates a terminal-owned list
- **WHEN** the user presses arrow keys, Tab, Esc, Backspace, or text filter keys in an active terminal-owned surface
- **THEN** Penggie sends the corresponding input to the active Codex PTY and waits for a new terminal frame

#### Scenario: Chat UI renders native rows
- **WHEN** Reading displays a native projection of a terminal-owned surface
- **THEN** the native UI does not mutate local selection in response to navigation keys

#### Scenario: Input is blocked
- **WHEN** a terminal-owned input policy blocks a key because confirmation is unsafe or stale
- **THEN** the key event is consumed and does not continue into ordinary composer input handling

### Requirement: Selected candidate remains visible in native overlays
The system SHALL keep the terminal-owned selected candidate fully visible when Reading renders a native list projection.

#### Scenario: Selected row is below the visible window
- **WHEN** a terminal-owned list has more candidates than the native visible row count and the selected candidate is below the initial window
- **THEN** the native projection scrolls or windows the candidate list so the selected row is fully visible

#### Scenario: Selected row is near a boundary
- **WHEN** the selected row is near the top or bottom of the candidate list
- **THEN** the native projection keeps the selected row fully visible and avoids clipping the selected background, marker, or text

#### Scenario: Selection is unavailable
- **WHEN** rows exist but no selected candidate can be proven
- **THEN** the native projection may show the first useful rows with a syncing indicator, but it does not fake a selected row
