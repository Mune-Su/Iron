# IRON v2.3.0 — AUTZ Field Assistant

## What's new in 2.3.0
- New live portrait: Iron now has the new face (pink-and-black rider jacket). She still blinks,
  breathes, leans toward your mouse/finger, glows while thinking and moves her lips when she talks.
- New app icons to match.
- "Model is busy" (503) errors are handled for you: Iron retries twice, then switches to another
  model from your list for that reply (shown under the reply) instead of showing a raw error.

## Updating
PC (from the Iron repo folder):
    & "$HOME\Projects\Iron\update-iron.ps1"
    git commit -m "v2.3.0"
    ipush

`ipush` waits for the Vercel deploy, then starts and watches the Android APK build.
The Android app shows an "Iron 2.3.0 is available" banner on next launch.
