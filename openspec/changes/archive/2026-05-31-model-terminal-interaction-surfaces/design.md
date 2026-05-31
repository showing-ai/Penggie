## Context

Penggie embeds one Ghostty surface running the real Codex CLI. Raw Terminal renders that surface directly; Reading renders a native projection of selected terminal states. Today those projections are feature-specific:

- Reading transcript extraction reads terminal text and blockizes it.
- Native slash overlay reads terminal text/screen model and applies slash-specific selection logic.
- Resume picker reads terminal text/screen model and applies resume-specific selection logic.

The foundation work made Ghostty style facts available and introduced shared terminal-owned selection concepts, but the runtime still lacks a single behavior model for Codex TUI surfaces. This is why resume picker verification can fail independently of slash overlay, and why future approval/model/permission surfaces would likely repeat the same mistakes.

The key architectural rule is: Terminal is the only interaction state machine. Reading can render better native UI, but it must project from terminal facts and route input back to the terminal.

## Goals / Non-Goals

**Goals:**

- Establish a frame-bound terminal fact pipeline used by all terminal-owned projections.
- Classify active terminal-owned behavior surfaces before applying feature-specific parsing.
- Centralize selected-row inference, confidence, freshness, and confirmation eligibility.
- Make input routing explicit: handled, blocked, or unhandled, instead of Bool fallthrough.
- Use resume picker as the first migration target and generalize the pattern to slash continuation, model/effort pickers, approval prompts, and permission prompts.
- Preserve Raw Terminal as the same-PTY visual reference for every terminal-owned surface.

**Non-Goals:**

- No Ghostty theme, renderer, or window chrome redesign.
- No Reading Display AST or Markdown/table/CJK rendering rewrite.
- No local Codex business state: no session list, model list, command list, approval list, or selectedIndex.
- No split Raw Terminal session or separate PTY for Chat UI.
- No attempt to make every unknown alternate-screen terminal UI native in this change.

## Decisions

### Decision 1: Add `TerminalFrame` as the single per-poll fact object

Each poll of Ghostty SHALL produce one immutable frame with a frame id, timestamp, visible text, screen text, raw screen model JSON, decoded screen snapshot, cursor/style facts, viewport dimensions, and process state.

Current code reads these facts in one poll loop, but each downstream feature receives different subsets and sometimes re-decodes or reinterprets them. A frame object makes every projection traceable to the same terminal moment.

Alternatives considered:

- Keep per-feature reads: rejected because it lets resume, slash, Reading, and diagnostics disagree about which terminal state they saw.
- Make Raw Terminal the source by screenshot/pixels: rejected because pixels are not a stable semantic API. The source is the Ghostty screen model and PTY facts, not a screenshot.

### Decision 2: Classify behavior zones before feature parsing

Introduce a `TerminalBehaviorZoner` that identifies screen regions and active surface kinds:

- transcript display
- status activity
- active input composer
- keyboard selectable list
- modal choice
- pager viewport
- footer/help
- opaque terminal surface

Feature names such as resume picker or model picker are adapters over these zones. For example, resume is a keyboard selectable list plus filter/sort header and pager/footer zones; approval is a modal choice plus keyboard selectable choices.

Alternatives considered:

- Keep `PenggieCodexScreenKind` as the top-level model: rejected because it classifies by product page names and cannot express shared behavior across resume/model/approval.
- Convert everything to raw terminal fallback: rejected because Penggie's product goal requires native Reading projections where the terminal facts are reliable.

### Decision 3: Use `TerminalInteractionSurface` as the Chat UI contract

The zoner and parsers produce a surface contract:

- `id`
- `kind`
- `frameID`
- `zones`
- `candidates`
- `selection`
- `confidence`
- `freshness`
- `confirmability`
- `inputPolicy`
- `evidence`

Domain-specific parsers may parse row labels and metadata, but they only output candidates. They do not own selection. Selection is inferred centrally from terminal markers, style facts, cursor row, and contiguous menu regions.

Alternatives considered:

- Let each surface output `isSelected` directly: rejected because it preserves today’s fragmented logic.
- Use local array indices for identity: rejected because terminal rows repaint, filter, page, and wrap. Row identity should be based on terminal region plus normalized text fingerprint and frame id.

### Decision 4: Selection is confidence-aware, not Boolean

Selection inference returns one of:

- `none`
- `ambiguous(evidence)`
- `single(rowID, source, evidence)`

Sources include visible marker, screen-model marker, explicit selected cells, inverse/selected style, foreground/faint contrast, cursor row, and contiguous region inference. Ghostty mouse text selection remains a different concept and MUST NOT be used as Codex TUI current row.

Alternatives considered:

- Keep `hasExactlyOneSelectedRow`: rejected because it hides whether the issue is no evidence, multiple conflicting rows, stale frame, or parser mismatch.
- Preserve previous selected row after navigation: rejected as a general solution because it can fabricate selection. A previous row may only be shown as stale evidence when the surface explicitly reports `waitingForTerminalFrame`, and must not be confirmable.

### Decision 5: Input routing becomes tri-state and surface-owned

Input routing for terminal-owned surfaces returns:

- `handled(action)`: Penggie intentionally sent or processed the event.
- `blocked(reason)`: Penggie consumed the event because it would be unsafe or stale.
- `unhandled`: the event may continue to ordinary Reading composer behavior.

Arrow keys, Tab, Esc, Backspace, text filter input, and confirm all route through the same Ghostty/Codex PTY path when a terminal-owned surface is active. Enter is confirmable only when the surface has fresh, reliable, exactly one terminal-owned confirmable row. Ambiguous Enter must be blocked/consumed; it must not fall through as ordinary `"\r"` text.

Alternatives considered:

- Keep Bool callbacks and return false to block: rejected because the current key-capture path treats false as possible fallthrough.
- Move interaction to local SwiftUI state: rejected because Terminal remains the source of truth.

### Decision 6: Migrate incrementally, with resume first

The implementation should first define the shared models and migrate resume picker because it is the current manual failure. Then slash continuation and model/effort pickers can adopt the same contract. Approval/permission prompts should be added early as fixtures and parser tests because they are safety-sensitive.

Alternatives considered:

- Big-bang rewrite of all projections: rejected because the app currently has multiple active changes and a dirty worktree.
- Only fix resume 6.8: rejected because the same failure mode will recur in model/approval/permission surfaces.

## Risks / Trade-offs

- **Risk: Surface detection becomes over-broad and misclassifies historical transcript text.** → Mitigate with negative fixtures where old transcript lines mention slash/model/approval text but no active surface exists.
- **Risk: Central selection inference hides surface-specific evidence.** → Mitigate by keeping parser-specific candidate extraction separate and attaching evidence/source metadata to every selection result.
- **Risk: Low-confidence states feel less responsive.** → Mitigate by showing visible candidates and a syncing hint while blocking only unsafe confirmation.
- **Risk: Pager and scroll state are not fully modeled in the first implementation.** → Mitigate by representing pager evidence in the surface contract even if first implementation only covers visible rows.
- **Risk: Existing slash behavior regresses during migration.** → Mitigate with parity fixtures for current slash suggestions and continuation menus before refactoring.
- **Risk: Approval/permission prompts are hard to trigger manually.** → Mitigate with captured screen-model fixtures and projection unit tests before relying on manual QA.

## Migration Plan

1. Record current resume picker 6.8 evidence as the baseline failure or risk.
2. Introduce pure data models for `TerminalFrame`, zones, interaction surfaces, selection confidence, and input routing decisions.
3. Construct `TerminalFrame` once per Ghostty poll and pass it into existing projection paths.
4. Migrate resume picker to the unified surface contract and tri-state input router.
5. Add projection and routing tests proving ambiguous resume selection blocks Enter without fallthrough.
6. Migrate slash continuation/model/effort surfaces to use shared selection inference while preserving surface-specific parsers.
7. Add approval/permission modal fixtures and tests, with Raw Terminal fallback if confidence is unavailable.
8. Keep legacy code behind narrow adapters until each surface has fixture coverage, then remove duplicated selection paths.

Rollback is straightforward for each migration step: keep the old surface-specific parser as an adapter until the unified projection passes parity tests. Do not change the underlying PTY/session lifecycle, so rollback does not require session model restructuring.

## Open Questions

- Which approval/permission prompt variants should be included in first fixtures: command approval, file write approval, network permission, or all three?
- How much pager metadata can be reliably inferred from current Ghostty screen facts without adding more substrate data?
- Should stale previous selection be displayed visually as “waiting” in any surface, or should stale selection always be unhighlighted with a syncing hint?
