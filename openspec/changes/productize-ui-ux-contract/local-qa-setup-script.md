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
- `manifest.tsv` with required scenario IDs, owning task IDs, and review scope
- `README.md` with required validation commands and manual QA references
- `notes/scenario-template.md` for per-scenario evidence
- one `notes/<scenario-id>.md` file for every required manual QA scenario

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

Final manual QA evidence verification:

```bash
scripts/qa/check-product-ui-ux-evidence-bundle.sh "$bundle"
```

The final checker is expected to fail on a freshly generated bundle. It should
only pass after every scenario note records a final result, observed result,
Raw Terminal parity note, and follow-up.

Optional build verification:

```bash
scripts/qa/prepare-product-ui-ux-local-qa.sh --build --evidence-dir /tmp/penggie-ui-ux-qa
```

This runs the standard Debug macOS build before writing evidence notes.

## Non-Goals

- Do not automate pass/fail decisions from screenshots.
- Do not create a second Codex/Ghostty session.
- Do not replace manual VoiceOver, Dynamic Type, Raw Terminal, or visual QA.
- Do not encode project-specific session data in the script.
