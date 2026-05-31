# App Shell Confirmation QA

Scope: task 2.6 in `productize-ui-ux-contract`.

This note records the confirmation behavior for destructive session actions:
New Chat and Close Session. The implementation uses the system SwiftUI alert
as the focus-trapping modal surface and keeps the existing Codex/Ghostty
session alive until the destructive confirmation button is activated.

## Acceptance Evidence

- `requestNewChat()` only sets `.newChat` confirmation after an inspectable
  session exists.
- `requestCloseSession()` only sets `.closeSession` confirmation after an
  inspectable session exists.
- Neither request path calls `closeCurrentSession()`, starts a new Codex
  process, or changes state to `.closed`.
- `cancelConfirmation()` only clears the pending confirmation and preserves the
  active session.
- `confirm(_:)` is the lifecycle boundary that closes the session:
  - New Chat closes the current session, returns to `.closed`, then starts a
    fresh Codex session through the normal start path.
  - Close Session closes the current session and returns to setup.
- The root view presents confirmations with `.alert(item:)`, a destructive
  primary button, and a cancel button. The system alert provides the modal
  focus trap while it is visible.
- Confirmation copy names the destructive outcome and distinguishes New Chat
  from Close Session.

## Manual QA

Run these on a Debug build with an inspectable session:

1. New Chat cancel:
   - Start a session and wait until Reading or Raw Terminal is inspectable.
   - Press Command-N or choose New Chat from the app menu.
   - Verify the alert title is `Start a new chat?`.
   - Verify the destructive action says `Start New Chat`.
   - Verify Tab/Shift-Tab remains inside the system alert controls.
   - Press Esc or activate Cancel.
   - Verify the same session remains visible, process/cwd are unchanged, and
     focus returns to the previous owner when macOS dismisses the alert.
2. New Chat confirm:
   - Trigger New Chat again.
   - Activate `Start New Chat`.
   - Verify the old session is closed only after confirmation.
   - Verify Penggie starts a fresh Codex session through the normal create path
     and does not enter resume unless Codex itself does.
3. Close Session cancel:
   - Start an inspectable session.
   - Press Command-W or choose Session > Close Session.
   - Verify the alert title is `End this Codex session?`.
   - Verify the destructive action says `End Session`.
   - Cancel the alert.
   - Verify the same session remains visible and Raw Terminal/Reading state is
     preserved.
4. Close Session confirm:
   - Trigger Close Session again.
   - Activate `End Session`.
   - Verify the session closes only after confirmation and Penggie returns to
     the setup surface.
5. Blocked states:
   - During checking/launching/initial hold, verify menu commands are disabled
     and no confirmation alert appears.

## Automated Coverage

- `PenggieSessionLifecyclePolicyTests` verifies the public lifecycle policy
  surface for blocked actions and recovery states.
- `scripts/qa/check-p0-session-lifecycle-source.sh` verifies destructive
  confirmation copy, request/cancel paths, and that the root view uses system
  destructive/cancel alert buttons without closing or replacing the session
  before confirmation.

## Non-Goals

- Do not replace the system alert with a custom SwiftUI sheet unless a future
  accessibility review proves the system modal cannot satisfy the focus trap.
- Do not close the Codex/Ghostty session before destructive confirmation.
- Do not add alternate session state or a second confirmation state machine.
