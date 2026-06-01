# Local QA Setup Script Evidence

Task: 10.2

## Scope

`scripts/qa/prepare-product-ui-ux-local-qa.sh` creates a repeatable local
evidence bundle for product-grade UI/UX review. It is deliberately a QA setup
helper, not a visual oracle or alternate runtime.

## Source Of Truth

- The script does not launch Codex, Ghostty, `codex exec --json`, or any second
  user-visible session.
- The running Penggie app and its embedded Ghostty/Codex PTY remain the only
  pass/fail source for session and terminal-owned state.
- Screenshots, recordings, logs, and notes generated under the evidence bundle
  are review artifacts. They do not replace fixture tests, terminal frame
  evidence, or Raw Terminal parity checks.

## Output

The script creates:

- `screenshots/`
- `recordings/`
- `logs/`
- `notes/`
- `manifest.tsv` with required scenario IDs, owning task IDs, review scope, and
  machine-checkable coverage requirements
- `README.md` with required validation commands and manual QA references
- `logs/build-identity.txt` with the repository commit, dirty status, Debug app
  path, `Penggie.debug.dylib` hash, and GhosttyKit static library hash
- `notes/scenario-template.md` for per-scenario evidence
- one `notes/<scenario-id>.md` file for every required manual QA scenario

The scenario matrix is stored in
`scripts/qa/product-ui-ux-manifest.tsv` and copied into each bundle. The prepare
script and status guard use the same manifest so QA coverage cannot silently
drift between tools.

## Verification

Run:

```bash
scripts/qa/prepare-product-ui-ux-local-qa.sh --evidence-dir /tmp/penggie-ui-ux-qa
```

The command must create a timestamped evidence directory and print its path.

Structural bundle verification:

```bash
bundle="$(scripts/qa/prepare-product-ui-ux-local-qa.sh --evidence-dir /tmp/penggie-ui-ux-qa | tail -n 1)"
scripts/qa/run-product-ui-ux-preflight.sh 2>&1 | tee "$bundle/logs/preflight.txt"
scripts/qa/check-openspec-worktree-inventory.sh
scripts/qa/check-product-ui-ux-task-evidence-map.sh
scripts/qa/check-product-ui-ux-evidence-bundle.sh --allow-pending "$bundle"
```

The product UI/UX preflight script should pass before live QA starts. It
aggregates the OpenSpec validation, worktree inventory, source guards, fixture
guards, focused Swift tests, and Debug macOS Xcode build that protect the
terminal-owned surface and product-grade UI/UX contracts. For final strict
evidence, record its output at `logs/preflight.txt` inside the evidence bundle.

The OpenSpec/worktree inventory guard must pass before live QA starts. It proves
that previously completed foundational changes are archived, the expected
productization change remains the only active change, and `Vendor/ghostty` has
no unclassified dirty changes.

The task evidence map guard must pass before manual QA starts. It proves that
every unchecked task in `tasks.md` is one of the protected live/manual QA tasks
and that every protected task has manifest scenarios, manual QA steps, and
strict evidence fields. If a future implementation task remains unchecked, this
guard fails instead of silently treating it as manual QA.

Remaining live/manual QA status:

```bash
scripts/qa/check-product-ui-ux-live-qa-status.sh --evidence-dir "$bundle"
```

The status guard reports every open live/manual QA task and the manifest
scenarios that prove it. It must not be used to mark tasks complete; it only
proves that pending tasks still have explicit evidence slots.

Final manual QA evidence verification:

```bash
scripts/qa/check-product-ui-ux-evidence-bundle.sh "$bundle"
```

The final checker is expected to fail on a freshly generated bundle. It should
only pass after every scenario note records a final result, observed result,
Raw Terminal parity note, follow-up, and the coverage required by
`manifest.tsv`.

Coverage entries are semicolon-separated `key=value` clauses, for example:

```text
theme=light,dark;window=normal,narrow;voiceover=on;terminal=live;raw-terminal=required
```

The strict checker verifies the matching note fields contain those coverage
tokens. This prevents a scenario from passing with only generic prose when it
actually required light/dark, narrow-window, VoiceOver, Raw Terminal, pointer,
motion, contrast, or screenshot evidence.

When `manifest.tsv` marks `screenshot=required`, the scenario note must include
one or more existing relative paths under `screenshots/` or `recordings/` in
`Screenshot/recording path`. When a scenario result is `fail` or `blocked`, the
note must include at least one existing relative path under `logs/` in
`Diagnostic/log path`. Absolute paths and paths outside the evidence bundle are
rejected so evidence remains portable and reviewable.

Optional build verification:

```bash
scripts/qa/prepare-product-ui-ux-local-qa.sh --build --evidence-dir /tmp/penggie-ui-ux-qa
```

This runs the standard Debug macOS build before writing evidence notes and
records the build identity in `logs/build-identity.txt`. Reviewers should use
that file to confirm manual QA is running against the intended app binary and
embedded Ghostty substrate instead of an older already-running app.

Runtime build identity verification:

```bash
scripts/qa/check-running-penggie-build-identity.sh "$bundle"
```

Run this after launching the recorded Debug `Penggie.app` and before collecting
live QA evidence. The guard compares the current repository commit, recorded
Debug app, `Penggie.debug.dylib` hash/inode, GhosttyKit static library hash, and
the dylib loaded by the running Penggie process. It must fail if manual QA is
accidentally using an older already-running app or a stale embedded Ghostty
substrate. If more than one Penggie process is running, pass `--pid <pid>`.

Strict live/manual QA status verification:

```bash
scripts/qa/check-product-ui-ux-live-qa-status.sh --strict --evidence-dir "$bundle"
```

This wraps the running build identity guard and the strict evidence checker. It
should only pass when the recorded Debug `Penggie.app` is currently running, the
running process has loaded the same `Penggie.debug.dylib` recorded in the
bundle, and the bundle is fully filled from that live app run.

The strict checker also requires `logs/build-identity.txt` to resolve a Debug
`Penggie.app`, `Penggie.debug.dylib` SHA256, and GhosttyKit static library
SHA256. This prevents accepting live QA evidence without a traceable build.

## Non-Goals

- Do not automate pass/fail decisions from screenshots.
- Do not create a second Codex/Ghostty session.
- Do not replace manual VoiceOver, Dynamic Type, Raw Terminal, or visual QA.
- Do not encode project-specific session data in the script.
