# Google Play Release Checklist

Use this checklist before submitting a new release to Google Play.

Active plan: `../PROJECT_PLAN.md`. Canonical execution task: Hub #1511 (2026-10-02).

## Enrollment and release prerequisites

- [ ] Confirm owner Google account and whether it already has a Play developer account.
- [ ] Complete personal enrollment, payment and identity/contact/device verification. Proposed public display name: Norbonics; support: support@norbonics.com; website: https://norbonics.com/. Gerald must confirm ownership and payment details.
- [ ] Resolve target-36 preview installation rejection; target-34 diagnostic works on Gerald's Android 13 phone but is not a store release candidate.
- [ ] Replace menu portrait with the approved Norbonics Games logo from `../../norbonics-games/assets/logo-clean.png`; preserve proportions and check Android launcher/store imagery for old portrait use.
- [ ] Include `games.norbonics.com` visibly in the menu or About area; plain text is acceptable. Do not add analytics or automatic browser navigation.
- [ ] Finalize release signing, secure key backup, version metadata and Android App Bundle; preserve the production application ID.
- [ ] Run internal testing, then required closed testing and production-access application. Recruit at least 12 active testers for a new personal account and keep them opted in continuously for at least 14 days.
- [ ] Obtain Gerald's release decision after addressing story/content feedback and reviewing the final listing.

## Required submission items

- [ ] **Privacy Policy URL**
  - Add a publicly accessible URL in Play Console.
  - Ensure the policy accurately matches current app behavior.
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
