# Playwright Google Translate (desktop)

Desktop translation uses a **Node sidecar** with [Playwright](https://playwright.dev/)
to automate `translate.google.com` and scrape translated output.

## One-time setup (developer machine)

From the repo:

```bash
cd apps/desktop/third_party/playwright_translate
npm install
npx playwright install chromium
```

## Layout next to the executable

The Flutter app looks for a folder named `playwright_translate` next to
`desktop.exe` (Windows) or under `Resources` / `Frameworks` on macOS.
The folder must contain:

- `run_playwright_translate.mjs`
- `node_modules/playwright/` (after `npm install`)
- Playwright browser binaries (after `npx playwright install chromium`)

Override directory with environment variable:

`PLAYWRIGHT_TRANSLATE_ROOT` = absolute path to that folder.

## Windows: copy from `third_party` (optional post-build)

After `npm install` (and `npx playwright install chromium`) in
`third_party/playwright_translate`, the **Windows** `runner_post_build.bat` step
will **robocopy** that folder next to `desktop.exe` as `playwright_translate/`.

- Skips if `playwright_translate/node_modules/playwright/package.json` already
  exists **and** `run_playwright_translate.mjs` is byte-identical to `third_party`.
- Force a full resync: `set FMC_FORCE_PLAYWRIGHT_SYNC=1` then
  `flutter build windows`.

Helper script: [`apps/desktop/windows/runner/sync_playwright_translate.bat`](apps/desktop/windows/runner/sync_playwright_translate.bat).

**Bundling Chromium is large**; you can skip shipping browsers and set
`PLAYWRIGHT_TRANSLATE_ROOT` to a folder on disk instead.

## Requirements

- **Node.js** on `PATH` (`node` / `node.exe`) so the app can spawn the sidecar.
