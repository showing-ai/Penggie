## 1. Evidence and Fixtures

- [x] 1.1 Record the current resume picker 6.8 manual result as baseline evidence for this change.
- [x] 1.2 Capture Ghostty screen-model fixtures for resume picker selected, unselected, ambiguous, filter, sort, and pager states.
- [x] 1.3 Capture Ghostty screen-model fixtures for slash suggestions, slash continuation, `/model`, model picker, and effort picker states.
- [x] 1.4 Capture Ghostty screen-model fixtures for approval and permission prompt choice surfaces.
- [x] 1.5 Add negative fixtures where historical transcript text mentions slash/model/resume/approval text but no active terminal-owned surface exists.

## 2. Terminal Frame Pipeline

- [x] 2.1 Define an immutable `TerminalFrame` model with frame id, timestamp, visible text, screen text, screen model JSON, decoded snapshot, cursor/style facts, viewport facts, and process state.
- [x] 2.2 Construct one `TerminalFrame` per Ghostty polling tick in `PenggieSessionModel`.
- [x] 2.3 Pass `TerminalFrame` into Reading transcript, resume picker, native slash overlay, diagnostics, and display-readiness paths instead of passing independently read terminal facts.
- [x] 2.4 Add tests proving multiple projections consume the same frame identity for one poll.

## 3. Surface Classification

- [x] 3.1 Define terminal interaction surface kinds for transcript, startup, slash suggestions, slash continuation, resume picker, model picker, effort picker, modal choice, approval prompt, permission prompt, pager, and opaque terminal.
- [x] 3.2 Implement a behavior zoner that classifies active terminal-owned regions before feature-specific parsing.
- [x] 3.3 Ensure historical transcript content cannot be classified as an active terminal-owned surface.
- [x] 3.4 Add classification tests for each supported surface kind and negative fixture.

## 4. Candidate Parsing

- [x] 4.1 Keep resume-specific candidate parsing for session age, title, filter, sort, pager, and footer hints.
- [x] 4.2 Keep slash-specific candidate parsing for slash suggestions and slash continuation menus.
- [x] 4.3 Add candidate parsers for model picker, effort picker, approval prompt, and permission prompt rows.
- [x] 4.4 Emit stable row identity based on terminal region, viewport row, and normalized text fingerprint rather than local array index.
- [x] 4.5 Add parser fixture tests for resume, slash, model, effort, approval, and permission candidates.

## 5. Shared Selection Inference

- [x] 5.1 Define `TerminalOwnedSelectionState` with `none`, `ambiguous`, and `single(rowID, source, evidence)` states.
- [x] 5.2 Implement one centralized selection inference primitive using visible marker, screen-model marker, explicit selected cells, inverse/selected style, foreground/faint contrast, cursor row, and contiguous menu region evidence.
- [x] 5.3 Keep Ghostty mouse text selection separate from Codex TUI current-row selection in model names, tests, and projection code.
- [x] 5.4 Migrate resume picker selected-row inference to the centralized primitive.
- [x] 5.5 Migrate slash continuation/model/effort selected-row inference to the centralized primitive without introducing local selected indexes.
- [x] 5.6 Add tests for unique marker, style-only selection, cursor fallback, missing selection, conflicting selection, and text-selection separation.

## 6. Input Routing and Confirmation Gating

- [x] 6.1 Define tri-state terminal input decisions: handled, blocked, and unhandled.
- [x] 6.2 Update key capture so blocked terminal-owned input is consumed and cannot fall through to ordinary composer text handling.
- [x] 6.3 Gate Enter/confirm on fresh, reliable, exactly-one confirmable terminal-owned selected row.
- [x] 6.4 Route arrow keys, Tab, Esc, Backspace, filter text, and confirm through the active Ghostty/Codex PTY for terminal-owned surfaces.
- [x] 6.5 Add tests proving ambiguous resume Enter is blocked and does not send `"\r"` through text fallback.
- [x] 6.6 Add tests proving reliable resume/model/approval confirm is sent to the active PTY.

## 7. Reading Projection Integration

- [x] 7.1 Render resume picker from terminal interaction surface candidates, selection state, confidence, freshness, and confirmability.
- [x] 7.2 Render slash continuation, model picker, and effort picker from the same surface contract.
- [x] 7.3 Render approval and permission prompts as terminal-owned modal choice surfaces rather than transcript blocks.
- [x] 7.4 Keep visible candidates displayed when selection confidence is low, with a syncing or low-confidence indication.
- [x] 7.5 Ensure terminal-owned active surfaces are not added to permanent Reading transcript blocks.

## 8. Raw Terminal Parity

- [x] 8.1 Add tests or diagnostics proving Reading selected-row projection matches the Raw Terminal marker/style row for the same frame when evidence is reliable.
- [x] 8.2 Add low-confidence behavior when Raw Terminal selected-row parity cannot be proven.
- [x] 8.3 Manually verify Reading to Raw Terminal to Reading switching during resume, slash continuation, and approval surfaces without PTY restart or selection drift.

## 9. Verification

- [x] 9.1 Run focused terminal interaction surface projection tests.
- [x] 9.2 Run native interaction and resume picker tests.
- [x] 9.3 Run full `swift test`.
- [x] 9.4 Run `git diff --check`.
- [x] 9.5 Build the macOS app target with `xcodebuild`.
- [x] 9.6 Manually verify resume picker 6.8 behavior: exactly one highlighted row when Raw Terminal has one, and blocked confirm when ambiguous.
- [x] 9.7 Manually verify `/model`, model picker, effort picker, approval prompt, and permission prompt behavior.
- [x] 9.8 Manually verify no local Codex menu list, model list, session list, approval list, or selectedIndex state was introduced.
