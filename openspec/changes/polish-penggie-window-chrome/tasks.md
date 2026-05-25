## 1. Chrome Structure

- [x] 1.1 Replace the active-session in-content `PenggieTopBar` row with a window chrome strip aligned to the hidden-titlebar traffic-light area.
- [x] 1.2 Keep Penggie identity on the left: app icon, `Penggie`, and quiet `Codex` session label without a capsule/pill treatment.
- [x] 1.3 Ensure Reading and Raw Terminal content start below one chrome strip and do not render a duplicate full-width top bar row.

## 2. Session Controls

- [x] 2.1 Replace the Reading/Terminal segmented picker with one destination icon mode switch.
- [x] 2.2 Show a Terminal destination icon while Reading is active and switch to Raw Terminal on activation.
- [x] 2.3 Show a Reading/chat destination icon while Terminal is active and switch to Reading on activation.
- [x] 2.4 Keep New Chat and Close Session actions in the chrome and preserve their existing confirmation/session behavior.

## 3. Accessibility and Interaction Polish

- [x] 3.1 Give every icon-only chrome control a clear tooltip and accessibility label.
- [x] 3.2 Provide reliable desktop hit targets and visible hover, focus, pressed, and disabled states for the mode switch, New Chat, and Close Session.
- [x] 3.3 Verify the chrome layout does not collide with macOS traffic lights at the current minimum window size.

## 4. Guardrails and Verification

- [x] 4.1 Do not modify Reading transcript store, transcript blockization, Ghostty PTY routing, Raw Terminal data source, composer IME behavior, or native slash overlay selection logic.
- [x] 4.2 Run the existing core test suite and confirm native slash/Reading transcript tests still pass.
- [x] 4.3 Manually verify Reading to Terminal to Reading switching uses the same active session and does not restart Codex.
- [x] 4.4 Manually verify `/`, `/m`, `/model`, arrow keys, Enter, Esc, and Backspace still behave through the real Codex PTY.
- [x] 4.5 Run a UI review pass using Impeccable, UI UX Pro Max, and Front End Design criteria before calling the change complete.
