# App Shell Lifecycle QA Matrix

Scope: task 2.7 in `productize-ui-ux-contract`.

This matrix consolidates unit and manual QA coverage for the P0 app shell,
setup, and session lifecycle milestone. It is intentionally scoped to lifecycle
state, recovery, destructive actions, and same-session availability; terminal
owned overlay behavior continues in task group 3.

## Automated Coverage

Run these commands for the P0 app-shell lifecycle milestone:

```bash
swift test --filter PenggieSessionLifecyclePolicyTests
scripts/qa/check-p0-session-lifecycle-source.sh
openspec validate productize-ui-ux-contract --strict
openspec validate --all --strict
git diff --check
xcodebuild -project Penggie/Penggie.xcodeproj -scheme Penggie -configuration Debug -destination 'platform=macOS' build
```

`PenggieSessionLifecyclePolicyTests` covers:

- setup/recovery phases are startable but not inspectable:
  `.idle`, `.closed`, `.codexMissing`, `.launchFailed`
- startup/initial hold phases block inspectable actions and prompt submission:
  `.checkingCodex`, `.launching`, `.reading(false)`, `.terminal(false)`
- stable Reading/Raw Terminal phases are inspectable
- exited sessions are inspectable, not running, startable, and not prompt
  submittable
- Reading/Raw Terminal transitions are mode-only after stable terminal evidence
- terminal-owned interactions block prompt submission even while the Codex
  process is running

`scripts/qa/check-p0-session-lifecycle-source.sh` covers source-level guards
that SwiftPM cannot instantiate directly:

- create/start path does not call resume or `--last`
- app-level `Create with Penggie` calls `session.startWithCodex()`
- app commands disable create, New Chat, and Close Session at lifecycle gates
- display mode switching delegates to `PenggieSessionLifecyclePolicy`
- folder changes are blocked outside startable states
- exited starts clean up stale terminal surface
- Ghostty exit callback ignores stale closed/replaced sessions
- New Chat and Close Session request confirmation without closing or replacing
  the active session
- confirmation and cancellation preserve destructive-action boundaries
- setup/start view, recovery views, confirmation alerts, and exited terminal
  inspection are wired in `PenggieRootView`

## Manual QA Matrix

| State / action | Expected visible state | Allowed actions | Blocked actions | Keyboard owner | Raw Terminal | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| Missing folder setup | Setup surface with missing-folder helper and disabled create | Choose folder | Create, prompt, Raw Terminal, New Chat, Close Session | SwiftUI setup controls | Not available | `app-shell-setup-start-qa.md` |
| Invalid folder setup | Setup surface with invalid-folder helper and disabled create | Choose folder | Create, prompt, Raw Terminal, New Chat, Close Session | SwiftUI setup controls | Not available | `app-shell-setup-start-qa.md` |
| Valid folder setup | Setup surface with enabled `Create with Penggie` | Choose folder, Create | Prompt, Raw Terminal, New Chat, Close Session | SwiftUI setup controls | Not available | `app-shell-setup-start-qa.md` |
| Create with Penggie | Checking/starting/preparing copy; no terminal noise | Wait for launch | Duplicate create, folder change, prompt, Raw Terminal, New Chat, Close Session | SwiftUI setup hold | Not available | `app-shell-create-path-verification.md`, `app-shell-launch-blocked-actions.md` |
| Checking Codex | Startup hold copy; no prompt/composer | Wait | Duplicate create, folder change, prompt, Raw Terminal, New Chat, Close Session | SwiftUI setup hold | Not available | `app-shell-launch-blocked-actions.md` |
| Launching Codex | Startup hold copy; no prompt/composer | Wait | Duplicate create, folder change, prompt, Raw Terminal, New Chat, Close Session | SwiftUI setup hold | Not available | `app-shell-launch-blocked-actions.md` |
| Initial Reading hold | Preparing Reading copy until stable terminal evidence | Wait | Prompt, Raw Terminal, New Chat, Close Session | SwiftUI setup hold | Not available | `app-shell-launch-blocked-actions.md` |
| Stable Reading | Reading transcript/composer or terminal-owned surface | Prompt when allowed, New Chat confirmation, Close Session confirmation, Raw Terminal switch | Prompt during terminal-owned interaction | Composer or terminal-owned key capture | Available | `app-shell-lifecycle-audit.md` |
| Stable Raw Terminal | Embedded Ghostty surface for same session | Terminal keyboard/mouse, return to Reading, New Chat confirmation, Close Session confirmation | Local Reading composer input | Ghostty host view | Authoritative view | `app-shell-lifecycle-audit.md` |
| Missing Codex | Recovery card with `Check Again` and `Choose Folder` | Retry, choose folder | Prompt, Raw Terminal, New Chat, Close Session | Recovery actions | Not available | `app-shell-recovery-qa.md` |
| Launch failed | Recovery card with `Try Again` and `Choose Folder` | Retry, choose folder | Prompt, Raw Terminal, New Chat, Close Session | Recovery actions | Not available | `app-shell-recovery-qa.md` |
| Exited with retained terminal surface | Recovery card with `Start Again`, `Inspect Raw Terminal`, `Close Session` | Start again, inspect terminal, close | Prompt submit | Recovery actions or retained Ghostty view | Available for inspection | `app-shell-recovery-qa.md` |
| Exited without retained terminal surface | Recovery card with `Start Again` and `Close Session` | Start again, close | Prompt submit, Raw Terminal inspection | Recovery actions | Not available | `app-shell-recovery-qa.md` |
| New Chat cancel | System destructive confirmation; active session retained | Cancel | Background session discard before confirm | System alert | Existing session retained | `app-shell-confirmation-qa.md` |
| New Chat confirm | System destructive confirmation; fresh session starts only after confirm | Start New Chat | Pre-confirm session discard | System alert | New session after confirm | `app-shell-confirmation-qa.md` |
| Close Session cancel | System destructive confirmation; active session retained | Cancel | Background session discard before confirm | System alert | Existing session retained | `app-shell-confirmation-qa.md` |
| Close Session confirm | System destructive confirmation; returns to setup only after confirm | End Session | Pre-confirm session discard | System alert | Closed after confirm | `app-shell-confirmation-qa.md` |

## Accessibility And Visual QA

- Keyboard-only setup: folder selection precedes create, and create is reachable
  only when enabled.
- Keyboard-only recovery: primary and secondary recovery actions are reachable
  without exposing prompt input to dead or unavailable processes.
- Confirmation focus: New Chat and Close Session use the system alert focus
  trap, destructive primary copy, and cancel restoration.
- VoiceOver setup: folder row exposes label, value, and state-specific hint;
  create explains unavailable states.
- VoiceOver recovery: missing Codex, launch failed, and exited recovery expose
  specific recovery copy and do not promise Raw Terminal when no inspectable
  surface exists.
- Visual review: setup, checking, launching, missing Codex, launch failed,
  exited recovery, New Chat confirmation, and Close Session confirmation use
  app-shell tokens and avoid showing terminal startup noise.

## Fixture Requirement

No terminal transcript fixture is required for task 2.7 because this milestone
does not change terminal projection, Display AST rendering, or terminal-owned
selection. Lifecycle behavior is covered by unit policy tests, source guards,
and manual app-shell QA scenarios. Terminal-owned fixture expansion begins in
task group 3.

## Non-Goals

- Do not add a local resume/session list to satisfy setup or New Chat behavior.
- Do not expose Raw Terminal before an inspectable `PenggieGhosttySession`
  exists.
- Do not close or replace the active Codex/Ghostty session before destructive
  confirmation.
- Do not route Create with Penggie into `codex resume`, `--last`, or any local
  saved-session selection path.
