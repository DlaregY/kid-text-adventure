# Sound assets

## Organic cues, October 14, 2026

Three existing WAVs were replaced with mono 22,050 Hz signed 16-bit PCM exports from the shared Sonniss GDC 2026 library. `scripts/build_sfx.py` pins each full source path and SHA-256, verifies source bytes and rebuilds the files with peak headroom and a short fade.

| Shipped asset | Event | Source |
|---|---|---|
| assets/sfx/tap.wav | Accepted tile tap or drop | Epic Stock Media, Board Game: Organic Connect Dots Fall Bounce 04 |
| assets/sfx/next.wav | NEXT scene transition | Cinematic Sound Design, Paper Foley: Encyclopedia Glossy Page Turn Muted |
| assets/sfx/success.wav | Successful command | CB Sounddesign, Applicable Sounds: Kalimba 3 Up |

Source: https://gdc.sonniss.com/. License: https://sonniss.com/gdc-bundle-license. Commercial game use permitted without attribution. Raw sources remain outside the repository; do not redistribute as a sound library or use for AI training/generation.

Tile drops share the accepted-placement cue with taps. Rejected drops remain silent. The transition fade no longer interrupts the paper cue with the old whoosh. Existing sound preference, speech-free behavior, story identifiers and saves are preserved. Other legacy WAVs are unchanged and their historical provenance remains unverified.

Forty Python tests passed. Godot regression results are recorded in the project plan. Physical Android playback and listening approval remain pending; this is not a Play release.
