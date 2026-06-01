## Context

Reading turns already have local metadata such as submitted time, latest observed time, status, and output blocks. The current waiting UI can still be dominated by terminal-projected Codex text such as `Working... 0s`, and that text does not reliably repaint every second. As a result, Penggie can appear stuck even while Codex is active.

The important boundary is that Codex/Ghostty remains the source of truth for PTY state, response content, tool/activity rows, Raw Terminal, and native slash overlay data. The timer is a Reading UX affordance, so Penggie should own it locally.

## Goals / Non-Goals

**Goals:**

- Show an active response indicator that visibly advances while Codex is running.
- Keep completed response duration stable after the turn finishes.
- Preserve terminal-derived response content and activity details.
- Avoid per-second full terminal projection or blockizer work.
- Keep multi-turn transcript ownership stable so later prompts cannot rewrite earlier turns.

**Non-Goals:**

- Do not change Ghostty PTY routing, Codex launch, Raw Terminal rendering, or native slash key handling.
- Do not parse semantic model/tool state beyond existing presentation classification.
- Do not maintain a second answer transcript that competes with the terminal-derived content store.
- Do not alter slash command suggestion data or selection behavior.

## Decisions

### Penggie owns the primary active-turn timer

The active Reading header will be generated from turn metadata (`submittedAt`, current UI time, and completion state), not from terminal-projected `Working...` rows. Codex-projected working/activity rows can remain available as disclosure details, but they must not suppress the primary `Working... Ns` indicator.

Alternative considered: keep relying on Codex `Working...` text and force more frequent screen reads. This was rejected because Codex TUI does not guarantee repaint cadence, and full projection on every tick risks performance regression.

### Timer refresh stays presentation-scoped

Use a lightweight UI timer for the active status header rather than re-blockizing terminal output every second. The transcript store should update when terminal projection changes or turn state changes, while the visible elapsed seconds can be computed during rendering for the active turn.

Alternative considered: mutate `latestObservedAt` every second and rebuild visible blocks. This is simpler but scales poorly with long conversations and can reintroduce the previous grouping bugs.

### Completion freezes duration

When a turn completes, display `Worked for Ns` using Codex-provided duration if present. If Codex does not provide one, compute a fallback from local submitted/completed metadata. Once frozen, later UI ticks must not change that duration.

### Details remain expandable and terminal-derived

Search/tool/activity rows should stay folded behind the `Working... Ns` or `Worked for Ns` disclosure affordance. Expanding shows the captured terminal-derived details. The main answer text remains readable and separate from transient details.

## Risks / Trade-offs

- Active timer duplicates terminal `Working...` detail if filtering is incomplete -> Keep projected working rows out of the primary flow and only expose them inside disclosure details.
- Timer updates could trigger expensive SwiftUI re-layout -> Scope the ticking view to the status row and avoid rebuilding the full transcript.
- Completion detection can lag terminal output -> Keep the active header until the existing session model marks the turn complete; do not infer completion from content alone.
- Multi-turn ordering bugs could return -> Add tests for consecutive prompts, long answers, and unchanged terminal projections after a new turn begins.
