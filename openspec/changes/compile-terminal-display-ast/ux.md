# Reading Chat UI UX Principles

## Experience Goal

Penggie's best chat UI should feel like a calm Reading workspace powered by a real terminal session.

```text
Primary experience: readable work surface
Underlying truth: real Codex CLI in Ghostty PTY
Fallback: Raw Terminal over the same session
```

The target is not Slack, iMessage, or a decorative web chat. It is a native macOS work surface for long-running agent sessions where trust, readability, and continuity matter more than visual novelty.

## Priority Order

1. Trust
2. Readability
3. Continuity
4. Low chrome
5. Native feel
6. Brand polish

Brand and visual polish matter, but they must not outrank truthful state, stable input, or readable output.

## What the UI Should Have

| Area | UX Requirement |
| --- | --- |
| Reading flow | Clear turn-by-turn structure with user prompts, assistant answers, and tool/activity detail separated. |
| Composer | Stable, always available after session start, IME-safe, and free of placeholder overlap. |
| Status feedback | Clear `Working`, tool-running, approval, error, completion, and session-exit states. |
| Tool details | Collapsed by default, expandable on demand, and never allowed to bury the final answer. |
| Markdown-ish display | Lists, code, tables, paths, and CJK content should be readable and stable. |
| Raw Terminal | Same-session fallback that can be opened anytime without restarting or forking Codex. |
| Native overlay | macOS-feeling slash/model overlay whose state comes from the real terminal screen model. |
| Keyboard flow | Enter, Shift+Enter, Esc, arrows, Tab, and command shortcuts must feel consistent and predictable. |
| Empty state | Directly helps the user start work; it should not become a marketing hero. |
| Recovery states | Missing CLI, launch failure, process exit, permission issues, and PTY errors need concrete next actions. |
| Explainability | The user can tell whether Penggie is waiting for the model, a tool, approval, terminal output, or recovery. |
| Low chrome | Project, model/status, mode switch, and session controls exist but do not compete with the transcript. |

## What the UI Should Avoid

| Anti-pattern | Reason |
| --- | --- |
| Beautified terminal screenshot | It does not solve Reading; it only reskins terminal projection. |
| Heavy cards around every message | Long agent sessions need density and scanning, not decorative framing. |
| Local slash/model command copies | They can diverge from the real CLI state. |
| Hidden real errors | Users need to distinguish Codex, permission, network, PTY, and Penggie failures. |
| Fully expanded tool logs | Tool output overwhelms answer reading when it is always inline. |
| Terminal chrome inside answers | Footers, working rows, menus, and status lines must not pollute final answer content. |
| Decorative animation | Agent workflows already have waiting; motion must communicate state, not add noise. |
| Color-only meaning | Theme and palette changes should not change semantic interpretation. |
| Nested card stacks | They make the app feel like a dashboard rather than a work surface. |
| Pretending all output is Markdown | Tables, box drawing, CJK, and TUI state require display-aware rendering. |
| Raw Terminal as a second session | This breaks trust immediately. |
| Unstable composer behavior | IME, focus, placeholder, slash lifecycle, and key routing must be boringly reliable. |

## Codex-App-Inspired Qualities

The useful reference from Codex app is not a specific visual skin. It is the product behavior:

- Low chrome and high content density.
- Tool work is visible but hierarchically below the answer.
- Running, approval, completed, and error states are explicit.
- Command entry stays close to the composer context.
- Completed history is stable and not rewritten by terminal repaint or resize.
- The user can keep working without managing terminal mechanics.

## Ideal Active Session Layout

```text
┌────────────────────────────────────────────┐
│ traffic lights   Project   model/status    │
├────────────────────────────────────────────┤
│                                            │
│  User prompt                               │
│  Agent answer                              │
│    - readable markdown-ish content         │
│    - code/table/path handled well          │
│                                            │
│  Tool activity disclosure                  │
│  Worked for 2m 13s                         │
│                                            │
├────────────────────────────────────────────┤
│ composer                                   │
│ native slash/model overlay when active     │
└────────────────────────────────────────────┘
```

Raw Terminal is a mode switch inside the same window, not a separate product surface:

```text
Reading | Raw Terminal
```

## Trust Tests

The chat UI should be judged by these user-facing trust questions:

- Did my input go to the real Codex CLI?
- Can I tell what the agent is doing right now?
- Can I read the answer without terminal noise?
- Can I inspect the same session in Raw Terminal?
- Are slash/model/approval states real, not Penggie guesses?
- Does long history remain stable after resize, repaint, or later turns?

If any answer is no, visual polish is secondary.

## Relationship to Display AST

The Display AST work exists to support this UX:

- It keeps Reading from becoming a plain terminal projection.
- It preserves terminal-sensitive content such as tables, box drawing, and CJK.
- It lets tool/status/chrome rows be classified and presented at the right hierarchy.
- It keeps native overlay and command state tied to the real terminal screen model.
- It provides confidence and fallback metadata so uncertain output stays readable instead of wrong.
