# Dynamic Announcements Evidence

Task: `7.3 Implement or verify dynamic state announcements for checking, launching, ready, working, tool running, approval required, permission required, projection degraded, selection syncing, process exited, missing Codex, and launch failed.`

## Scope

This evidence closes the source-backed dynamic announcement portion of task 7.3. It does not claim a live VoiceOver pass. Manual VoiceOver QA remains required for auditory timing, verbosity, and usefulness.

## Implementation Evidence

- `PenggieAccessibilityAnnouncementEvent` defines one centralized event vocabulary for:
  - `checkingCodex`
  - `launching`
  - `ready`
  - `working`
  - `toolRunning`
  - `approvalRequired`
  - `permissionRequired`
  - `projectionDegraded`
  - `selectionSyncing`
  - `processExited`
  - `missingCodex`
  - `launchFailed`
- `PenggieAccessibilityAnnouncement` carries a stable `id`, human-readable `message`, and `priority`.
- `PenggieSessionModel.accessibilityAnnouncement` maps app lifecycle, live Reading projection, and active terminal-owned surface state into announcement events.
- `PenggieRootView` observes `session.accessibilityAnnouncement` and posts `NSAccessibility.Notification.announcementRequested` with a duplicate-id guard.

## Event Matrix

| Event | Source of truth | Priority | Notes |
| --- | --- | --- | --- |
| `checkingCodex` | `PenggieSessionModel.state == .checkingCodex` | Polite | Startup/setup state. |
| `launching` | `state == .launching` | Polite | Startup/setup state. |
| `ready` | Reading/Terminal state after stable Codex screen | Polite | Not emitted before terminal observation is stable. |
| `working` | Live Reading projection activity block | Polite | Does not rewrite sealed transcript content. |
| `toolRunning` | Live Reading projection tool-like block | Polite | Derived from live terminal projection only. |
| `approvalRequired` | Active terminal surface kind `.approvalPrompt` with fresh confirmable selection | Assertive | Terminal-owned safety decision. |
| `permissionRequired` | Active terminal surface kind `.permissionPrompt` with fresh confirmable selection | Assertive | Terminal-owned safety decision. |
| `projectionDegraded` | Live low-confidence Reading projection | Polite | Old sealed low-confidence blocks do not keep the app degraded forever. |
| `selectionSyncing` | Active terminal surface without fresh confirmable selection | Polite | Enter remains blocked by the same terminal evidence gate. |
| `processExited` | `state == .exited` | Assertive | Recovery state. |
| `missingCodex` | `state == .codexMissing` | Assertive | Recovery state. |
| `launchFailed` | `state == .launchFailed` | Assertive | Recovery state. |

## Terminal Truth Constraints

- No local selectedIndex is introduced for announcements.
- No local command/model/resume/approval/permission list is introduced for announcements.
- Terminal-owned approval and permission announcements come from `activeTerminalInteractionSurface`, not from SwiftUI row ownership.
- `selectionSyncing` uses the existing `hasFreshConfirmableSelection` gate, so accessibility activation cannot become more permissive than Enter.
- Dynamic announcements do not start a second Codex/Ghostty session and do not inspect a separate runtime.

## Verification

Run:

```bash
swift test --filter PenggieAccessibilityAnnouncementTests
scripts/qa/check-accessibility-smoke-source.sh
openspec validate productize-ui-ux-contract --strict
openspec validate --all --strict
```

Manual VoiceOver QA remains required for:

- Announcement timing during real Codex launch.
- Announcement usefulness during working/tool-running transitions.
- Approval and permission prompt announcements in a live terminal-owned surface.
- Selection syncing verbosity during rapid arrow navigation.
