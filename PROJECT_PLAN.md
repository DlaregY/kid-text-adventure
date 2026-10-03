# Ike Quest Android release

Updated: 2026-10-03. Status: approved Norbonics Games menu and splash branding plus a visible Games URL implemented. Android 36 toolchain preview rebuilt for a new device check; the original target-36 installer rejection remains unproven. Gerald confirms the earlier target-34 preview and basic Bigfoot gameplay work on his phone. Story pacing, ending presentation and save/resume remain proposals.

## Goal and scope

Prepare Ike Quest for Android distribution under the Norbonics brand. Gerald chose Android only because he and his close associates cannot test iOS. First establish a working phone build, then prepare Google Play enrollment and release. ChallengeBoard follows separately.

Gerald authorized starting account setup and release preparation on October 2, including tracking replacement of his picture with the approved Norbonics Games logo and an in-app Games URL. Canonical execution task: Hub #1511. Gerald subsequently reports account setup and all three verification steps complete; Console status has not been independently inspected. No app submission or public release is recorded. Preserve all six stories and the existing production package identifier. Story expansion and save/resume remain proposals pending a separate implementation decision.

## Account setup and release preparation

**Latest status, October 2:** Gerald reports completing all three verification steps and account setup. This supersedes the outstanding enrollment/sign-in notes below, retained as historical context. It does not establish production access or app approval. Enrollment used geraldnorby@gmail.com, with hello@norbonics.com recommended for public contact and gerald@norbonics.com for Google's private contact; catch-all delivery to norbonics@outlook.com was verified earlier in this conversation.

Enrollment recommendation: personal account, developer display name **Norbonics** (covers games and future ChallengeBoard), studio website https://norbonics.com/, public developer/support email support@norbonics.com. Confirm the owner Google account with Gerald before registration; recommended geraldnorby@gmail.com. Google permits a separate developer display name but also displays legal name, country and developer email; monetization exposes the full legal address, with additional regional disclosures possible. Registration costs $25 once. Payment, identity checks and verification codes remain outstanding; no payment authorized or made.

Browser checks on October 2 reached the Google account chooser through the Play Console sign-in link. Both listed Google accounts are signed out, including geraldnorby@gmail.com. Existing developer-account status is therefore unknown; owner choice and interactive sign-in remain pending. No registration form has been submitted.

Release checklist: `docs/play-release-checklist.md`. Begin with enrollment and resolving the target-36 build installation issue, then signing/AAB and declarations, followed by internal/closed testing and a separately approved public launch. A new personal account requires 12 testers continuously opted in for 14 days before applying for production access.

Approved branding requirements (implemented October 3, Hub #1511):
- Replace the menu portrait with the unchanged approved transparent master `../norbonics-games/assets/logo-clean.png` (1888x833); preserve its aspect ratio. Inspect launcher/store icons for the old portrait as part of the same pass.
- Show `games.norbonics.com` in the app, proposed beneath the menu branding as a plain URL. Full destination https://games.norbonics.com/ returned HTTP 200 on October 2. A plain URL meets Gerald's request without adding browser navigation to the child-facing flow.

The unchanged master is copied to `assets/branding/norbonics-games.png` and displayed with preserved proportions. Menu and boot splash now use it. The project icon and all Android launcher variants use the existing K artwork, which contains no portrait. Old portrait source images are retained but excluded from exported assets. The Games URL is plain menu text. A 540x960 desktop capture is saved at `exports/norbonics-menu-preview.png`; this is not a phone screenshot.

October 3 verification: both branded previews built successfully. The default APK reports compile SDK 36, target 36, min 24, preview package `com.ike.textadventure.preview`, version 0.6.0/code 600, ARM64 and no permissions. Android-13-specific signature verification, APK CRC integrity, 16 KB ZIP/native ELF alignment, six byte-identical story JSONs, version metadata and exact branding master all passed. The old portraits are absent from packaged assets. Godot regression rendered all 55 scenes across six stories without failures. Original unbranded APKs are preserved as `exports/ike-quest-preview-original-target36.apk` and `exports/ike-quest-preview-original-target34.apk`.

Fresh download filenames avoid confusion with the earlier previews:
- `exports/ike-quest-preview-norbonics-target36.apk`: SHA-256 `89c50313330e914f1e23f1ead20dc47d3bfe4f004f8a5f91191d4e23f710dec7`.
- `exports/ike-quest-preview-norbonics-target34.apk`: SHA-256 `e89184572b27dd8757f67ac506131ed2e9e768d0a74b548699222d9cf66ff743`.

Both retain the earlier debug signer and preview identity. Phone installation and runtime of these new artifacts remain untested. Production identity stays `com.ike.textadventure`. Hub #1511 remains in progress.

Enrollment sources checked October 2:
- https://support.google.com/googleplay/android-developer/answer/13628312
- https://support.google.com/googleplay/android-developer/answer/6112435

## Strategy

Use Godot 4.6.1 with the existing portrait/tile UI. Distribute a separate debug-signed preview package for the first device check. Keep the app offline without ads, accounts, analytics, or permissions. Resolve device findings before preparing a release-signed AAB and store declarations.

## Implementation status

- [x] Pulled repository; baseline `6bf1101`, clean before work. Actual remote is `DlaregY/kid-text-adventure`.
- [x] Confirmed and repaired parser-breaking indentation in `scripts/Game.gd` story validation. Godot previously reported an expected-indented-block error at line 326.
- [x] Explicitly include `stories/*.json` and `version.txt` in exports; exclude development docs/tasks/tests.
- [x] Raised target SDK from 34 to 36. Google's current new-app requirement is API 36.
- [x] Installed local build prerequisites and added `scripts/build_android_preview.py`.
- [x] Produced `exports/ike-quest-preview.apk`, package `com.ike.textadventure.preview`, label `Ike Quest Preview`, version 0.6.0/code 600. The separate identifier avoids replacing an existing install or requiring its signing key. Production version is unchanged; bump before a Play release.
- [x] APK signature verification passed; min SDK 24, target SDK 36, ARM64; all six story JSON files and version file packaged; manifest declares no permissions.
- [x] APK 16 KB ZIP alignment passed; native Godot ELF LOAD segments use 16 KB alignment. Runtime on a 16 KB device and eventual AAB validation remain untested.
- [x] Godot headless smoke checks passed for six story loads and 55 scene layouts, invalid requirements/effects rejection, and inventory/flag acquisition and removal. Test: `tests/story_smoke.gd`.
- [x] Independent state search visited 125 reachable scene/inventory/flag states. All 55 scenes and nine terminal endings reachable; zero reachable states without a terminal path. Search models available tiles, first matching eligible rules, inventory and flags. It does not replace real tap/drag playtesting or editorial review.
- [x] Gerald confirmed installation of the target-34 diagnostic preview on his Android 13 moto g stylus 5G (2022).
- [x] Gerald reports the requested basic phone checks work (text, emoji, tapping, switching away/back) and reached the Bigfoot friend ending. This is not exhaustive coverage of every story or interaction.
- [ ] Complete remaining device coverage: other endings/stories, drag/drop, hints, new-game and Android Back.
- [x] Record phone model, Android version and device findings: Gerald's screenshot confirms moto g stylus 5G (2022), XT2215-4; he reports Android 13 (T2SD S33.75-38-1-3-30). Preview installation reports an invalid package. Download shows 80.59 MB, consistent with the server's 80,591,072 bytes at that precision, but not a checksum verification. Earlier GitHub APKs installed and ran successfully on this phone.

### Installation diagnosis, October 2

Downloaded the unchanged GitHub v0.6.0 asset to `exports/comparison-v0.6.0/ike-adventure.apk` (80,977,213 bytes) for a same-download-channel comparison. Its embedded Android version is 0.2.1/code 2 despite the release tag. Compared with the failing preview: identical `classes.dex`, Godot native library and C++ native library hashes; same ARM64 architecture, min SDK 24, Godot 4.6.1, native compression and alignment. Manifest differences are package/provider identifiers, version metadata, and target SDK 34 versus 36. Preview ZIP integrity, uncompressed/aligned resources and Android-13-specific signature verification pass. No installation cause established; source checks cannot validate the downloaded phone copy or its installer handoff. No device or accelerated Android emulator is attached. Next diagnostic: try the unchanged GitHub asset through Zo, opening it from Files/Downloads, without uninstalling the existing game. A baseline failure would implicate delivery/installer handling or device state; baseline success would narrow investigation to differences in the preview.

### Playtest feedback, October 2

Gerald reports the app itself works fine, but the Bigfoot friend ending arrives too quickly, before enough has happened. He dislikes announcing the ending as the page title and suggests smaller lettering. Preserve this as feedback pending a story/layout decision; no content or UI changes authorized by his question about releasing updates. He is weighing improvements before launch against starting Play preparation and iterating through later releases.

## Readiness findings and release gates

Diagnostic update, October 2: Gerald successfully installed both the unchanged v0.6.0 comparison APK and then `exports/ike-quest-preview-target34.apk` through Zo on the same phone. The diagnostic was built with `scripts/build_android_preview.py --diagnostic-target-34`, retaining current content, preview identity and signing key while using target SDK 34. This implicates the target-36 build configuration, but does not establish the precise Android installer rejection reason or mean Android 13 universally rejects target-36 apps. Use the installed diagnostic for gameplay testing; investigate the modern-target build before store preparation. The default target-36 preview and production preset remain unchanged. This is a sideload diagnostic, not a Play release candidate. Gameplay results remain pending.

1. **Progress is memory-only.** Force-stop or process death loses the current story. No save/resume implementation or mid-story restart control was added. Recommend local checkpoint/resume before public launch; decide after the phone test.
2. **Basic device compatibility confirmed on one phone.** Gerald reports the target-34 preview works on his Android 13 moto g stylus 5G (2022). Project uses Forward Plus rendering and system emoji fonts. Broader device coverage, Android 16 safe areas, gesture navigation and large font behavior remain unverified.
3. **Build toolchain needs a release pass.** The October 3 default preview builder stages the Godot template with compile SDK 36, Build Tools 36.0.0 and AGP 8.9.2, retaining Gradle 8.11.1 and Java 17. The target-34 diagnostic retains the earlier template configuration. This removes the default preview's compile-35/target-36 mismatch; it does not establish the reason for the phone's rejection. A production build using the preset directly still needs the equivalent toolchain pass and bundle validation. No Play acceptance is inferred from APK construction.
4. **Production signing/AAB not prepared.** No upload/release key generated; no Play App Signing configuration changed. Keep future production keys out of the workspace. Verify native 16 KB page support and bundle validation before submission.
5. **Privacy document is a draft.** `docs/privacy-policy.md` still names Norbonics Industries and an older contact. Reconcile with current Norbonics identity/support contact, actual final behavior and a public policy URL before launch. No policy was published.
6. **Audience/content decisions remain.** Early-reader positioning requires an accurate target-audience/Families declaration, content rating and Data Safety form. Review story/icon/asset provenance; the Spiderdude/Skull Rider story needs a deliberate public-release content decision. Renaming alone does not establish rights clearance.
7. **Store setup and testing remain.** Gerald reports enrollment and all three verifications complete; do not enroll again. Console app status and production access remain uninspected. A new personal account requires 12 testers continuously opted in for 14 days before applying for production access. Phone sideloading does not count toward that closed test.
8. **Listing assets remain.** Capture real device screenshots and prepare feature graphic, description and support links after UI verification.

## Local build and verification

`exports/` is Git-ignored and contains `.gdignore`, downloads, isolated build staging, logs and APKs. OpenJDK 17 is installed system-wide; Godot 4.6.1 and Android SDK tools live in `exports/toolchain/`. The preview builder checks prerequisites and stages the current source with a separate application ID. It requires `android_debug.apk`, `android_release.apk`, `android_source.zip` and `version.txt` from the matching official export templates; Android SDK platform/build tools must already be installed. No production keystore is used.

```bash
python3 /home/workspace/Projects/ike-quest/scripts/build_android_preview.py
/home/workspace/Projects/ike-quest/exports/toolchain/Godot_v4.6.1-stable_linux.x86_64 --headless --path /home/workspace/Projects/ike-quest --script res://tests/story_smoke.gd
```

Initial APK SHA-256: `87ed63a586c94071094e4f4fe7c8b390c9d742ca7918737100a8e631c10a296c`.

The initial export completed with Godot shutdown/scan warnings and an unavailable ADB daemon in Zo. No phone is attached; `/dev/kvm` is unavailable. The concrete next step is to install the rebuilt target-36 preview on Gerald's phone, retaining the working diagnostic. If it fails, capture the exact ADB installer error and package-manager log rather than changing more settings without evidence. No story/save changes or publication were performed.

## Sources checked October 2, 2026

- https://support.google.com/googleplay/android-developer/answer/11926878
- https://support.google.com/googleplay/android-developer/answer/14151465
- https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html
- Android 16 toolchain setup checked October 3: https://developer.android.com/about/versions/16/setup-sdk
