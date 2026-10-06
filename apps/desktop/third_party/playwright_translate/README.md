# Playwright translate sidecar (Google web)

Used by the Flutter desktop app when **Settings → Translation engine → Google Translate (web automation)** is selected.

## Prerequisites

- **Node.js** 18+ on `PATH` (the app invokes `node` and this script).
- Install dependencies and Chromium **once** in this directory:

```bash
cd apps/desktop/third_party/playwright_translate
npm install
npx playwright install chromium
```

## Layout for packaged builds

Copy this entire folder next to the desktop executable as `playwright_translate/`,
including `node_modules` and Playwright’s browser cache, **or** set environment variable:

`PLAYWRIGHT_TRANSLATE_ROOT` = absolute path to this directory (must contain `run_playwright_translate.mjs` and `node_modules/playwright`).

## Behaviour

The script opens `translate.google.com` in headless Chromium and scrapes the
translated output panel.

Do not automate third-party translation websites unless you have permission and
accept their terms of service.
