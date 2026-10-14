## Audio candidate, October 14, 2026

`audio/organic-sfx-v01` replaces tap, NEXT and success with wooden, paper and kalimba samples. Accepted drags share the tap cue; transition fades no longer interrupt NEXT. Provenance and reproducible export: `docs/ASSET_REGISTER.md`, `scripts/build_sfx.py`. No speech or save changes. CI run `38606401390` attempt 2 built and verified the debug candidate from `79064bf`: `exports/candidate-audio-79064bf/candidate/`, package `com.ike.textadventure.candidate.r38606401390a2`. https://norbonics.com/ike now serves `/ike/ike-quest-0.7.1-audio-79064bf.apk` (public unlinked download, SHA-256 `fe7a9530…b1a1` verified end-to-end). Separate install and saves; physical listening/device acceptance remains pending. No Play release is authorized.

## Phone feedback and revised branding — October 9, 2026

Gerald installed the API-36 candidate and reported picker/story scrolling blockers
and confusing reversed drops. Prioritize `docs/touch-feedback.md` over release
work. His latest branding direction supersedes October 3: original Ike portrait
on the menu and launcher, Norbonics Games on the in-engine loading splash.
Preserve all six stories, saves, and the production application ID. A new test
APK is not Play/public-release authorization.

# Ike Quest

Shared Android publishing workflow: `../../Docs/Standard-Operating-Procedures/android-play-publishing.md`. Read before release preparation; it captures ChallengeBoard's Play internal-testing lessons and keeps Godot-specific checks separate. This does not establish Ike Quest's release readiness.

Read `CLAUDE.md` for architecture and `PROJECT_PLAN.md` plus `docs/play-release-checklist.md` for current Android release status. This is the existing Godot project, GitHub `DlaregY/kid-text-adventure`.

## Google Play account: completed

Gerald has already created and paid for the Google Play developer account and completed all three enrollment verifications. Verification was reported October 2, 2026; payment explicitly reconfirmed October 3. Do not ask him to enroll or pay again.

- Owner Google account: `geraldnorby@gmail.com`.
- Publishing brand: Norbonics; Android only. ChallengeBoard may use the same account later.
- Developer ID: `8341017993051504358`.
- Console: https://play.google.com/console/u/0/developers/8341017993051504358/.
- Contact choices: `hello@norbonics.com` public, `gerald@norbonics.com` private; Norbonics catch-all delivery was verified.
- Zo browser sign-in is blocked by Google's browser-security error. Gerald can access Console in his own browser. Lack of agent access does not undo completed enrollment.

Account completion is distinct from app creation, closed testing, production access and app approval. Those remain to inspect or complete; no public app release is established. Continue release preparation under Hub #1511 using the current plan. Preserve the production application ID and all six stories. Save/resume, safe replacement, and the Bigfoot story changes are implemented through PRs #12–14. On October 9 Gerald chose to defer speech and originalize the sixth story; see the current-state section in PROJECT_PLAN.md. No release or Play mutation is authorized by those code decisions.

Merged release-preparation baseline: main `2d4e68d` includes PRs #15–18 (speech deferred, original sixth story, isolated Android candidate pipeline, touch scrolling/slot roles/Ike portrait branding). Current phone-test APK: CI run 37987240185 (dispatched on main), `exports/candidate-main-2d4e68d/`, package `com.ike.textadventure.candidate.r37987240185a2`, SHA-256 `6da08c36…a951`. Candidate packages are unique per run, so each installs beside the previous one rather than upgrading it (saves do not carry over). Gerald's phone retest of the touch fixes is still pending; no Play upload or production signing performed. PR #19 (menu polish, v0.7.1/versionCode 701: transparent Ike head cutout, fixed `Norbonics Games · v0.7.1` footer, URL label removed, splash `minimum_display_time=0`) merged to main `6143d94` on 2026-10-10 after review; Phone-test candidate built from main `8b35ea0` by CI run 38095831510: `exports/candidate-main-8b35ea0/`, package `com.ike.textadventure.candidate.r38095831510a1`, 0.7.1/701, SHA-256 `8b31025d…36ae`, debug-signed, not device-tested. Phone retest pending.

## Phone download link (set up 2026-10-09)

Gerald gets the newest test APK on his phone at https://norbonics.com/ike (a Vercel redirect, unchanged per release) or directly at https://gerald.zo.space/ike. That public, unlinked API route 302-redirects (no-store) to a versioned zo.space asset, currently `/ike/ike-quest-0.7.1-audio-79064bf.apk` (audio candidate, refreshed 2026-10-14; see above). Assets are served with a 4-hour cache, so never overwrite one path; for each new phone-test APK: `update_space_asset` to a new versioned path, `edit_space_route('/ike')` to point at it, and verify the redirect plus downloaded hash. Retain the preceding candidate during device acceptance for rollback. Anyone with the URL can download the APK; Play testing tracks replace this once release-signed builds exist.

## Play Developer API access: 2026-10-08

Hub #1543 provides agent inspection without browser sign-in. Cloud project `norbonics-play` has Android Publisher API enabled; service account `play-publisher@norbonics-play.iam.gserviceaccount.com` uses Zo shell secret `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`. Read JSON only from the environment, keep credentials in memory, and never write the key or token to disk/logs.

Gerald granted View app information (read-only), Release apps to testing tracks, Manage testing tracks and edit tester lists, and Manage store presence. Production release, user management, financial data and app deletion were deliberately excluded to retain Gerald's production approval boundary and limit access. This task authorized inspection only; it did not authorize testing releases or listing edits. New permissions may take up to 24 hours to propagate; re-run a 401/403 after that window before changing grants.

```bash
python3 /home/workspace/Skills/google-play-api/scripts/check_tracks.py
```

The check opens an empty edit, lists tracks/release names/versionCodes/status and deletes the edit in `finally`, without committing, uploading or changing tracks/listings. It defaults to production package `com.ike.textadventure` and ChallengeBoard `app.challengeboard.twa`; do not substitute the preview identity. The shared Android publishing SOP records the full procedure and cleanup caveats.

Live check 2026-10-08 20:35 UTC (after Gerald created the app entry): `com.ike.textadventure` reads ok, edit deleted, production/beta/alpha/internal tracks all empty. Earlier check 2026-10-08 03:21 UTC had returned HTTP 404 `Package not found: com.ike.textadventure.` No edit was created; record this as the API's current package finding, not a release failure. ChallengeBoard inspection succeeded with five tracks: completed versionCode 2 releases in `internal` and `Track 1`; empty `production`, `beta`, `alpha`. Its edit was successfully deleted. #1511 remains in progress for the existing build/device/signing/store release gates.
