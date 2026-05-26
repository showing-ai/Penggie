<p align="center">
  <img src="Penggie/Resources/Assets.xcassets/AppIcon.appiconset/icon_256.png" width="96" alt="Penggie app icon">
</p>

<h1 align="center">Penggie</h1>

<p align="center">
  A native macOS Reading shell for local agent CLI sessions.
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-111111.svg"></a>
  <img alt="Platform: macOS" src="https://img.shields.io/badge/platform-macOS-111111.svg">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6-orange.svg">
</p>

## What is Penggie?

Penggie wraps a real agent CLI session in a calm macOS app surface. The first version focuses on Codex: you choose a project folder, create a Penggie session, and work in a Reading-first interface while Raw Terminal remains available as a faithful fallback.

Penggie does not replace the agent runtime. Codex remains the source of truth for model state, slash commands, command selection, and terminal behavior. Penggie reads the same PTY state and projects it into a native app experience.

## Why

Agent CLIs are powerful, but living inside a raw terminal is not always the best way to work. Penggie keeps the real CLI underneath while giving day-to-day work a quieter desktop interface:

- Reading-first conversation flow instead of a terminal viewport.
- Raw Terminal fallback over the same session when you need the underlying TUI.
- Native slash command overlay sourced from terminal screen state.
- Project folder selected before launch, so the session starts in the right workspace.
- Productized launch, missing CLI, failure, and process-exit states.

## Current Scope

Penggie v0.1 is intentionally narrow:

- Codex only.
- One local session.
- One selected project folder per session.
- Reading mode plus Raw Terminal fallback.
- Core composer, send flow, and native slash interaction.
- Real `/`, `/m`, and `/model` behavior from Codex, not local command copies.

## Architecture

Penggie is built around one invariant: Reading and Raw Terminal are two views of the same PTY-backed agent session.

```text
Penggie app shell
  -> Reading presentation
  -> Native slash overlay
  -> Raw Terminal fallback
  -> Ghostty PTY substrate
  -> Codex CLI
```

Key boundaries:

- The Ghostty substrate owns the terminal session and screen model.
- Reading owns presentation, transcript stability, and product states.
- Native slash rows are projected from styled terminal screen rows.
- Penggie does not maintain a local slash command table or selected index.
- Completed Reading turns are preserved by Penggie-owned session history.

## Getting Started

### Requirements

- macOS 15 or later.
- Xcode with a Swift 6 toolchain.
- Codex CLI installed and available from the user's login shell.

### Build

Open the Xcode project:

```sh
open Penggie/Penggie.xcodeproj
```

Or build from the command line:

```sh
xcodebuild -project Penggie/Penggie.xcodeproj -scheme Penggie -configuration Debug build
```

### Test

```sh
swift test
```

## Development Notes

- `PRODUCT.md` defines the product boundaries and v0.1 scope.
- `DESIGN.md` defines the UI baseline and interaction rules.
- `openspec/` contains product and implementation change specs.
- `PenggieReferencePackage/` contains the validated ShowCLI/Ghostty reference material used to preserve core behavior.
- `patches/ghostty/` contains Ghostty integration reference patches.

Before changing Reading, slash interaction, or Raw Terminal behavior, preserve these constraints:

- Agent CLI state is the source of truth.
- Reading must not display raw terminal slash/menu chrome.
- Raw Terminal must show the same PTY session, not a restarted session.
- Slash overlay selection must come from styled terminal rows, not local index state.
- Composer IME and marked text behavior must not regress.

## Status

Penggie is under active development toward a focused v0.1 macOS release. The repository currently prioritizes productizing the validated Codex + Ghostty PTY core into a stable Penggie-first app.

## License

MIT. See [LICENSE](LICENSE).
