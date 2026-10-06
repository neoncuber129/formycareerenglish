# Hotkey + Real Data Manual Checklist (Windows)

## Preconditions
- App built with required env:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
- For translation: Playwright sidecar bundle next to the app (`playwright_translate/`).
- App started once while focused so global hotkeys can register to current app window handle.

## Text Mode (Ctrl+Shift+D)
- Turn **Study mode ON** in app.
- Switch to another app (browser/notepad), select a word or short phrase.
- Press `Ctrl+Shift+D`.
- Confirm popup appears near cursor with detected text and translated meaning.
- Press save and confirm message:
  - signed in: `Saved ✓`
  - not signed in: `Saved locally. Sign in to sync.`

## Text Mode Gating
- Turn **Study mode OFF** in app.
- Switch to another app, select text, press `Ctrl+Shift+D`.
- Confirm popup does not open.

## Image Mode (Ctrl+Shift+X)
- Switch to another app and press `Ctrl+Shift+X`.
- Drag-select a region containing visible text.
- Confirm popup appears with OCR text + translation.
- Confirm `Esc` cancels region selector without crash.

## Sync End-to-End
- Capture and save at least one item while online.
- Verify record exists in local list immediately.
- If signed in, verify record appears in Supabase `vocab` table after sync cycle.
- Turn network off, save new item, then turn network on.
- Confirm background retry syncs pending item when network returns.

## Diagnostics
- Verify UI hotkey diagnostics line shows:
  - `supported=true`
  - `bridge=true`
  - registered hotkey ids include image id, and text id only when study mode is ON.
