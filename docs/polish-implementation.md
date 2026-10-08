# Polish implementation — first batch

Date: 2026-10-08. Base: merged PR #12, `c5d4f8d` (0.7.0).

This batch begins the source-based `POLISH_REVIEW.md` recommendations; it is not release approval and does not claim the entire review is closed.

| Review item | Implemented here |
|---|---|
| M04 | START NEW, confirmation before replacing the single saved run, safe cancel/Android Back, and the saved story's name on CONTINUE. The dialog freezes its requested story; underlying menu handlers ignore input. Endings/settings are preserved. |
| M06, menu portion | Hide and clear the ending badge on returning to the menu; regression coverage includes all ten endings. |
| N07, input/idle portions | Reject drops before slot mutation while blocked, cancel long-press when dragging, block hints consistently, pause/restart idle help around Stop. |
| M07, test infrastructure portion | Disposable player-data staging and fail-closed guards, genuine fallback capture, explicit missing-tile/image-save failures, additional regression assertions, and desktop-only CI. |

Seven Python isolation-runner unit tests were executed successfully in the implementation environment. Godot is unavailable there and a fresh clone failed with a GitHub DNS resolution error. Source was read through the GitHub connector, with local baseline blob hashes verified before editing. Godot runtime results must come from the PR's CI or the documented local wrapper; no runtime pass is claimed by this note.

## Still open

- M01: substantive original-content/rights decision for Spiderdude/Skull Rider.
- M02/M03: offline speech verification or removal, accurate speech disclosures, local readable policy and actual public policy URL.
- M05 and remaining M06: library hint, GO BED/vocabulary treatment, deliberate Bigfoot finish behavior.
- Remaining M07: actual visual inspection of full story/feedback states and Gerald's phone testing.
- M08/M09: store assets/declarations and Android installation/signing/distribution gates.
- Other nice-to-have and later recommendations remain separate work.

All six story files, the production application ID, version metadata, speech configuration, and Android permissions are unchanged in this batch. No Android artifact was built, no main-branch merge or Play change was performed, and live Zo Hub #1511 was not accessed or updated.

## Continuation: batch 2

After PR #13 merged as `82edf765`, the next content-focused batch is documented in
[`polish-story-batch.md`](polish-story-batch.md). It covers M05, the Bigfoot part of
M06, and targeted regression/path/capture evidence. The older pending-CI status
above is historical; each PR's verification section records its tested commit.
