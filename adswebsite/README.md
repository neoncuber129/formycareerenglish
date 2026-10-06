# FormyCareer Ads Website

Static website for policy transparency and Google AdSense review support.

## Files

- `app-logo.png`: Original application logo used across favicon/header/social preview.
- `site.webmanifest`: Web app manifest (name, theme colors, icon).
- `styles.css`: Shared layout, typography, and components (DM Sans + Fraunces via Google Fonts).
- `consent.js`: Cookie consent logic (stores accept/decline choice locally).
- `index.html`: Public product landing page.
- `blog.html`: Blog listing page (all HTML files live in the project root; no subfolders).
- `posts.json`: Blog catalog used for search + tag filters.
- `roadmap-90-ngay.html`, `xay-dung-cv-thuyet-phuc.html`, `ky-nang-tu-hoc-hieu-qua.html`, `chuan-bi-phong-van.html`, `quan-ly-thoi-gian-nguoi-moi.html`: Core blog articles.
- `learning-vocabulary-for-it-roles.html`, `spaced-repetition-explained.html`, `linkedin-profile-checklist.html`, `salary-negotiation-basics.html`, `portfolio-projects-that-impress.html`, `remote-work-readiness.html`, `formycareer-app-guide.html`: Extended article set.
- `about.html`, `terms.html`, `cookies.html`, `disclaimer.html`: Legal/transparency pages for AdSense readiness.
- `privacy.html`: Privacy Policy page.
- `contact.html`: Contact/support page.
- `download.html`: Official release download page.
- `404.html`: Not found page.
- `ads.txt`: AdSense publisher file placeholder.
- `rss.xml`: RSS feed for blog content discovery.
- `robots.txt`: Crawl rules and sitemap location.
- `sitemap.xml`: All public URLs for search engines.
- `vercel.json`: Vercel static config + security headers + optional domain redirect placeholder.
- `desktop-ad-config.json`: Remote config consumed by desktop app to control ad on/off and banner URL.
- `desktop-ad-config.example.json`: Template config for quick edits.
- `desktop-app-config.json`: Remote config for desktop version checks and Pro key activation (week 1 setup).

### Blog routing note

Listing: `/blog.html`. Articles: `/article-slug.html` at the site root. `cleanUrls` is off so paths match the `.html` files on disk.

## Desktop ad remote config

Desktop app fetches this URL on startup:

- `https://formycareer.vercel.app/desktop-ad-config.json`

Current schema:

```json
{
  "enabled": true,
  "adUrl": "https://formycareer.vercel.app"
}
```

- `enabled`: global kill switch for banner ads (`false` hides ads for all non-Pro users).
- `adUrl`: web page loaded inside desktop WebView banner.

Quick operations:

- Turn ads off globally:
  - set `"enabled": false`
- Change banner source URL:
  - update `"adUrl"` to new page/domain

Notes:

- Keep `adUrl` on your controlled trusted domain.
- `desktop-ad-config.json` is set with short cache in `vercel.json` so updates propagate quickly.

## Desktop app update + Pro config

Desktop app fetches this URL on startup and when user presses "Check updates":

- `https://formycareer.vercel.app/desktop-app-config.json`

Current schema:

```json
{
  "latestVersion": "1.0.0",
  "minSupportedVersion": "1.0.0",
  "downloadUrl": "https://formycareer.vercel.app",
  "proProvider": "lemonsqueezy",
  "gumroadProductPermalink": "",
  "gumroadVerifyUrl": "https://api.gumroad.com/v2/licenses/verify",
  "gumroadUseIncrementUsesCount": false,
  "lemonLicenseProxyUrl": "https://formycareer-license-verify.<your-subdomain>.workers.dev/lemon/verify",
  "lemonLicenseProxyAuthToken": "",
  "lemonVerifyUrl": "https://api.lemonsqueezy.com/v1/licenses/validate",
  "lemonActivateUrl": "https://api.lemonsqueezy.com/v1/licenses/activate",
  "lemonInstanceName": "FormyCareer Desktop",
  "lemonStoreName": "Lemon Squeezy",
  "lemonExpectedStoreId": "",
  "lemonExpectedProductId": "",
  "lemonExpectedVariantId": "",
  "licenseVerifyUrl": "https://formycareer-license-verify.maivantungqy98.workers.dev/verify-license",
  "forceUpdate": false,
  "releaseNotes": "Initial public desktop release.",
  "validProKeys": ["FORMYCAREER-PRO-2026"]
}
```

- `latestVersion`: latest published desktop version.
- `minSupportedVersion`: versions below this should update.
- `downloadUrl`: where users download the newest build.
- `proProvider`: activation provider (`lemonsqueezy`, `gumroad`, or `custom`).
- `gumroadProductPermalink`: Gumroad product permalink used for verify API.
- `gumroadVerifyUrl`: Gumroad license verification endpoint.
- `gumroadUseIncrementUsesCount`: whether activation increments Gumroad uses count.
- `lemonLicenseProxyUrl`: optional Cloudflare Worker URL (`…/lemon/verify`). When set, the app verifies Lemon keys through your Worker instead of calling `api.lemonsqueezy.com` directly; product/variant checks can live in Worker env only.
- `lemonLicenseProxyAuthToken`: optional Bearer token sent to the Worker when `LEMON_VERIFY_PROXY_TOKEN` is configured there (same value as the secret).
- `lemonVerifyUrl`: Lemon Squeezy validation endpoint (used only when `lemonLicenseProxyUrl` is empty).
- `lemonActivateUrl`: Lemon Squeezy activation endpoint (reserved for future use).
- `lemonInstanceName`: instance/device label sent to Lemon Squeezy when activation flow is enabled.
- `lemonStoreName`: helper label shown in support/docs.
- `lemonExpectedStoreId`: optional strict store binding.
- `lemonExpectedProductId`: optional strict product binding.
- `lemonExpectedVariantId`: optional strict variant/edition binding.
- `licenseVerifyUrl`: Cloudflare endpoint used only when `proProvider` is `custom`.
- `forceUpdate`: force-update flag.
- `validProKeys`: legacy fallback list for `custom` provider.

Important:

- Recommended production setup is `proProvider: "lemonsqueezy"` with `lemonLicenseProxyUrl` pointing at your Worker’s `POST /lemon/verify` route so validation and product/variant binding stay server-side.
- `custom` provider and `validProKeys` remain as rollback path during migration.

## Before submitting to AdSense

1. Confirm support email is valid in:
   - `privacy.html`
   - `contact.html`
2. Replace placeholders before production:
   - `ads.txt` with your real `pub-xxxxxxxxxxxxxxxx` line.
   - `index.html` meta tags:
     - `google-site-verification`
     - `google-adsense-account`
3. Production URLs are set to `https://formycareer.vercel.app` in canonical tags, JSON-LD, `robots.txt`, and `sitemap.xml`. If you later use a custom domain, replace that base URL everywhere in one pass.
4. Keep adding real blog content regularly (quality over quantity).
5. Deploy to your domain (Vercel URL is fine for first review, but custom domain is recommended).
6. Confirm these URLs are publicly accessible:
   - `/`
   - `/blog.html`
   - `/about.html`
   - `/terms.html`
   - `/cookies.html`
   - `/disclaimer.html`
   - `/privacy.html`
   - `/contact.html`
   - `/download.html`
   - `/ads.txt`
   - `/robots.txt`
   - `/sitemap.xml`
   - `/rss.xml`

## Deploy with GitHub + Vercel

1. Push `adswebsite` folder to GitHub.
2. In Vercel, import repository.
3. Set **Root Directory** = `adswebsite`.
4. Framework Preset = `Other`.
5. Build Command = empty, Output Directory = empty.
6. Deploy and map your custom domain.
7. Optional: set redirect placeholders in `vercel.json`:
   - `REPLACE_WITH_SECONDARY_DOMAIN`
   - `REPLACE_WITH_PRIMARY_DOMAIN`
   (this sends all traffic to one canonical host with 308).

## AdSense readiness notes

- Keep policy pages consistent with app behavior.
- Ensure site has real content, not only placeholder text.
- Keep contact channel valid and monitored.
- Do not place prohibited content.
- After deployment, submit property to Google Search Console, wait for indexing, then request AdSense review.
