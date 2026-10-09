# Google Play Release Checklist

Use this checklist before submitting a new release to Google Play.

Read the shared workflow first: `../../../Docs/Standard-Operating-Procedures/android-play-publishing.md`. Reuse its account, signing, artifact-validation and Console steps; retain this project's Godot, device and content gates below.

Active plan: `../PROJECT_PLAN.md`. Canonical execution task: Hub #1511 (2026-10-02).

## Current testing path (October 9, 2026)

PRs #15 and #16 are merged, including Gerald's privacy-title edit. Speech is
removed; Tess and the Cloud Machine is the sixth story. The current next step is
a separately identified debug APK for phone validation; see `android-candidate.md`
and PR #17 for the exact candidate evidence. It does not replace existing installs
or establish release signing, target-36 device success, or Play acceptance.

## Enrollment and release prerequisites

- [x] Personal developer account created and paid for (Gerald reconfirmed October 3); all three verifications completed October 2. Owner geraldnorby@gmail.com; developer ID `8341017993051504358`. Do not enroll or pay again. Zo browser sign-in failure is separate from enrollment; inspect Console app status and production access before submission.
- [ ] Resolve target-36 preview installation rejection; target-34 diagnostic works on Gerald's Android 13 phone but is not a store release candidate.
- [x] Replace menu and splash portraits with the unchanged approved Norbonics Games master; preserve proportions. Project/Android icons use existing K artwork without portraits; old portrait sources are excluded from exports. Store imagery remains to prepare.
- [x] Include `games.norbonics.com` as visible plain menu text without analytics or automatic browser navigation.
- [ ] Finalize release signing and secure key backup; the "Ike Quest" preset now exports an App Bundle at version 0.7.0 / code 700 with the production application ID preserved.
- [ ] Run internal testing, then required closed testing and production-access application. Recruit at least 12 active testers for a new personal account and keep them opted in continuously for at least 14 days.
- [ ] Obtain Gerald's release decision after addressing story/content feedback and reviewing the final listing.

## Required submission items

- [ ] **Privacy Policy URL**
  - [x] Publish the matching app policy: `https://games.norbonics.com/ike-quest/privacy/`. Anonymous HTML 200 and exact app-policy body verified October 9 at 16:14:34 UTC; Actions run `37957663109`. See `android-candidate.md` for deployment/evidence.
  - [ ] Enter the verified URL in Play Console under a separately authorized submission. No Console field was changed by publication.
  - [x] Full offline policy is available in Parent corner; `docs/privacy-policy.md` describes the speech-free build.
  - Ensure the policy accurately matches the final artifact, including optional bundled sound effects and local saves.
  - Update the policy before release if data practices change.

- [ ] **Data Safety form answers**
  - Complete all required Data Safety questions in Play Console.
  - Confirm whether data is collected, shared, encrypted in transit, and deletable.
  - Re-review after any SDK, analytics, ads, login, or backend change.

- [ ] **Target audience / Families declaration**
  - Set the target age groups in Play Console.
  - Complete Families policy declarations if the app targets children.
  - Verify compliance of all assets, SDKs, and content for the selected audience.

- [ ] **Content rating questionnaire**
  - Fill out the content rating survey accurately.
  - Re-submit questionnaire if game content changes meaningfully.
  - Confirm resulting rating is appropriate for intended audience.

- [ ] **App access instructions (if needed)**
  - Provide reviewer instructions if any area requires specific steps to access.
  - Include demo credentials only if authentication exists.
  - Keep instructions short, precise, and reproducible.

- [ ] **Store listing assets**
  - Prepare and upload required visual assets:
    - App icon
    - Feature graphic
    - Phone screenshots (and tablet/other formats if applicable)
  - Ensure screenshots reflect current gameplay and UI.
  - Verify text and imagery are age-appropriate for chosen audience.

## Suggested final verification pass

- [ ] Version name/code updated correctly.
- [ ] App bundle/APK signed and upload-ready.
- [ ] Release notes added.
- [ ] Policy declarations reviewed one more time before rollout.
