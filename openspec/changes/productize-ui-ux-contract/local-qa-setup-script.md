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
- `README.md` with required validation commands and manual QA references
- `notes/scenario-template.md` for per-scenario evidence

## Verification

Run:

```bash
scripts/qa/prepare-product-ui-ux-local-qa.sh --evidence-dir /tmp/penggie-ui-ux-qa
```

The command must create a timestamped evidence directory and print its path.

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
