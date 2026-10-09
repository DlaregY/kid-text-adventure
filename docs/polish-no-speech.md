# Polish 3 — defer speech, retain sound, expose the offline policy

Date: 2026-10-09. Base main: `7ef951f3783df1426b1d9c0c30d7fe219adc9714`.

Gerald chose to defer speech rather than make it a first-release dependency.
This implements M02 by removing the feature, not by making claims about an
unverified voice provider. The useful feature may return in a separately scoped,
verified release; it is not required for the current word-tile game.

## Changes

All application TTS calls, voice discovery, speaker button, automatic-reading
toggle, and hold-to-read timer are removed. Engine text-to-speech is explicitly
disabled; CI no longer installs/starts speech services. The six bundled sound
effects remain optional. A held tile is an ordinary release-to-select gesture;
a drag release cannot also select a tile. Old `read_aloud` keys are ignored and
removed when settings are next saved; sound preference, saves and endings stay.

M03 is partly addressed by a full scrollable policy in Parent corner, with a
fixed close button and Back returning one layer at a time. The scene embeds the
policy, so no runtime web request or export inclusion filter is necessary. A
Python test compares it to the Markdown policy to prevent drift. A public URL
must still be hosted and verified; this PR does not publish a site or edit Play.

The current-state plan/agent instructions no longer describe save/resume as
missing. Historical build/device notes are retained and explicitly superseded
where needed. The sixth-story rewrite is a separate PR.

## Verification and boundaries

Run Python unittest discovery and `tests/run_checks.py --suite all` through the
safe wrapper. See the PR's verified-commit results for exact counts/logs/captures.
Tests cover legacy preferences, retained sound events, no speech API/control
paths, drag/hold behavior, policy-copy equivalence, scrolling and Back.

No APK/AAB export, signing, version bump, package-ID change, new permission,
Play mutation, website publication, or merge is authorized or performed here.
No live Zo workspace or Hub #1511 access is available in this runtime, so its
pointer remains to be added there; this file records the status without claiming
a Hub update. Direct network clone failed; a verified GitHub-generated bundle
provided the exact main commit for a local working clone.
