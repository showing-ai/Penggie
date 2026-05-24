## 1. Penggie App Shell

- [ ] 1.1 Create or configure the Penggie macOS app target with Penggie bundle name, display name, app icon, menu name, and window title.
- [ ] 1.2 Build the Penggie start/connect screen with a centered Penggie-branded layout and a single `Start with Codex` entry.
- [ ] 1.3 Add productized states for Codex missing, launch failed, process exited, and session closed.
- [ ] 1.4 Remove or hide user-visible ShowCLI and Ghostty shell copy from v0.1 surfaces.

## 2. Ghostty-backed Codex Single Session

- [ ] 2.1 Implement the v0.1 session state model for idle, checking Codex, launching, running, failed, exited, and closed.
- [ ] 2.2 Implement Codex availability checking through the user's login shell/PATH.
- [ ] 2.3 Integrate the real Ghostty substrate path required for PTY text/key send, screen text read, screen model JSON read, and raw surface hosting.
- [ ] 2.4 Launch a single real Codex CLI process in a Ghostty-backed PTY.
- [ ] 2.5 Implement `Close Session` to end the active session and return to the start screen.
- [ ] 2.6 Implement `New Chat` to restart a fresh Codex session in the same window.

## 3. Reading Chat UI

- [ ] 3.1 Migrate and rename the PoC Reading projection, transcript, and presentation models.
- [ ] 3.2 Build the Reading empty state with centered headline and composer.
- [ ] 3.3 Build the transcript state with Reading output projection and a bottom/sticky composer after conversation content exists.
- [ ] 3.4 Migrate the AppKit-backed composer with IME-safe placeholder behavior.
- [ ] 3.5 Implement ordinary prompt submission to the real Codex PTY and show submitted user input in Reading.

## 4. Native Slash Interaction

- [ ] 4.1 Migrate and rename first-character native trigger rules for `/` and Codex-allowed `$` behavior.
- [ ] 4.2 Migrate native interaction phase, timing, focus recovery, and key capture behavior.
- [ ] 4.3 Migrate Ghostty screen model JSON parsing and native overlay row extraction.
- [ ] 4.4 Render native slash suggestions as a GUI projection of the real Codex terminal screen model.
- [ ] 4.5 Ensure `/m`, `/model`, arrow keys, Enter, Esc, and Backspace route through the PTY and do not use local command/model state.

## 5. Raw Terminal Fallback

- [ ] 5.1 Add a top bar Reading/Terminal mode switch.
- [ ] 5.2 Host the same Ghostty surface as Raw Terminal fallback without Ghostty product chrome.
- [ ] 5.3 Preserve the same PTY/session state when switching between Reading and Terminal.
- [ ] 5.4 Ensure Terminal mode is unavailable when no Codex session exists.

## 6. Verification

- [ ] 6.1 Add or port regression tests for composer native trigger rules and IME placeholder visibility.
- [ ] 6.2 Add or port regression tests for screen model native overlay row extraction and continuation menus.
- [ ] 6.3 Verify Codex installed: start with Codex, enter Reading, send prompt, display Reading output.
- [ ] 6.4 Verify Codex missing, launch failed, and process exited product states.
- [ ] 6.5 Verify `/`, `/m`, `/model`, arrow/Enter, Esc, and Backspace behavior against real Codex CLI.
- [ ] 6.6 Verify Raw Terminal shows the same PTY state as Reading.
