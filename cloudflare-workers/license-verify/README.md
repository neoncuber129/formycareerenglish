# FormyCareer License Verify Worker

Cloudflare Worker API for desktop Pro key verification with D1 persistence.

Note:

- For Lemon Squeezy, prefer `POST /lemon/verify` as a proxy: the desktop app calls your Worker only; the Worker calls Lemon and enforces `LEMON_EXPECTED_*` env vars.
- This worker also serves the `custom` provider path (`/verify-license`), admin tooling, and webhook-based key issuance.

## Endpoints

- `GET /health`
  - Basic health check.
- `POST /verify-license` (or `POST /` for backward compatibility)
  - Body:
    ```json
    { "licenseKey": "FMC-XXXX-XXXX-XXXX", "deviceId": "optional-device-id" }
    ```
  - Response:
    ```json
    { "valid": true, "message": "Pro activated successfully.", "plan": "pro" }
    ```
- `POST /lemon/verify`
  - Validates with `https://api.lemonsqueezy.com/v1/licenses/validate`, then calls `https://api.lemonsqueezy.com/v1/licenses/activate` so Lemon **activation limits** apply (see [Activate a License Key](https://docs.lemonsqueezy.com/api/license-api/activate-license-key)).
  - Body:
    - `licenseKey` (required)
    - `instanceName` (required) — stable per-device label from the desktop app (e.g. product name + UUID).
    - `instanceId` (optional) — when the app already has a Lemon instance UUID for this key on this device, validates that instance only (no new activation slot).
  - Response: `{ "valid": true|false, "message": "...", "instanceId"?: "<uuid>" }` — `instanceId` is returned on success so the client can persist it for reuse.
  - Configure `[vars]` or dashboard: `LEMON_EXPECTED_PRODUCT_ID`, `LEMON_EXPECTED_VARIANT_ID`, `LEMON_EXPECTED_STORE_ID` (empty string skips that check).
  - Optional: `wrangler secret put LEMON_VERIFY_PROXY_TOKEN` — when set, client must send `Authorization: Bearer <token>` (desktop: `lemonLicenseProxyAuthToken` in remote JSON, or leave both unset for an open proxy).
- `POST /webhook/gumroad`
  - Creates a license after purchase webhook.
  - Auth via header `X-Webhook-Token: <GUMROAD_WEBHOOK_TOKEN>` or `Authorization: Bearer <token>`.
  - Accepts `application/json` or `application/x-www-form-urlencoded`.
  - If `RESEND_API_KEY` and `LICENSE_EMAIL_FROM` are configured, license key is emailed automatically.
- `POST /admin/issue`
  - Manual license issue endpoint.
  - Requires `Authorization: Bearer <ADMIN_API_TOKEN>`.
- `POST /admin/revoke`
  - Revoke by `saleId` or `licenseKey`.
  - Requires `Authorization: Bearer <ADMIN_API_TOKEN>`.

## 1) Configure Wrangler

Edit `wrangler.toml`:

- Replace `database_id` in `[[d1_databases]]`.
- Keep `VALID_LICENSE_KEYS` only as temporary fallback.
- Set `DEFAULT_MAX_DEVICES` as needed.

## 2) Create D1 database + apply schema

From this folder:

```bash
wrangler d1 create formycareer_licenses
```

Copy returned database ID into `wrangler.toml`, then run:

```bash
wrangler d1 execute formycareer_licenses --file migrations/0001_init.sql
```

## 3) Set secrets

```bash
wrangler secret put ADMIN_API_TOKEN
wrangler secret put GUMROAD_WEBHOOK_TOKEN
wrangler secret put RESEND_API_KEY
wrangler secret put LICENSE_EMAIL_FROM
```

Optional:

```bash
wrangler secret put SUPPORT_EMAIL
wrangler secret put LEMON_VERIFY_PROXY_TOKEN
```

Lemon proxy expected IDs can stay in `wrangler.toml` `[vars]` (`LEMON_EXPECTED_*`) or be set in the dashboard.

## 4) Deploy

```bash
wrangler deploy
```

## 5) Connect desktop app

Put deployed worker URL into:

- `adswebsite/desktop-app-config.json` field `licenseVerifyUrl`

Example:

```json
{
  "licenseVerifyUrl": "https://formycareer-license-verify.<your-subdomain>.workers.dev/verify-license"
}
```

## Quick tests

Verify key:

```bash
curl -X POST "https://<worker>.workers.dev/verify-license" \
  -H "Content-Type: application/json" \
  -d '{"licenseKey":"FORMYCAREER-PRO-2026"}'
```

Manual issue:

```bash
curl -X POST "https://<worker>.workers.dev/admin/issue" \
  -H "Authorization: Bearer <ADMIN_API_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"saleId":"manual-001","email":"user@example.com","maxDevices":2}'
```

## Gumroad webhook setup

In Gumroad product settings:

- Webhook URL:
  - `https://formycareer-license-verify.maivantungqy98.workers.dev/webhook/gumroad`
- Add header:
  - `X-Webhook-Token: <GUMROAD_WEBHOOK_TOKEN>`

Expected payload fields (JSON or form data):

- `sale_id` (or `purchase_id` / `id`)
- `email` (or `purchaser_email`)

Worker creates license, stores hash in D1, and sends email automatically when Resend secrets are configured.
