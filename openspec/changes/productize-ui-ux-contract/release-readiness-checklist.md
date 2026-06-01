# Release Readiness Checklist

Use this checklist before accepting each product-grade UI/UX milestone.

## Required Commands

- `openspec validate productize-ui-ux-contract --strict`
- `openspec show productize-ui-ux-contract --json`
- `openspec validate --all --strict`
- Relevant `swift test --filter ...` commands for changed logic.
- `scripts/qa/run-product-ui-ux-preflight.sh` before live QA starts, unless a reviewer explicitly documents why a narrower rerun is sufficient.
- Relevant QA/source guard scripts, including:
  - `scripts/qa/check-openspec-worktree-inventory.sh` before live QA starts, to prove the expected historical OpenSpec changes are archived, the current active change set is understood, and `Vendor/ghostty` has no unclassified dirty changes.
  - `scripts/qa/check-p0-session-lifecycle-source.sh` when lifecycle/session guards are touched.
  - `scripts/check-theme-token-usage.sh` when visual/theme tokens are touched.
  - `scripts/qa/check-product-ui-ux-task-evidence-map.sh` before live QA starts, to prove the only unchecked tasks are protected live/manual QA tasks with manifest, manual QA, and strict evidence coverage.
- Live/manual QA status guard:
  - `scripts/qa/check-product-ui-ux-live-qa-status.sh` before manual QA starts, to prove all remaining live tasks have manifest scenarios.
  - `scripts/qa/check-running-penggie-build-identity.sh <bundle>` after launching the recorded Debug app, to prove the running process loaded the same `Penggie.debug.dylib` recorded in the evidence bundle.
  - `scripts/qa/check-product-ui-ux-live-qa-status.sh --strict --evidence-dir <bundle>` before accepting live/manual QA completion; this strict guard also reruns the running app identity check.
- `git diff --check`
- `xcodebuild -project Penggie/Penggie.xcodeproj -scheme Penggie -configuration Debug -destination 'platform=macOS' build`

## Milestone Evidence Record

For each milestone, record:

- OpenSpec task IDs completed.
- Source files changed.
- Tests run and result.
- Evidence bundle path and `check-product-ui-ux-live-qa-status.sh` result.
- Evidence bundle `logs/build-identity.txt` result, including current commit,
  Debug app path, `Penggie.debug.dylib` hash, and GhosttyKit static library hash.
- Evidence bundle `logs/preflight.txt` result, including the
  `Product-grade UI/UX preflight passed` marker from the recorded commit.
- Running app build identity result from
  `scripts/qa/check-running-penggie-build-identity.sh <bundle>`.
- Fixtures added or updated, or reason not applicable.
- Manual QA scenario names and result.
- Existing screenshot or recording paths for scenarios that require visual
  evidence.
- Existing diagnostic log paths for every failed or blocked scenario.
- Accessibility QA result.
- Visual QA captures reviewed, or reason not applicable.
- Raw Terminal parity evidence when a live/inspectable terminal surface exists.
- Known limitations and deferred P1/P2 follow-ups.

## Release Review Evidence Template

Copy this template into the milestone review notes before accepting a product
UI/UX milestone.

```text
Milestone:
Reviewer:
Date:
Penggie commit:
Build configuration:
Build identity log:
OpenSpec change:
OpenSpec tasks completed:

Commands:
- openspec validate productize-ui-ux-contract --strict:
- openspec show productize-ui-ux-contract --json:
- openspec validate --all --strict:
- relevant swift test filters:
- relevant QA/source guard scripts:
- git diff --check:
- xcodebuild Debug macOS build:
- build identity commit/app/dylib/GhosttyKit hashes:
- preflight log:
- running app identity guard:

Manual QA Evidence:
- Scenarios run:
- Scenarios passed:
- Scenarios failed:
- Scenarios blocked or not applicable:
- Raw Terminal parity evidence:
- Same-session evidence:
- Terminal-owned selection evidence:
- Unsafe confirmation gate evidence:

Visual Captures:
- Light mode captures:
- Dark mode captures:
- Narrow window captures:
- Large-text captures:
- Known visual defects:

Accessibility Notes:
- Keyboard-only result:
- VoiceOver result:
- Dynamic announcement result:
- Dynamic Type or larger text result:
- Reduced motion result:
- Accessibility defects:

Fixture Coverage:
- Fixtures added:
- Fixtures updated:
- Fixtures reviewed:
- Missing fixtures and rationale:
- Low-confidence/fallback evidence:

Known Limitations:
- Accepted limitations:
- User-facing risk:
- Owner:
- Follow-up task/change:

Deferred P1/P2 Items:
- Item:
- Why deferred:
- Required evidence before acceptance:

Final Decision:
- Accept / Reject / Accept with follow-up:
- Reason:
```

## Release Review Acceptance Gates

The reviewer must reject the milestone when any of these evidence fields are
missing without an explicit not-applicable rationale:

- Manual QA scenarios relevant to the completed tasks.
- Visual captures for any changed visual surface.
- Accessibility notes for any changed keyboard, focus, control, overlay, or
  recovery behavior.
- Fixture coverage for any changed terminal projection, Display AST, lifecycle,
  focus routing, or terminal-owned selection behavior.
- Known limitations and deferred P1/P2 items.
- Raw Terminal parity evidence when an inspectable terminal surface exists.
- Build identity evidence proving QA ran against the intended Penggie build,
  not an older already-running app or stale embedded Ghostty substrate.
- Running process identity evidence proving the live Penggie process loaded the
  evidence bundle's `Penggie.debug.dylib` path and inode.

The reviewer must also reject the milestone if the evidence depends on a second
Codex CLI, SDK session, `codex exec --json` output, separate Raw Terminal
session, local command/model/resume/approval/permission list, or local selected
index as user-visible truth.

## P0 Manual QA Minimum

- Setup/start: valid folder, invalid folder, missing folder, `Create with Penggie`, disabled states, keyboard order.
- Lifecycle: checking, launching, active Reading, active Raw Terminal, missing Codex, launch failed, exited, New Chat, Close Session.
- Terminal-owned overlays: slash, model, effort, resume, approval, permission, low-confidence rows, stale selection, blocked Enter, Esc/cancel.
- Composer: IME marked text, committed text, Enter, Shift-Enter, paste, large paste, draft preservation, disabled send reason.
- Reading: long session, CJK, table, code, warning, tool-heavy output, fallback, process exit, Raw Terminal switch.
- Raw Terminal: view switching, same process/cwd/session, keyboard focus, text selection/copy, paste, active overlay parity.

## Accessibility QA Minimum

- Keyboard-only completion of setup, prompt submit, slash/model selection, resume, approval/permission, Raw Terminal switch, New Chat, Close Session.
- VoiceOver labels/hints/values for setup controls, composer, overlay rows, selected rows, disabled rows, syncing state, recovery actions, confirmations.
- Dynamic announcements for checking, launching, ready, working, approval required, permission required, projection degraded, selection syncing, process exited, missing Codex, launch failed.
- Dynamic Type or larger text review for setup, Reading, composer, overlays, recovery, Raw Terminal chrome, and narrow windows.
- Reduced motion review for disclosure, surface switching, focus affordances, and overlay transitions.

## Visual QA Minimum

- Light and dark mode:
  - setup
  - empty Reading
  - long transcript
  - composer focus
  - slash overlay
  - resume picker
  - approval/permission
  - Raw Terminal
  - recovery
  - narrow window
  - large text
- Review token usage for background, text, border, focus, disabled, warning, danger, selected, terminal renderer, and titlebar/canvas seams.

## Acceptance Rule

A milestone is not accepted when:

- Reading and Raw Terminal disagree about process, cwd, prompt readiness, terminal-owned rows, selected row, or process state without visible degraded fallback.
- Enter/click/accessibility activation can confirm a stale, ambiguous, missing, or non-confirmable terminal-owned selection.
- Visual polish hides low-confidence projection or terminal evidence.
- Debug-only diagnostics leak into release without an explicit product QA purpose.
