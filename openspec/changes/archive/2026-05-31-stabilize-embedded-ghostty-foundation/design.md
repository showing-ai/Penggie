## Context

Penggie embeds Ghostty and runs the real Codex CLI in one PTY. Reading, Raw Terminal, native slash overlay, and native resume picker are all projections of that same live terminal state. The archived startup/resume change showed that the product layer is now relying on terminal facts that are not stable enough: Raw Terminal colors do not clearly match Ghostty.app, and native picker selection sometimes depends on weak text/style heuristics.

The relevant substrate has four layers:

```
Codex CLI output
  └─ emits text + SGR based on env / TTY detection
       └─ Ghostty terminal model stores cells + styles
            └─ Ghostty renderer displays Raw Terminal
                 └─ Penggie screen model projects native UI
```

The foundation must be repaired from the bottom upward. If Codex does not emit SGR, theme work cannot restore semantic foreground colors. If Ghostty theme/config flattens colors, screen model work will inherit distorted style facts. If the screen model only exports line text plus coarse counters, Reading UI will continue inventing selection state.

Current observations:

- `PenggieGhosttySession.writePenggieLightTerminalConfig()` writes `window-theme = light`, explicit `background`, `foreground`, `selection-*`, a hand-written 16-color palette, and `minimum-contrast = 4.5`.
- Ghostty supports light/dark theme pairs and embedded color-scheme APIs, but Penggie does not currently bridge system appearance to `ghostty_app_set_color_scheme` / `ghostty_surface_set_color_scheme`.
- Ghostty embedded surface config supports per-surface `env_vars`, but Penggie currently mutates process environment briefly around app/surface creation.
- `ghostty_surface_read_screen_model` exports `"selected": false` and style counters, but does not expose style runs or background-only cells.
- Ghostty text selection is not the same semantic as Codex TUI current-row selection.

## Goals / Non-Goals

**Goals:**

- Establish an evidence-first terminal color diagnosis path before changing UI projection behavior.
- Ensure the Codex process launched by Penggie receives explicit, per-surface terminal/color environment intent.
- Make Raw Terminal use Ghostty's theme/color pipeline instead of a hand-written light palette and high contrast coercion.
- Synchronize embedded Ghostty app/surface color scheme with macOS appearance so light/dark theme pairs can work.
- Export screen model style facts rich enough for native UI projections to identify terminal-owned selected rows without local selected indexes.
- Share terminal-owned selected line/region projection primitives between resume picker and slash overlay while keeping their row parsers separate.

**Non-Goals:**

- Do not split Reading and Raw Terminal into separate Codex sessions or Ghostty surfaces.
- Do not replace Codex resume/session data with a local Penggie session list.
- Do not change Codex key routing unless probes show the key path is wrong.
- Do not redesign Reading transcript rendering, Markdown, tables, or blockization.
- Do not ask Ghostty to label Codex business concepts such as "resume selected row"; Ghostty should export terminal facts only.

## Decisions

### Decision 1: Add an evidence gate before foundation changes

Implementation should first add or document repeatable Raw Terminal probes for:

- effective environment: `TERM`, `COLORTERM`, `TERM_PROGRAM`, `NO_COLOR`, `CLICOLOR`, `CLICOLOR_FORCE`, `FORCE_COLOR`
- direct ANSI rendering: 16-color, truecolor, faint, bold, inverse
- Codex TUI capture where needed to determine whether SGR sequences exist in the PTY stream

Rationale: color loss can happen before Ghostty renders anything. A printf probe distinguishes "Ghostty cannot render SGR" from "Codex did not emit SGR".

Alternative considered: change Ghostty theme first. Rejected because it can make the visual output better while leaving the source-of-truth problem unresolved.

### Decision 2: Use per-surface environment overrides for color intent

Penggie should prefer `surfaceConfig.env_vars` / Ghostty `config.env` override for Codex color-related variables instead of temporarily mutating the Penggie process environment. The current process-level sanitation may work because Ghostty copies the environment synchronously, but it is fragile and global.

The override should make the intended terminal environment explicit:

- keep `TERM` and `COLORTERM` owned by Ghostty Exec
- ensure `NO_COLOR` is not inherited into Codex
- explicitly record or set `CLICOLOR`, `CLICOLOR_FORCE`, and `FORCE_COLOR` policy based on probe results

Alternative considered: keep temporary global env mutation. Rejected because it is hard to reason about and can affect concurrent app work.

### Decision 3: Raw Terminal should use Penggie-generated Ghostty themes, not hand-written main-config palette overrides

Penggie should stop writing top-level `background`, `foreground`, and `palette` values in the main embedded config. The main config should reference a light/dark theme pair generated from Penggie's `terminalScene` tokens and use a low `minimum-contrast`, such as `1` or `1.1`, unless probes prove a higher value is needed.

Rationale: Ghostty documents that explicit color settings override theme colors, and high `minimum-contrast` can coerce foreground colors toward black or white. That is incompatible with using Raw Terminal as visual truth. Built-in Ghostty theme names are useful references, but Penggie needs app-level scene tokens so chrome, Raw Terminal, and native terminal-owned overlays remain visually coherent.

Alternative considered: keep Penggie's custom light palette and tune individual colors. Rejected because it keeps Penggie responsible for matching Ghostty.app and can hide ANSI/style bugs.

### Decision 4: Bridge macOS appearance to embedded Ghostty app and surfaces

Penggie should mirror Ghostty.app's behavior by deriving light/dark from `NSApplication.shared.effectiveAppearance` and synchronizing it to embedded Ghostty. Initial scheme should be applied before or during surface creation, and appearance changes should update both app and existing surface state.

The implementation must verify whether Ghostty's soft reload action path needs host handling through `action_cb` for config changes to apply to active surfaces.

Alternative considered: rely on initial `window-theme = system` only. Rejected because embedded hosts do not automatically inherit Ghostty.app's macOS controller behavior.

### Decision 5: Export terminal style facts, not business selection

The screen model should be generated directly from viewport rows and cell styles instead of pairing dumped text lines with separate row iteration. It should export enough structured data to identify style differences:

- line index, text, first/last nonblank columns, wrap metadata where available
- style runs or an equivalent compact fingerprint
- raw foreground/background kind and value, including palette and RGB
- bold, faint, inverse, underline, italic, invisible where available
- counts for text cells and background-only cells
- terminal text selection ranges only under explicit naming, not as `selected`

Rationale: Codex TUI selected rows are encoded as terminal cell styles and markers. Ghostty cannot know the Codex business semantic; Penggie can only infer it by comparing terminal facts among candidate rows.

Alternative considered: keep line-level counters and improve thresholds. Rejected because multiple rows may share background/foreground counters, and background-only highlight cells are currently invisible to the model.

### Decision 6: Share selection projection primitives, not picker parsers

Resume picker and slash overlay should share a common primitive for terminal-owned selected line/region inference. They should not share row parsers or local state because their surfaces have different structures: resume rows parse age/title, while slash overlay parses command suggestions, continuation menus, and current input anchors.

The resume picker fallback order should become:

1. unique visible marker from the current viewport
2. snapshot style/cursor facts
3. backing text marker
4. unselected rows

Rationale: backing text can be stale or less viewport-specific than the current screen model. Snapshot style facts should not be overridden by an old backing marker.

Alternative considered: keep visible/backing marker precedence over snapshot. Rejected because it can preserve stale marker state when screen model facts are stronger.

### Decision 7: Normalize known embedded TUI control RGBs at the renderer adapter

Runtime diagnostics on 2026-05-30 proved the Codex composer active input row is stored in the Ghostty terminal model as an explicit RGB background:

```text
bg=rgb=240,240,240 inverse=false terminalTextSelected=false
```

This is not Ghostty text selection, not an ANSI palette entry, and not inverse video. Therefore `selection-background`, `activeInputBackground` SwiftUI tokens, and ANSI palette changes cannot make this row adapt to light/dark mode. The embedded renderer must provide a narrow Penggie-owned normalization path for known terminal-control RGB backgrounds that are part of Codex TUI chrome.

The normalization is an embedded adapter rule:

- enabled only by Penggie's generated embedded Ghostty theme/config;
- maps known TUI control explicit RGB backgrounds to the current `terminalScene.activeInputBackground`;
- keeps PTY text, terminal cell state, screen model raw style facts, and Codex output unchanged;
- does not maintain local TUI state, selected indexes, or session lists;
- does not globally remap arbitrary truecolor output.

Alternative considered: continue tuning Ghostty `selection-background` or app semantic tokens. Rejected because diagnostics show the affected row does not use terminal text selection or palette semantics.

## Risks / Trade-offs

- **Risk:** Codex uses color behavior that changes across CLI versions.  
  **Mitigation:** Keep probes as explicit verification steps and avoid hard-coding assumptions not observed in the active CLI.

- **Risk:** Lower `minimum-contrast` may reduce readability for some themes.  
  **Mitigation:** start with Ghostty theme defaults, verify real UI surfaces, and raise only with evidence.

- **Risk:** Screen model JSON grows larger with style runs.  
  **Mitigation:** compress contiguous identical styles and keep expensive resolved colors optional unless needed.

- **Risk:** Reproducing renderer final color composition in the API could drift from Ghostty.  
  **Mitigation:** prefer raw style facts plus optional resolved color helpers instead of copying full shader/render logic into Swift.

- **Risk:** Theme changes alter existing native selection heuristics.  
  **Mitigation:** implement style export before relying on color-specific heuristics and preserve slash overlay regression tests.

## Migration Plan

1. Add manual/debug probe tasks and confirm current Raw Terminal behavior.
2. Harden the Codex launch environment through per-surface overrides.
3. Replace the embedded light palette config with theme-based configuration and low contrast coercion.
4. Add embedded app/surface color-scheme synchronization.
5. Upgrade Ghostty screen model export and Swift decoding for style facts.
6. Refactor selection projection to consume terminal facts and share the primitive between resume and slash surfaces.
7. Verify with Swift tests, Ghostty substrate rebuild, macOS app build, and manual Raw Terminal/resume/slash checks.

Rollback is straightforward at each step before screen model schema consumers are migrated: restore the previous generated config, disable color-scheme bridge, or keep old style summary fields during a compatibility window.

## Open Questions

- Should Penggie use built-in Ghostty themes by name or generate bundled Penggie light/dark theme files?
- Do probes show that `FORCE_COLOR` or `CLICOLOR_FORCE` is required for Codex, or is removing `NO_COLOR` sufficient?
- How much resolved color data should the screen model export versus raw palette/RGB style facts?
- Does Ghostty embedded soft reload need explicit `action_cb` handling in Penggie for live theme switching, or is surface conditional-state notification enough for the chosen approach?

## Evidence Notes

### Raw Terminal probe contract

Use the same active Penggie Raw Terminal surface as Reading. Do not run these probes in a separate shell and treat them as proof for Penggie.

Environment probe:

```sh
python3 - <<'PY'
import os
for key in ["TERM", "COLORTERM", "TERM_PROGRAM", "NO_COLOR", "CLICOLOR", "CLICOLOR_FORCE", "FORCE_COLOR"]:
    print(f"{key}={os.environ.get(key, '<unset>')!r}")
PY
```

ANSI probe:

```sh
python3 - <<'PY'
print("16-color foregrounds:")
for i in range(30, 38):
    print(f"\033[{i}mfg{i}\033[0m", end=" ")
print("\nbright foregrounds:")
for i in range(90, 98):
    print(f"\033[{i}mfg{i}\033[0m", end=" ")
print("\ntruecolor: \033[38;2;32;128;255mblue-truecolor\033[0m")
print("bold: \033[1mbold text\033[0m")
print("faint: \033[2mfaint text\033[0m")
print("inverse: \033[7minverse text\033[0m")
PY
```

### Current implementation findings before behavior changes

- `PenggieGhosttySession` currently mutates the Penggie process environment around embedded app/surface creation by clearing `NO_COLOR` and setting `CLICOLOR=1`. This is a global workaround, not the per-surface contract required by this change.
- Ghostty embedded surface options already expose `env_vars`, but the current Ghostty execution path applies overrides by `put` only. It cannot remove inherited variables such as `NO_COLOR` unless Penggie keeps using global `unsetenv`.
- `PenggieGhosttySession.writePenggieLightTerminalConfig()` currently writes top-level `background`, `foreground`, `selection-*`, a 16-color `palette`, and `minimum-contrast = 4.5`. Ghostty's own config docs state that explicit colors override theme colors, and high minimum contrast can coerce foreground colors toward black or white.
- The embedded screen-model patch currently builds JSON by splitting dumped viewport text and separately asking for a style summary by viewport row index. It writes `"selected": false` for every row and only counts styled text cells; background-only highlighted cells are not exported.
- Therefore, before the foundation fixes, a mismatch between Raw Terminal `›`/highlight and native resume/slash selection is most likely in the Ghostty rendering/screen-model/projection layers after Codex TUI output, not in a Penggie local key-event selected-index path. The current evidence does not justify adding a local resume session list or selected index.

### Post-change runtime environment observation

On 2026-05-30, a Debug Penggie build was launched from:

```sh
.build/XcodeDerivedData/Build/Products/Debug/Penggie.app
```

The active Codex child processes under Penggie exposed these relevant environment variables through `ps eww`:

```text
TERM_PROGRAM=ghostty
TERM=xterm-ghostty
COLORTERM=truecolor
```

No `NO_COLOR`, `CLICOLOR_FORCE`, or `FORCE_COLOR` entry was present in the observed Codex child environment. This supports the required color-capable terminal contract and confirms that known color-disabling variables were not inherited into the running Codex child. `CLICOLOR=1` was not visible in the observed Codex child process, so it should not be treated as manually verified behavior; the current verified policy is Ghostty-owned `TERM`/`COLORTERM`/`TERM_PROGRAM` plus removal of color-disabling overrides.

### Manual dark-theme and selection bridge finding

On 2026-05-30, manual comparison showed Penggie's embedded Raw Terminal in dark mode used a near-black background while Ghostty.app used the slate default dark background. The configured `Apple System Colors` dark theme defines `background = #1e1e1e`. The bundled `Ghostty Default Style Dark` theme matches the slate `background = #282c34` but defines `selection-background = #ffffff`, which makes Codex's highlighted composer row render as a light block in dark mode. The bundled `One Half Dark` theme keeps `background = #282c34` while using `selection-background = #474e5d`, matching the observed Ghostty.app behavior more closely.

Penggie no longer uses built-in Ghostty theme names as the final visual source of truth. It generates light and dark Ghostty theme files from app-level `terminalScene` tokens, then points the embedded main config at those absolute theme files through Ghostty's light/dark theme pair syntax. This preserves Ghostty's theme semantics and macOS color-scheme synchronization while keeping Penggie's chrome, host fallback, Raw Terminal renderer, slash overlay, and resume picker on the same token system.

The same manual pass also showed embedded Raw Terminal text could not be selected for copy/paste. Code review confirmed `PenggieGhosttyHostView` forwarded scroll and key events but did not forward mouse position/button events to `ghostty_surface_mouse_pos` / `ghostty_surface_mouse_button`, so Ghostty could not establish terminal text selection. The fix is to bridge AppKit mouse movement, drag, button, and standard copy/paste actions to the same embedded Ghostty surface, preserving the single-PTY constraint.

### Theme ownership refinement

Manual visual comparison also exposed a broader architecture issue: Penggie's window chrome, SwiftUI root surfaces, Raw Terminal fallback, Ghostty host view, and Ghostty renderer config were not owned by a single theme source. A Raw Terminal-only background patch would make the immediate screenshot closer, but would preserve the underlying split-brain theme model.

Penggie's theme owner is now the app-level theme system:

- `PenggieThemeController` observes macOS effective appearance and publishes the active immutable `PenggieTheme`.
- SwiftUI views consume `Environment(\.penggieTheme)` semantic tokens rather than scattered system colors or hard-coded terminal colors.
- `PenggieTheme` is structured into primitives, semantic tokens, scenes, and components.
- `terminalScene` owns Raw Terminal canvas/chrome, terminal foregrounds, active input, TUI selected rows, terminal text selection, and ANSI palette tokens.
- `TerminalThemeConfiguration` owns generated Ghostty light/dark renderer theme contents, not built-in theme names.
- `PenggieSessionModel` stores the current `TerminalThemeConfiguration` and supplies it when launching the single embedded Codex/Ghostty session.
- `PenggieGhosttySession` remains the Ghostty adapter: it writes the config, applies the color scheme, and forwards host fallback background to `PenggieGhosttyHostView`. It no longer decides theme names itself.

This keeps Ghostty as a renderer consumer of Penggie's theme, not the source of the whole app theme. Titlebar, Reading, Raw Terminal fallback, native resume picker, and slash overlay should all derive their colors from the same `PenggieTheme` token set. The token guard script prevents new feature code from reintroducing scattered raw/system colors outside `PenggieTheme.swift`.

### Active input explicit RGB diagnostic

On 2026-05-30, `PenggieActiveInputStyleDiagnostic` captured the active Codex composer row in the live embedded Raw Terminal:

```text
text="› Use /skills to list available skills"
backgroundCellCount=... bg=rgb=240,240,240 inverse=false terminalTextSelected=false
```

The same raw RGB was present after dark appearance synchronization and Ghostty config reload. This closes the diagnostic loop: the remaining non-adaptive active input row is caused by explicit RGB terminal cells being faithfully rendered, not by missing theme reload, `selection-background`, ANSI palette, SwiftUI chrome, or Codex business state.
