# Reading Turn Stability Validation

Task: `5.3 Validate completed-turn stability under repaint, resize, later terminal output, Raw Terminal switching, long sessions, process exit, and subsequent prompt submission.`

## Validation Scope

This validation covers completed Reading turns in both transcript paths that currently exist:

- legacy runtime turns in `PenggieReadingTurnStore`,
- Display AST turns in `DisplayTranscriptReconciler`.

The validation does not claim that every Reading visual layout case is productized. Visual stress fixtures remain in `5.4`, `5.6`, `8.3`, and `9.1`.

## Evidence Matrix

| Scenario | Evidence | Result |
| --- | --- | --- |
| Repaint / repeated stable frame | `turnStoreDoesNotDuplicateRepeatedStableSnapshots` and `activeTurnMergesViewportOverlapWithoutDuplicatingRows` | Repeated projections do not duplicate completed or active answer rows. |
| Resize / changed terminal dimensions | `sealedTurnsSurviveResizeRepaintRawSwitchLikeProjectionAndSubsequentPrompt` | A sealed Display AST turn remains unchanged when the same projection returns with different terminal columns/rows. |
| Later terminal output containing sealed history | `sealedTurnsStayStableWhenLaterProjectionContainsHistory` and `turnStoreKeepsCompletedTurnsImmutableAcrossLaterTerminalProjections` | Completed turns are not rewritten by stale or mutated history when a later prompt is active. |
| Raw Terminal switching / same session projection round trip | `sealedTurnsSurviveResizeRepaintRawSwitchLikeProjectionAndSubsequentPrompt` | Re-projecting the same terminal evidence, including terminal-owned overlay rows, does not alter sealed turns. |
| Long session / viewport advances | `turnStoreAccumulatesActiveTurnWhenVisibleProjectionAdvances` and `turnStoreKeepsPreviousLongAnswerWhenNextTurnRunsLong` | Long answers accumulate without losing prior answer content and previous long turns remain stable while the next turn runs. |
| Process exit | `PenggieSessionModel.startScreenPolling()` sets `.exited` and cancels polling when `session.processExited`; `onExit` also sets `.exited` without resetting `readingTurnStore`. | Exit state does not reset or rewrite completed transcript state. App-shell recovery and Raw Terminal availability remain covered by lifecycle tasks. |
| Subsequent prompt submission | `completedTurnStillAcceptsLateTailUntilNextPromptSealsIt`, `turnStoreInterleavesThreeComposerTurnsWhenProjectionMergesAllAnswers`, and `sealedTurnsSurviveResizeRepaintRawSwitchLikeProjectionAndSubsequentPrompt` | A new prompt seals prior completed output; later projections append to the new assistant turn without mutating prior turns. |
| Active terminal-owned surfaces | `nativeOverlayBlocksNeverEnterSealedTranscript` and `sealedTurnsSurviveResizeRepaintRawSwitchLikeProjectionAndSubsequentPrompt` | Overlay blocks are filtered and do not become sealed assistant content. |

## Acceptance Notes

- The tests assert visible output order and block roles rather than implementation-private IDs.
- The process-exit validation is code-path evidence because exit is controlled by `PenggieSessionModel`, not by `PenggieReadingTurnStore` or `DisplayTranscriptReconciler`.
- Raw Terminal switching is validated as a same-session projection round trip at the transcript layer. Full keyboard/focus and visual parity remain in Raw Terminal tasks.
- This task validates stability invariants; it does not replace fixture expansion for CJK, tables, code, warnings, low-confidence fallback, or large preformatted output.

## Result

Task `5.3` is complete for transcript stability invariants. Remaining Reading work should focus on fixture breadth, pollution prevention, fallback traceability, and visual/accessibility QA.
