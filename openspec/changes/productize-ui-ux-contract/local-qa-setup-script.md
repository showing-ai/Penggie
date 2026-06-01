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
scripts/qa/check-product-ui-ux-evidence-bundle.sh --allow-pending "$bundle"
```

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

Optional build verification:

```bash
scripts/qa/prepare-product-ui-ux-local-qa.sh --build --evidence-dir /tmp/penggie-ui-ux-qa
```

This runs the standard Debug macOS build before writing evidence notes.

Strict live/manual QA status verification:

```bash
scripts/qa/check-product-ui-ux-live-qa-status.sh --strict --evidence-dir "$bundle"
```

This wraps the strict evidence checker and should only pass when the bundle is
fully filled from a live app run.

## Non-Goals

- Do not automate pass/fail decisions from screenshots.
- Do not create a second Codex/Ghostty session.
- Do not replace manual VoiceOver, Dynamic Type, Raw Terminal, or visual QA.
- Do not encode project-specific session data in the script.
