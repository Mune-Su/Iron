# IRON v2.3.2 — AUTZ Field Assistant

## What's new in 2.3.2
- Default persona is now a proud, fiercely loyal African warrior woman. Replaces the older built-in
  personas automatically; a persona you wrote yourself is left alone.

## What's new in 2.3.1
- New persona: Iron is a warm, friendly woman. Supportive instead of curt, happy to chat casually,
  and she adjusts her tone when you ask. Replaces the old built-in persona automatically
  (a persona you wrote yourself in Settings is left alone).

## What's new in 2.3.0
- New live portrait: Iron now has the new face (pink-and-black rider jacket). She still blinks,
  breathes, leans toward your mouse/finger, glows while thinking and moves her lips when she talks.
- New app icons to match.
- "Model is busy" (503) errors are handled for you: Iron retries twice, then switches to another
  model from your list for that reply (shown under the reply) instead of showing a raw error.

## Updating
PC (from the Iron repo folder):
    & "$HOME\Projects\Iron\update-iron.ps1"
    git commit -m "v2.3.2"
    ipush

`ipush` waits for the Vercel deploy, then starts and watches the Android APK build.
The Android app shows an "Iron 2.3.2 is available" banner on next launch.
