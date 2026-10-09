# Android candidate preparation and phone handoff

October 9, 2026. Gameplay baseline: main `0193dbac8efef1337358339e63a7e06ebb9b07bc`
(merged speech removal, Tess rewrite and Gerald's policy-title revision).

## What this workflow does

`Android test candidate` builds a debug-signed ARM64 **APK for sideload testing**,
not a Play release. It uses an official checksum-verified Godot 4.6.1 binary and
export templates, JDK 17, compile/target SDK 36, Build Tools 36.0.0, AGP 8.9.2 and
the template's Gradle wrapper/NDK 28.1.13356709. The template patch is shared with
`scripts/build_android_preview.py`; unknown template changes fail rather than
silently producing a different toolchain.

Use the workflow's Run workflow control after this workflow reaches main.
The temporary branch-specific push trigger exists only for this implementation
branch; main pushes do not automatically build or publish APKs. Neither trigger
uploads to Play, creates a GitHub Release, or uses production signing material.

The production AAB path is still a separate signing/bundle-validation gate. Reuse
the verified template preparation there rather than exporting the unpatched
upstream template and assuming preview evidence applies. A reproducible recipe
is not a promise of byte-identical APKs: each candidate gets a disposable debug
key, and Android builds can contain timestamps.

## Local equivalent

Run on a clean committed checkout after installing the pinned prerequisites:

```bash
python3 scripts/android_candidate.py \
  --godot /path/to/Godot_v4.6.1-stable_linux.x86_64 \
  --sdk /path/to/android-sdk --templates /path/to/4.6.1/templates \
  --java /path/to/jdk17 --candidate-id localtest1 --output exports/candidate
```

Use a new candidate ID for every new key/build. The ID starts with a lowercase
letter and contains only lowercase letters/digits. CI uses its run ID/attempt.
The builder stages files/configuration and generates its disposable key outside
the repository; it does not touch normal Godot player data. No key is uploaded.
Production ID `com.ike.textadventure` and the older `.preview` ID are unchanged.

## Read the artifact evidence, not just a green build

A successful run supplies the APK, `SHA256SUMS`, `candidate-evidence.json`, and
raw inspection logs. The validator checks actual package/version/min/target SDK,
zero requested Android permissions, backup disabled, signature validity (also
against API 33), ZIP CRC/integrity, 16 KB ZIP/native LOAD alignment, six exact
story JSON files, version.txt, provenance JSON and a packaged privacy dialog.
Development/signing files and old root portrait PNGs must not be packaged.

The gameplay source remains speech-free. Source scans and permission inspection
are not a packet-capture test of the final app or its operating system.

The candidate requests Godot's **Mobile renderer** explicitly in staged config;
the production project's defaults are not changed. `renderer_observed_on_device`
remains null until a real launch log establishes it, including any fallback.
Desktop checks use Compatibility and do not prove Vulkan/Mobile behavior.
`--renderer gl_compatibility` is available for a separately named diagnostic, not
an automatic renderer change to conceal a failure.

## Gerald's phone pass

Install the APK labeled **Ike Quest Test <candidate-id>**. It has a unique
`com.ike.textadventure.candidate.<candidate-id>` identity, so it can coexist with
both the working game and the old preview. **Do not uninstall either existing
app or clear its storage.** This test starts with its own empty progress; it is
not an in-place upgrade or a migration test. Later disposable candidates also
have their own progress. The APK is not a store-approved release.

1. Open the downloaded APK from Files/Downloads. Record the phone model, Android
   version, filename/candidate ID, and whether installation and launch succeed.
   The first install/launch is the immediate gate; report an exact error before
   changing settings or trying different builds.
2. Start an adventure, collect an item, return to the menu, force-stop **only the
   test app** in Android settings, then reopen it and CONTINUE. Confirm story,
   location and items survive. Cancel START NEW, including with Back, and verify
   the checkpoint stays intact. Then confirm a fresh start deliberately.
3. Check taps, held taps and drags, slot clearing, hints, NEXT, sound on/off,
   Back/Home and Parent corner -> Privacy -> Back -> Parent corner -> Back.
   Scroll the policy to its last line. Verify no speaker/reading controls remain.
4. Play Tess end to end and try several Bigfoot endings. Check readability and
   long/full-inventory screens. Observe any pauses, crashes, missing symbols or
   controls obscured by system bars. Repeat on Android 16/API 36 or another
   representative newer device when available; Android 13 alone cannot close
   the newer edge-to-edge/Back gate.

With Android Platform Tools available, obtain the precise installer result:

```powershell
adb install "<the exact candidate APK path>"
```

After launch, record the renderer and crashes with a focused log (review before
sharing; device logs can contain unrelated information):

```powershell
adb logcat -d -s godot:I AndroidRuntime:E
```

Do not reduce the release target SDK or remove a working install to work around
an unexplained installer error. The separate identity avoids signer conflicts
with existing apps. A successful debug sideload is not final Play signing,
release-mode behavior, store acceptance, or a 16 KB device-runtime test.

## Public policy and release gates

The policy is published at `https://games.norbonics.com/ike-quest/privacy/`.
Website PR #1 in `DlaregY/norbonics-games` was merged as `166630e` under the
approved publication scope. Vercel reported a successful deployment. Anonymous
HTTPS verification at 2026-10-09 16:14:34 UTC returned a direct HTML 200 response,
with an exact normalized body match to the app policy. Evidence: GitHub Actions
run `37957663109`, artifact `11629070356`. HTML SHA-256:
`2926f2e49e2745b718f809df8fc2769a5ad625938963d56f2f217a48d22110a3`.
The page has no scripts and distinguishes app privacy from website privacy.
No game catalogue link was added; this is not publication of the game. The URL
has NOT been entered in Play Console. Repeat the anonymous check after policy
changes: `python3 scripts/check_public_privacy.py` (requires networking).

Still separate: phone results, any resulting fixes, secure production upload-key
backup, release AAB/bundletool validation, current store assets and declarations,
explicit internal-track upload approval, required testing/access, and public
launch approval. No Play or live Hub #1511 mutation is part of this batch.

Primary technical references (checked October 9): Godot 4.6.1 Android
`platform/android/java/app/config.gradle` in the official source; Android 16 SDK
setup (`developer.android.com/about/versions/16/setup-sdk`); Android 16 behavior
changes (`developer.android.com/about/versions/16/behavior-changes-16`).
