# Signed builds with GitHub Actions

Release APKs and AABs for Brass & Starlight are built only by GitHub Actions,
never on a local machine. The workflow is
[`.github/workflows/android-release.yml`](../.github/workflows/android-release.yml).

## What the workflow does

It runs on every push (any branch) and on a manual run from the Actions tab
(`workflow_dispatch`):

1. Checks out the code (`actions/checkout@v5`) and sets up Java 17
   (`actions/setup-java@v5`) and Flutter **3.47.9**. The Flutter version is
   pinned on purpose. A newer runner Flutter can need a newer Gradle than
   `android/` uses.
2. Runs `flutter analyze` and `flutter test`.
3. Decodes the upload keystore from the `STARCART_KEYSTORE_BASE64` secret
   into `android/app/starcart-upload.jks` and writes `android/key.properties`
   from the other three secrets. Secrets go through environment variables
   only and are never printed.
4. Builds a signed release APK and AAB, then checks that neither is signed
   with the Android debug key. A missing keystore secret stops the run at
   step 3. Gradle falls back to debug signing only on a local machine with no
   `key.properties`, and this check fails the run if that ever reaches CI.
5. Deletes the keystore and `key.properties` in an `if: always()` step, so
   they are removed even when an earlier step failed.
6. Uploads two artifacts: `brass-and-starlight-release-aab` and
   `brass-and-starlight-release-apk`.

## One-time setup

### 1. Generate the upload keystore

You need a JDK on `PATH` for `keytool` (check with `keytool -help`). Then run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/generate_keystore.ps1
```

On macOS or Linux, run `bash scripts/generate_keystore.sh` instead.

The script asks only for **company details**: company name, organisational
unit, organisation, city, state and a two-letter country code. It also asks
for a key alias, a validity period and two passwords. It does not read your
username, machine name, IP address, location or any other system
information, and it fills nothing in automatically. The certificate holds
only what you type.

It writes two git-ignored files:

- `scripts/starcart-upload.jks`: the upload keystore
- `scripts/starcart-keystore-base64.txt`: the same keystore in base64, for
  the GitHub secret

**Generate the keystore only once.** Google Play accepts updates only when
they are signed with the original upload key, so never create a second one.

### 2. Add the four repository secrets

Add them under GitHub → Settings → Secrets and variables → Actions, or with
the GitHub CLI from the project folder:

```bash
gh secret set STARCART_KEYSTORE_BASE64 < scripts/starcart-keystore-base64.txt
```

```bash
gh secret set STARCART_STORE_PASSWORD
```

```bash
gh secret set STARCART_KEY_ALIAS
```

```bash
gh secret set STARCART_KEY_PASSWORD
```

Each command without `<` prompts for the value, so it never lands in your
shell history.

### 3. Back up, then clean up

- Back up `starcart-upload.jks` and both passwords **offline, in two places
  outside the project folder**.
- Check that the certificate holds no personal name:
  `keytool -list -v -keystore scripts/starcart-upload.jks`.
- Delete `scripts/starcart-keystore-base64.txt` once the secret is saved.

## Running a build

Push any commit, or open the Actions tab → **Android Release Build** → **Run
workflow**. When the run is green, download `brass-and-starlight-release-aab`
from the run's artifacts and upload the `.aab` to Play Console.

On the first upload, let Google manage the app signing key (Play App
Signing). The keystore CI uses is the **upload key**.

## Before each Play upload

Raise `version:` in `pubspec.yaml` (for example `1.0.0+1` → `1.0.1+2`).
The number after `+` is the `versionCode`, and it must be higher than any
build already uploaded.
