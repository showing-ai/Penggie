# Penggie Reference Package

This folder contains the reference material to start the new Penggie product from the validated ShowCLI/Ghostty proof-of-concept.

Penggie should not inherit the old ShowCLI workspace structure. Treat this package as source reference and migration guidance, not as a drop-in app.

Core validated thesis:
- A real Agent CLI running inside a real PTY can power a GUI-like product experience.
- Reading can be the primary UI while Raw Terminal remains a fallback for the same PTY.
- Slash/native command interaction should use the real Agent CLI, not a local command list or semantic parser.
- Native overlays can be derived from terminal screen model styled rows/cells.

Recommended use:
1. Create a clean `Penggie` macOS project.
2. Copy `source/showcli-reading-native` into a new Penggie module and rename symbols deliberately.
3. Port only the minimal Ghostty integration hooks from `source/ghostty-integration-reference`.
4. Keep tests from `tests/` and add Penggie-specific regression coverage before redesigning UI.
