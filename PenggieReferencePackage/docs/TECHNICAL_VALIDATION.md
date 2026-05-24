# Technical Validation Summary

The PoC validated that Penggie can deliver a Codex-App-like GUI experience by driving a real Agent CLI through a terminal PTY.

Validated capabilities:
- Launch Codex CLI in a Ghostty-backed PTY.
- Show a Reading UI as the main interface.
- Keep Raw Terminal as a fallback view over the same PTY.
- Detect untrimmed first character `/` in an empty composer and enter native slash interaction.
- Detect untrimmed first character `$` for Codex sessions and enter native dollar interaction.
- Keep `/`, `/m`, `/mo`, `/model`, and continuation menus in one native interaction state.
- Route native interaction text and control keys through the real PTY / Agent CLI path.
- Read native overlay rows from Ghostty screen model / styled rows/cells.
- Avoid local slash command lists and semantic command parsers.
- Preserve Reading output blockization and transcript logic while native interaction occurs.

Resolved PoC blockers:
- `/` in empty Reading composer did not trigger native interaction.
- Composer placeholder overlapped user/IME marked text.
- Native slash overlay lost keyboard focus after entering command mode.
- `/m` and `/mo` exited Reading native state instead of continuing the same Codex CLI slash state.

Known productization risks:
- The overlay parser depends on Agent CLI terminal screen shape.
- Focus handoff between SwiftUI/AppKit/native capture needs regression tests.
- IME behavior needs complete product QA beyond the placeholder fix.
- Packaging, signing, updater, permissions, and product onboarding are not solved by the PoC.
