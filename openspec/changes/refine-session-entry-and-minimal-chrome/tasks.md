## 1. Session Folder Model

- [x] 1.1 Add pending and active session folder state to `PenggieSessionModel`.
- [x] 1.2 Add a folder picker that accepts only readable local directories.
- [x] 1.3 Persist and restore the last selected folder when it is still usable.
- [x] 1.4 Pass the selected folder into Codex/Ghostty launch as the process working directory.
- [x] 1.5 Keep the active folder read-only until the session is closed or restarted.

## 2. Start Screen

- [x] 2.1 Replace immediate Codex-row launch with a configure-then-start layout.
- [x] 2.2 Show Codex as the selected v0.1 agent CLI using the OpenAI icon without turning it into a premature launch control.
- [x] 2.3 Add a session folder row with clear selected-folder/path display and `Choose`/`Change` action.
- [x] 2.4 Add `Create with Penggie` as the only launch action and disable or block it when no folder is selected.
- [x] 2.5 Keep Codex missing, launch failed, and process exited states productized.

## 3. Active Chrome and Composer

- [x] 3.1 Remove redundant active-session Penggie icon/provider text from titlebar chrome.
- [x] 3.2 Keep one accessible destination mode icon aligned with the macOS traffic-light/titlebar region.
- [x] 3.3 Ensure Reading/Terminal switching remains a same-session view switch.
- [x] 3.4 Remove the composer `/ commands` affordance.
- [x] 3.5 Display active folder context as read-only in the titlebar, without duplicating it in the composer footer.
- [x] 3.6 Apply a Penggie light theme to the embedded Raw Terminal Ghostty session.

## 4. Guardrails and Verification

- [x] 4.1 Confirm no changes were made to Reading turn ownership, native slash row extraction/selection, Ghostty screen model parsing, or Raw Terminal data source.
- [x] 4.2 Run existing Swift tests covering transcript/store/slash behavior.
- [x] 4.3 Build the macOS app target.
- [x] 4.4 Manually verify start flow: choose folder, start Reading, send ordinary prompt, switch to Raw Terminal and back.
- [x] 4.5 Manually verify slash flow: `/`, `/m`, `/model`, arrows, Enter, Esc, and Backspace still use the real Codex PTY.
- [x] 4.6 Review the resulting UI against Impeccable, UI UX Pro Max, and Front End Design criteria before marking the change complete.
- [x] 4.7 Manually verify Raw Terminal light theme readability against Codex startup, prompt, assistant output, and slash/menu states.
