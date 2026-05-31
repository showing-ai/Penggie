## Baseline Evidence

### 2026-05-31 Resume Picker 6.8

Manual verification before this change reported that check 6.8 did not pass while the other manual checks were acceptable.

Observed failure class:

- Raw Terminal could show a terminal-owned selected row marker for resume picker.
- Reading/Chat UI could lose or mis-project the corresponding selected row.
- Confirmation needed to be blocked when Reading could not prove exactly one terminal-owned selected row.

This change treats that as baseline evidence for the Terminal-ground-truth architecture: Reading projections must derive candidates, selection state, confidence, and confirmability from the same Ghostty terminal frame that Raw Terminal renders.
