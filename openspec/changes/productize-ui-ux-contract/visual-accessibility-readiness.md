# Visual, Density, Contrast, And Larger Text Readiness

Task support: `7.4`, `7.5`, `8.3`, `8.4`, and `8.5`.

## Scope

This is source-backed readiness evidence for the remaining P1 visual and
accessibility validation pass. It does not claim a live Dynamic Type/larger text
pass, reduced-motion pass, visual capture pass, density pass, or contrast pass.

Tasks `7.4`, `7.5`, `8.3`, `8.4`, and `8.5` remain open until the running
macOS app is reviewed in the required appearances, window sizes, accessibility
settings, and terminal states.

## Source-Backed Readiness

### Larger Text And Dynamic Type

The manual QA matrix and release checklist require larger-text review across
setup, Reading, composer, terminal-owned overlays, recovery, Raw Terminal
chrome, and narrow windows.

Current source still uses fixed SwiftUI font sizes in several product surfaces.
That is allowed as current implementation debt, but it means task `7.4` cannot
be closed from source inspection. Live review must verify whether fixed sizes
remain readable and whether accepted truncation exposes full accessible values.

### Reduced Motion

`reduced-motion-source-evidence.md` records source-backed Reduce Motion support
for identifiable Penggie-owned SwiftUI motion:

- chrome button press/hover/focus animation;
- Reading disclosure expansion;
- terminal-owned candidate list scrolling.

Live Reduce Motion QA remains required because source inspection cannot prove
actual user-perceived transitions, focus affordances, or overlay changes in the
running app.

### Visual Captures

`prepare-product-ui-ux-local-qa.sh` creates a local evidence bundle with
`screenshots/`, `recordings/`, `logs/`, and `notes/`, plus a capture matrix for:

- setup;
- empty Reading;
- long transcript;
- composer focus;
- slash overlay;
- resume picker;
- approval or permission;
- Raw Terminal;
- recovery;
- narrow window;
- large text;
- light mode;
- dark mode.

The script is an evidence scaffold only. It does not launch a second Codex
session and does not replace terminal-frame facts, Raw Terminal parity, or
manual visual review.

### Density And Contrast

The manual QA matrix requires `QA-VIS-002` density and contrast review across
long transcript, CJK/table/code, terminal-owned overlay, and Raw Terminal
screens in light and dark mode.

The source-level theme guard enforces token discipline and blocks scattered raw
colors or built-in Ghostty theme names outside the theme model. This prevents
new local color patches, but it is not a contrast checker. Contrast acceptance
still requires live review of normal text, large text, icons, focus rings,
disabled state, selected rows, warnings, danger, and terminal renderer colors.

## Manual QA Boundary

The readiness guard cannot prove:

- large text keeps setup, Reading, composer, overlays, recovery, and Raw
  Terminal chrome usable;
- narrow windows avoid hidden critical state or unusable controls;
- screenshots exist for every required state;
- visual density is created through hierarchy/disclosure rather than tiny text,
  nested cards, overloaded titlebar, or decorative weight;
- contrast targets are met for all visual states;
- reduced motion feels stable in the running app.

Those checks must be recorded in the release checklist and evidence bundle.

## Verification

- `scripts/qa/check-p1-visual-accessibility-readiness.sh` -> P1 visual/accessibility readiness guard passed.

## Non-Goals

- Do not mark live Dynamic Type, reduced motion, visual capture, density, or
  contrast tasks complete from source evidence.
- Do not use screenshots as terminal-owned state authority.
- Do not launch a second Codex process, SDK session, `codex exec --json`
  session, or second Ghostty/Raw Terminal surface for user-visible QA truth.
- Do not introduce local command, model, resume, approval, permission, or
  selected-index state for visual polish.
