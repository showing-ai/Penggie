# Migration Guide for Penggie

Do not copy the old repository wholesale. Start clean and port the proven kernel.

## Modules to create

- `PenggieApp`: macOS app entry, window, launch UI.
- `PenggieTerminalEngine`: PTY/session/screen model wrapper around Ghostty or chosen terminal engine.
- `PenggieReading`: Reading projection, blocks, presentation.
- `PenggieComposer`: AppKit-backed composer, IME handling, placeholder visibility.
- `PenggieNativeInteraction`: slash/dollar lifecycle, key capture, screen-model overlay extraction.
- `PenggieAgents`: Codex/Claude/Aider/shell launch presets and availability checks.

## First port

Copy and rename from `source/showcli-reading-native`:

- `ShowCLIReadingMode.swift`
- `ShowCLICurrentSessionController.swift`
- `ShowCLIComposerNativeTrigger.swift`
- `ShowCLITerminalScreenSnapshot.swift`
- `ShowCLIReadingPresentation.swift`
- `ShowCLIItemTranscript.swift`

Keep behavior intact before visual redesign.

## Integration hooks to port

Use `source/ghostty-integration-reference` to locate the required Ghostty hooks:

- screen plain text read
- screen VT text read
- screen model JSON read
- PTY text send
- PTY key event send
- Raw Terminal surface reuse

## Do not port

- Old Tauri/Rust ShowCLI implementation.
- Old Warp extraction code.
- Full experimental corpus into product repo.
- Local slash command list.
- Semantic command parser.
- Ad hoc output filters for fixed strings.

## Rename strategy

Rename `ShowCLI` symbols to `Penggie` only after tests pass in the clean project. First get behavior compiling and tested, then rename in a focused pass.
