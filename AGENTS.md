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

Account completion is distinct from app creation, closed testing, production access and app approval. Those remain to inspect or complete; no public app release is established. Continue release preparation under Hub #1511 using the current plan. Preserve the production application ID and all six stories; story expansion and save/resume remain proposals pending an implementation decision.

## Play Developer API access: 2026-10-08

Hub #1543 provides agent inspection without browser sign-in. Cloud project `norbonics-play` has Android Publisher API enabled; service account `play-publisher@norbonics-play.iam.gserviceaccount.com` uses Zo shell secret `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`. Read JSON only from the environment, keep credentials in memory, and never write the key or token to disk/logs.

Gerald granted View app information (read-only), Release apps to testing tracks, Manage testing tracks and edit tester lists, and Manage store presence. Production release, user management, financial data and app deletion were deliberately excluded to retain Gerald's production approval boundary and limit access. This task authorized inspection only; it did not authorize testing releases or listing edits. New permissions may take up to 24 hours to propagate; re-run a 401/403 after that window before changing grants.

```bash
python3 /home/workspace/Skills/google-play-api/scripts/check_tracks.py
```

The check opens an empty edit, lists tracks/release names/versionCodes/status and deletes the edit in `finally`, without committing, uploading or changing tracks/listings. It defaults to production package `com.ike.textadventure` and ChallengeBoard `app.challengeboard.twa`; do not substitute the preview identity. The shared Android publishing SOP records the full procedure and cleanup caveats.

Live check 2026-10-08 03:21 UTC: Ike Quest returned HTTP 404 `Package not found: com.ike.textadventure.` No edit was created; record this as the API's current package finding, not a release failure. ChallengeBoard inspection succeeded with five tracks: completed versionCode 2 releases in `internal` and `Track 1`; empty `production`, `beta`, `alpha`. Its edit was successfully deleted. #1511 remains in progress for the existing build/device/signing/store release gates.
