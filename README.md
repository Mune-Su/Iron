# IRON v2.2 — AUTZ Field Assistant

## What's new
- Live Iron: her real portrait animated: blinks, breathes, leans toward your mouse/finger, glows while thinking, lips move when she talks. Works fully offline.
- Iron speaks her replies (🔊 in the top bar, Settings → Voice). Code blocks are skipped.
- 🎤 talk to her (speech-to-text, auto-send optional).
- Phone-ready layout (☰ chat drawer, touch controls) + installable Android app (PWA).
- New default picture/app icon. Chats/settings from v2.0 carry over on the same browser.

## Use on PC
Double-click `index.html` (or keep hosting it, below).

## Put it on your Android phone
1. Host the folder over https (Vercel, from PowerShell in this folder):
   npx vercel --prod
2. On the phone, open the Vercel URL in Chrome → ⋮ → **Install app** (or Add to Home screen).
3. Open Iron from the home-screen icon → Settings → paste your Gemini key → Fetch list → Save.
4. Optional: PC Settings → Data → Export everything, then Import on the phone to bring your chats across.

## Updating
Replace the folder contents and run `npx vercel --prod` again. The phone app downloads the update
in the background and switches to it the next time you open Iron.
