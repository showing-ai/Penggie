# Penggie Product Boundaries from the PoC

Core product boundary:
- Reading is the primary interface.
- Raw Terminal is the fallback for the same PTY/session.
- Agent CLI remains the source of truth for slash/dollar commands.
- Native overlays reflect terminal screen model state.

Native command rules:
- Untrimmed first character `/` starts slash native interaction.
- Untrimmed first character `$` starts dollar native interaction only for Codex sessions.
- Leading-space slash, e.g. ` /model`, is ordinary chat text.
- Inline slash, e.g. `hello /model`, is ordinary chat text.
- Once native interaction starts, `/m`, `/mo`, `/model`, Backspace, Tab, arrows, Enter, and Esc stay on the native PTY path.

Composer rules:
- SwiftUI state and NSTextView state must not fight during IME marked text.
- Placeholder is hidden when NSTextView has visible text or marked text.
- Do not overwrite NSTextView string from SwiftUI while marked text is active.

Output rules:
- Do not couple native command interaction to answer extraction.
- Do not change blockizer/transcript behavior to fix native overlay issues.
- Reading output should remain terminal-derived unless explicitly app-owned, such as submitted composer input.
