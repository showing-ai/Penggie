# Manual QA Productization Evidence

This evidence closes task 2.2 for the product-grade UI/UX contract definition
change. The accepted UX contract's scenario QA scripts have been converted into
the executable manual QA plan in the implementation change:

- `openspec/changes/productize-ui-ux-contract/product-grade-ui-ux-manual-qa-script.md`
- `scripts/qa/check-product-grade-ui-ux-manual-qa.sh`

## Coverage

The implementation QA script requires each scenario to declare:

- setup;
- terminal fixture or live terminal setup;
- window size;
- light/dark theme coverage;
- keyboard path;
- VoiceOver applicability;
- expected result;
- Raw Terminal parity note where an inspectable terminal surface exists.

It covers setup/start, New Chat, Close Session, slash suggestions, model/effort
picker, resume picker, approval/permission modal choices, composer/IME/focus,
Reading transcript, Raw Terminal audit/control, keyboard-only accessibility,
dynamic announcements, and visual QA.

The guard script fails if required sections, scenarios, QA fields, or
terminal-ground-truth invariants are removed from the manual QA plan.

## Boundary

This does not claim that manual QA has been executed. Runtime manual QA tasks in
`productize-ui-ux-contract` remain separate and must be completed with evidence
from the running app.

This also does not close task 2.3. Visual review fixtures/captures for the full
long-session, CJK, table, code, tool-heavy, narrow-window, large-text, and
light/dark matrix remain productization work.
