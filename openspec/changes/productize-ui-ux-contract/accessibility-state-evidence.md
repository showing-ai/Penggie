# Accessibility State Evidence

Task: `7.2 Implement or verify accessibility labels, hints, values, roles, selected states, disabled/unavailable states, syncing states, expanded/collapsed states, and destructive confirmation labels.`

## Scope

This evidence closes the source-backed accessibility state portion of task 7.2. It does not claim a live VoiceOver pass; live VoiceOver traversal, dynamic announcements, Dynamic Type, and reduced motion remain covered by tasks 7.1, 7.3, 7.4, and 7.5.

## Verified Source Coverage

### Setup And Start

- `PenggieStartView` exposes the selected provider with `.accessibilityLabel("Codex selected as local agent CLI")`.
- The project folder row exposes `.accessibilityLabel("Choose Project Folder")`, `.accessibilityValue(session.sessionFolderDisplayPath)`, and a state-sensitive hint that distinguishes editable setup from startup-disabled state.
- Folder status text is combined into one accessibility element with `.accessibilityElement(children: .combine)` and `.accessibilityLabel(folderStatusText)`.
- `Create with Penggie` exposes `.accessibilityLabel("Create with Penggie")` and `.accessibilityHint(createHelpText)`, so unavailable states can announce the blocking reason.

### Reading And Raw Terminal Visibility

- `PenggieSessionView` keeps Reading and Raw Terminal in the same session container while hiding the inactive surface from accessibility traversal with `.accessibilityHidden(session.state == .terminal)` and `.accessibilityHidden(session.state != .terminal)`.
- This preserves the same Codex/Ghostty session while preventing VoiceOver from traversing both surfaces at once.

### Terminal-Owned Candidate Rows

- `PenggieTerminalSurfaceCandidateRowView` isolates each candidate row with `.accessibilityElement(children: .ignore)`.
- The row label is the terminal-projected row text via `.accessibilityLabel(candidate.text)`.
- The value is centralized through `PenggieTerminalSurfaceCandidateAccessibility.value(...)`, covering selected/not selected, confirmable/unavailable, and selection-syncing state.
- The hint is centralized through `PenggieTerminalSurfaceCandidateAccessibility.hint(...)`, covering Enter confirmation, terminal syncing, and unavailable confirmation.
- The selected row exposes a non-color affordance with `.accessibilityAddTraits(isSelected ? [.isSelected] : [])` and the visual `›` marker. The marker remains display-only; terminal evidence still owns selected state.

### Syncing And Unsafe Confirmation

- `PenggieTerminalInputPolicy.commandDecision(.enter, surface:)` blocks unsafe Enter when there is no fresh exactly-one confirmable terminal-owned selection.
- `PenggieTerminalSurfaceStatusCopy.syncingSelection` explains the syncing state without hiding useful candidate rows.
- `PenggieTerminalInteractionSurfaceTests.candidateAccessibilityValuesDescribeSelectionConfirmabilityAndSyncing` verifies selected, confirmable, unavailable, and syncing accessibility values and hints.
- `PenggieTerminalInteractionSurfaceTests.unsafeEnterConsumesEventInsteadOfFallingThroughToComposerSubmission` verifies unsafe Enter is consumed instead of falling through to composer submission.

### Disclosure State

- Reading disclosure rows expose `.accessibilityLabel(disclosure.summary)` and `.accessibilityValue(isExpanded ? "Expanded" : "Collapsed")`.

### Destructive Confirmations

- The root view presents New Chat and Close Session confirmations with `.alert(item: $session.pendingConfirmation)`.
- The alert uses `confirmation.title`, `confirmation.message`, and `confirmation.confirmationButtonTitle`.
- The destructive button is `primaryButton: .destructive(Text(confirmation.confirmationButtonTitle))`.
- The cancel button routes to `session.cancelConfirmation()` and preserves the current session.
- The confirm button routes to `session.confirm(confirmation)`, which is the explicit lifecycle boundary for ending or replacing the active session.

## Automated Evidence

- `scripts/qa/check-accessibility-smoke-source.sh` verifies setup labels/hints/values, Reading/Raw Terminal accessibility visibility, terminal-owned candidate row value/hint/selected traits, disclosure expanded/collapsed state, destructive confirmation labels/actions, and the manual QA/release evidence gates.
- `PenggieTerminalInteractionSurfaceTests.candidateAccessibilityValuesDescribeSelectionConfirmabilityAndSyncing` verifies candidate row state strings.
- `PenggieTerminalInteractionSurfaceTests.unsafeEnterConsumesEventInsteadOfFallingThroughToComposerSubmission` verifies unsafe confirmation does not become composer input.

## Non-Goals

- Do not synthesize Codex-owned selection state for accessibility.
- Do not maintain local selected indexes for accessibility state.
- Do not launch a second Codex session for accessibility audit.
- Do not treat this source-backed evidence as a completed live VoiceOver, Dynamic Type, reduced motion, or dynamic announcement pass.
