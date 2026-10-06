export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";

    if (request.method === "GET" && path === "/health") {
      return json({ ok: true, service: "license-verify" });
    }

    if (request.method === "POST" && (path === "/" || path === "/verify-license")) {
      return verifyLicense(request, env);
    }

    if (request.method === "POST" && path === "/webhook/gumroad") {
      return gumroadWebhook(request, env, url);
    }

    if (request.method === "POST" && path === "/admin/revoke") {
      return revokeLicense(request, env);
    }

    if (request.method === "POST" && path === "/admin/issue") {
      return issueLicense(request, env);
    }

    if (request.method === "POST" && path === "/lemon/verify") {
      return lemonVerifyProxy(request, env);
    }

    return json({ ok: false, message: "Not found" }, 404);
  },
};

/**
 * Proxies Lemon Squeezy: validate (+ optional instance reuse), then activate so
 * activation limits work (POST /v1/licenses/activate). Body:
 * { "licenseKey", "instanceName", "instanceId"? } — instanceId when reusing a
 * prior activation on this device. See License API docs.
 */
async function lemonVerifyProxy(request, env) {
  const proxyToken = String(env.LEMON_VERIFY_PROXY_TOKEN ?? "").trim();
  if (proxyToken && !isProxyBearerAuthorized(request, proxyToken)) {
    return json({ valid: false, message: "Unauthorized" }, 401);
  }
  const body = await tryParseJson(request);
  if (body == null) {
    return json({ valid: false, message: "Invalid JSON body" }, 400);
  }
  const licenseKey = String(body.licenseKey ?? "").trim();
  if (!licenseKey) {
    return json({ valid: false, message: "License key is required" }, 400);
  }
  const instanceName = String(body.instanceName ?? "").trim();
  const instanceId = String(body.instanceId ?? "").trim();

  if (instanceId) {
    const vr = await lemonLicenseValidateRequest(licenseKey, instanceId);
    if (!vr.ok) {
      return json({ valid: false, message: vr.message });
    }
    const chk = lemonParsedLicenseChecks(vr.decoded, env);
    if (!chk.ok) {
      return json({ valid: false, message: chk.message });
    }
    const metaChk = lemonMetaMatchesEnv(vr.decoded?.meta, env);
    if (!metaChk.ok) {
      return json({ valid: false, message: metaChk.message });
    }
    return json({
      valid: true,
      message: "Pro activated successfully.",
      instanceId,
    });
  }

  const vr = await lemonLicenseValidateRequest(licenseKey, "");
  if (!vr.ok) {
    return json({ valid: false, message: vr.message });
  }
  const chk = lemonParsedLicenseChecks(vr.decoded, env);
  if (!chk.ok) {
    return json({ valid: false, message: chk.message });
  }

  if (!instanceName) {
    return json(
      {
        valid: false,
        message:
          "Device label (instanceName) is required. Please update the desktop app.",
      },
      400,
    );
  }

  const ar = await lemonLicenseActivateRequest(licenseKey, instanceName);
  if (!ar.ok) {
    return json({ valid: false, message: ar.message });
  }
  const metaChk = lemonMetaMatchesEnv(ar.decoded?.meta, env);
  if (!metaChk.ok) {
    return json({ valid: false, message: metaChk.message });
  }
  const newId =
    ar.decoded?.instance && ar.decoded.instance.id != null
      ? String(ar.decoded.instance.id)
      : "";
  return json({
    valid: true,
    message: "Pro activated successfully.",
    ...(newId ? { instanceId: newId } : {}),
  });
}

async function lemonLicenseValidateRequest(licenseKey, instanceId) {
  const params = new URLSearchParams({ license_key: licenseKey });
  if (instanceId) {
    params.set("instance_id", instanceId);
  }
  let verifyResponse;
  try {
    verifyResponse = await fetch("https://api.lemonsqueezy.com/v1/licenses/validate", {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: params.toString(),
    });
  } catch (_) {
    return {
      ok: false,
      message: "Cannot reach Lemon Squeezy now. Please try again later.",
    };
  }
  if (!verifyResponse.ok) {
    return {
      ok: false,
      message: "Cannot verify Lemon Squeezy license now. Please try again shortly.",
    };
  }
  let verifyDecoded;
  try {
    verifyDecoded = await verifyResponse.json();
  } catch (_) {
    return { ok: false, message: "Lemon Squeezy response is invalid." };
  }
  return { ok: true, decoded: verifyDecoded };
}

function lemonParsedLicenseChecks(verifyDecoded, env) {
  const valid = verifyDecoded?.valid === true;
  const license = verifyDecoded?.license_key;
  const status =
    license && typeof license === "object"
      ? String(license.status ?? "")
          .trim()
          .toLowerCase()
      : "";
  const licenseStoreId = readNumericIdString(license, "store_id", "storeId");
  const licenseProductId = readNumericIdString(license, "product_id", "productId");
  const licenseVariantId = readNumericIdString(license, "variant_id", "variantId");

  if (!valid || status === "disabled" || status === "expired") {
    return { ok: false, message: "License key is invalid or not active." };
  }

  const expectedStoreId = String(env.LEMON_EXPECTED_STORE_ID ?? "").trim();
  if (
    expectedStoreId &&
    licenseStoreId &&
    licenseStoreId !== expectedStoreId
  ) {
    return { ok: false, message: "This license does not belong to this store." };
  }
  const expectedProductId = String(env.LEMON_EXPECTED_PRODUCT_ID ?? "").trim();
  if (
    expectedProductId &&
    licenseProductId &&
    licenseProductId !== expectedProductId
  ) {
    return { ok: false, message: "This license is not valid for this product." };
  }
  const expectedVariantId = String(env.LEMON_EXPECTED_VARIANT_ID ?? "").trim();
  if (
    expectedVariantId &&
    licenseVariantId &&
    licenseVariantId !== expectedVariantId
  ) {
    return { ok: false, message: "This license is not valid for this edition." };
  }
  return { ok: true };
}

function lemonMetaMatchesEnv(meta, env) {
  if (!meta || typeof meta !== "object") {
    return { ok: true };
  }
  const expectedStoreId = String(env.LEMON_EXPECTED_STORE_ID ?? "").trim();
  const metaStoreId = readNumericIdString(meta, "store_id", "storeId");
  if (expectedStoreId && metaStoreId && metaStoreId !== expectedStoreId) {
    return { ok: false, message: "This license does not belong to this store." };
  }
  const expectedProductId = String(env.LEMON_EXPECTED_PRODUCT_ID ?? "").trim();
  const metaProductId = readNumericIdString(meta, "product_id", "productId");
  if (expectedProductId && metaProductId && metaProductId !== expectedProductId) {
    return { ok: false, message: "This license is not valid for this product." };
  }
  const expectedVariantId = String(env.LEMON_EXPECTED_VARIANT_ID ?? "").trim();
  const metaVariantId = readNumericIdString(meta, "variant_id", "variantId");
  if (expectedVariantId && metaVariantId && metaVariantId !== expectedVariantId) {
    return { ok: false, message: "This license is not valid for this edition." };
  }
  return { ok: true };
}

async function lemonLicenseActivateRequest(licenseKey, instanceName) {
  let res;
  try {
    res = await fetch("https://api.lemonsqueezy.com/v1/licenses/activate", {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        license_key: licenseKey,
        instance_name: instanceName,
      }).toString(),
    });
  } catch (_) {
    return {
      ok: false,
      message: "Cannot reach Lemon Squeezy now. Please try again later.",
    };
  }
  let decoded;
  try {
    decoded = await res.json();
  } catch (_) {
    return { ok: false, message: "Lemon Squeezy activation response is invalid." };
  }
  if (decoded?.activated === true) {
    return { ok: true, decoded };
  }
  const err = String(decoded?.error ?? "").trim();
  if (err) {
    return { ok: false, message: err };
  }
  return {
    ok: false,
    message: "License could not be activated. Please try again or contact support.",
  };
}

function readNumericIdString(obj, snakeKey, camelKey) {
  if (!obj || typeof obj !== "object") {
    return "";
  }
  const value = obj[snakeKey] ?? obj[camelKey];
  if (value == null) {
    return "";
  }
  if (typeof value === "number" && Number.isFinite(value)) {
    return String(Math.trunc(value));
  }
  return String(value).trim();
}

function isProxyBearerAuthorized(request, expectedToken) {
  const auth = request.headers.get("authorization") || "";
  return auth === `Bearer ${expectedToken}`;
}

async function verifyLicense(request, env) {
  const body = await tryParseJson(request);
  if (body == null) {
    return json({ valid: false, message: "Invalid JSON body" }, 400);
  }
  const licenseKey = normalizeKey(body.licenseKey);
  if (!licenseKey) {
    return json({ valid: false, message: "License key is required" }, 400);
  }
  const deviceId = String(body.deviceId ?? "").trim();
  const keyHash = await sha256Hex(licenseKey);

  const hasD1 = Boolean(env.DB);
  if (hasD1) {
    const row = await env.DB.prepare(
      `SELECT id, status, expires_at, max_devices
       FROM licenses WHERE key_hash = ?1 LIMIT 1`,
    )
      .bind(keyHash)
      .first();
    if (!row) {
      return json({
        valid: false,
        message: "License key is invalid. Please check and try again.",
      });
    }
    if (row.status !== "active") {
      return json({ valid: false, message: "License is not active." });
    }
    if (row.expires_at && Date.parse(row.expires_at) < Date.now()) {
      return json({ valid: false, message: "License has expired." });
    }

    if (deviceId) {
      const existingDevice = await env.DB.prepare(
        "SELECT id FROM license_activations WHERE license_id = ?1 AND device_id = ?2 LIMIT 1",
      )
        .bind(row.id, deviceId)
        .first();
      if (!existingDevice) {
        const deviceCountRow = await env.DB.prepare(
          "SELECT COUNT(*) AS total FROM license_activations WHERE license_id = ?1",
        )
          .bind(row.id)
          .first();
        const total = Number(deviceCountRow?.total ?? 0);
        const maxDevices = Number(row.max_devices ?? 2);
        if (total >= maxDevices) {
          return json({
            valid: false,
            message: "Device limit reached for this license.",
          });
        }
        await env.DB.prepare(
          `INSERT INTO license_activations
           (license_id, device_id, created_at, updated_at)
           VALUES (?1, ?2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
        )
          .bind(row.id, deviceId)
          .run();
      } else {
        await env.DB.prepare(
          `UPDATE license_activations
           SET updated_at = CURRENT_TIMESTAMP
           WHERE id = ?1`,
        )
          .bind(existingDevice.id)
          .run();
      }
    }

    await env.DB.prepare(
      `UPDATE licenses
       SET last_verified_at = CURRENT_TIMESTAMP
       WHERE id = ?1`,
    )
      .bind(row.id)
      .run();

    return json({
      valid: true,
      message: "Pro activated successfully.",
      plan: "pro",
    });
  }

  const validKeys = String(env.VALID_LICENSE_KEYS ?? "")
    .split(",")
    .map((k) => normalizeKey(k))
    .filter(Boolean);
  const valid = validKeys.includes(licenseKey);
  return json({
    valid,
    message: valid
      ? "Pro activated successfully."
      : "License key is invalid. Please check and try again.",
  });
}

async function gumroadWebhook(request, env, url) {
  const queryToken = String(url.searchParams.get("token") ?? "").trim();
  if (!isAuthorized(request, env.GUMROAD_WEBHOOK_TOKEN, queryToken)) {
    return json({ ok: false, message: "Unauthorized" }, 401);
  }
  if (!env.DB) {
    return json({ ok: false, message: "D1 binding is missing" }, 500);
  }

  const payload = await parseGumroadBody(request);
  const saleId = String(
    payload.sale_id ?? payload.purchase_id ?? payload.id ?? "",
  ).trim();
  const email = String(payload.email ?? payload.purchaser_email ?? "").trim();
  if (!saleId || !email) {
    return json({
      ok: true,
      ignored: true,
      message: "Webhook received but missing sale_id/email (likely test ping).",
    });
  }

  const existing = await env.DB.prepare(
    "SELECT license_key_masked FROM licenses WHERE sale_id = ?1 LIMIT 1",
  )
    .bind(saleId)
    .first();
  if (existing) {
    return json({
      ok: true,
      reused: true,
      message: "License already exists for this sale.",
      licenseKeyMasked: existing.license_key_masked,
    });
  }

  const plainKey = generateLicenseKey();
  const keyHash = await sha256Hex(plainKey);
  const masked = maskKey(plainKey);
  const maxDevices = Number(env.DEFAULT_MAX_DEVICES || 2);
  const now = Date.now();
  const oneYearMs = 365 * 24 * 60 * 60 * 1000;
  const expiresAt = new Date(now + oneYearMs).toISOString();

  await env.DB.prepare(
    `INSERT INTO licenses
      (sale_id, email, key_hash, license_key_masked, status, plan, max_devices, expires_at, created_at, updated_at)
     VALUES
      (?1, ?2, ?3, ?4, 'active', 'pro', ?5, ?6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
  )
    .bind(saleId, email, keyHash, masked, maxDevices, expiresAt)
    .run();

  const emailSent = await sendLicenseEmail({
    env,
    toEmail: email,
    licenseKey: plainKey,
    expiresAt,
    saleId,
  });

  return json({
    ok: true,
    message: "License issued.",
    licenseKey: plainKey,
    licenseKeyMasked: masked,
    expiresAt,
    emailSent,
  });
}

async function revokeLicense(request, env) {
  if (!isAuthorized(request, env.ADMIN_API_TOKEN)) {
    return json({ ok: false, message: "Unauthorized" }, 401);
  }
  if (!env.DB) {
    return json({ ok: false, message: "D1 binding is missing" }, 500);
  }
  const body = await tryParseJson(request);
  if (body == null) {
    return json({ ok: false, message: "Invalid JSON body" }, 400);
  }
  const saleId = String(body.saleId ?? "").trim();
  const licenseKey = normalizeKey(body.licenseKey);

  if (!saleId && !licenseKey) {
    return json({ ok: false, message: "saleId or licenseKey is required." }, 400);
  }

  let result;
  if (saleId) {
    result = await env.DB.prepare(
      "UPDATE licenses SET status = 'revoked', updated_at = CURRENT_TIMESTAMP WHERE sale_id = ?1",
    )
      .bind(saleId)
      .run();
  } else {
    const keyHash = await sha256Hex(licenseKey);
    result = await env.DB.prepare(
      "UPDATE licenses SET status = 'revoked', updated_at = CURRENT_TIMESTAMP WHERE key_hash = ?1",
    )
      .bind(keyHash)
      .run();
  }

  return json({
    ok: true,
    message: result.meta.changes > 0 ? "License revoked." : "No matching license found.",
  });
}

async function issueLicense(request, env) {
  if (!isAuthorized(request, env.ADMIN_API_TOKEN)) {
    return json({ ok: false, message: "Unauthorized" }, 401);
  }
  if (!env.DB) {
    return json({ ok: false, message: "D1 binding is missing" }, 500);
  }
  const body = await tryParseJson(request);
  if (body == null) {
    return json({ ok: false, message: "Invalid JSON body" }, 400);
  }
  const saleId = String(body.saleId ?? "").trim();
  const email = String(body.email ?? "").trim();
  const plan = String(body.plan ?? "pro").trim() || "pro";
  const maxDevices = Number(body.maxDevices ?? env.DEFAULT_MAX_DEVICES ?? 2);
  const expiresAt = String(body.expiresAt ?? "").trim();
  if (!saleId || !email) {
    return json({ ok: false, message: "saleId and email are required." }, 400);
  }

  const existing = await env.DB.prepare(
    "SELECT id FROM licenses WHERE sale_id = ?1 LIMIT 1",
  )
    .bind(saleId)
    .first();
  if (existing) {
    return json({ ok: false, message: "saleId already exists." }, 409);
  }

  const plainKey = generateLicenseKey();
  const keyHash = await sha256Hex(plainKey);
  const masked = maskKey(plainKey);
  await env.DB.prepare(
    `INSERT INTO licenses
      (sale_id, email, key_hash, license_key_masked, status, plan, max_devices, expires_at, created_at, updated_at)
     VALUES
      (?1, ?2, ?3, ?4, 'active', ?5, ?6, ?7, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
  )
    .bind(
      saleId,
      email,
      keyHash,
      masked,
      plan,
      Math.max(1, maxDevices || 2),
      expiresAt || null,
    )
    .run();

  const sendEmail = body.sendEmail == null ? true : body.sendEmail === true;
  const emailSent = sendEmail
    ? await sendLicenseEmail({
        env,
        toEmail: email,
        licenseKey: plainKey,
        expiresAt: expiresAt || null,
        saleId,
      })
    : false;

  return json({
    ok: true,
    message: "License issued.",
    licenseKey: plainKey,
    licenseKeyMasked: masked,
    emailSent,
  });
}

async function sendLicenseEmail({ env, toEmail, licenseKey, expiresAt, saleId }) {
  const apiKey = String(env.RESEND_API_KEY ?? "").trim();
  const fromEmail = String(env.LICENSE_EMAIL_FROM ?? "").trim();
  if (!apiKey || !fromEmail) {
    return false;
  }

  const expiryText = expiresAt
    ? `Expiry date: ${new Date(expiresAt).toUTCString()}`
    : "Expiry date: Not set";
  const supportEmail = String(env.SUPPORT_EMAIL ?? "FormyCareersupport@gmail.com").trim();

  const html = `
    <div style="font-family:Arial,sans-serif;line-height:1.5;">
      <h2>Your FormyCareer Pro license</h2>
      <p>Thanks for your purchase. Here is your license key:</p>
      <p style="font-size:20px;font-weight:bold;letter-spacing:1px;">${licenseKey}</p>
      <p>Order ID: ${saleId}</p>
      <p>${expiryText}</p>
      <p>How to activate:</p>
      <ol>
        <li>Open FormyCareer desktop app.</li>
        <li>Go to About -> Activate Pro.</li>
        <li>Paste the license key above.</li>
      </ol>
      <p>If you need help, contact ${supportEmail}.</p>
    </div>
  `;

  try {
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: fromEmail,
        to: [toEmail],
        subject: "Your FormyCareer Pro license key",
        html,
      }),
    });
    return response.ok;
  } catch (_) {
    return false;
  }
}

function isAuthorized(request, expectedToken, queryToken = "") {
  const required = String(expectedToken ?? "").trim();
  if (!required) {
    return false;
  }
  if (queryToken && queryToken === required) {
    return true;
  }
  const auth = request.headers.get("authorization") || "";
  if (auth === `Bearer ${required}`) {
    return true;
  }
  const webhookToken = request.headers.get("x-webhook-token") || "";
  return webhookToken === required;
}

function normalizeKey(input) {
  return String(input ?? "").trim().toUpperCase();
}

function maskKey(key) {
  const cleaned = key.replace(/[^A-Z0-9]/g, "");
  if (cleaned.length < 8) {
    return "****";
  }
  return `${cleaned.slice(0, 4)}-****-****-${cleaned.slice(-4)}`;
}

function generateLicenseKey() {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const section = (size) =>
    Array.from({ length: size }, () => alphabet[Math.floor(Math.random() * alphabet.length)]).join("");
  return `FMC-${section(4)}-${section(4)}-${section(4)}`;
}

async function sha256Hex(value) {
  const data = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", data);
  const bytes = new Uint8Array(digest);
  return Array.from(bytes).map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function parseGumroadBody(request) {
  const contentType = request.headers.get("content-type") || "";
  if (contentType.includes("application/json")) {
    return (await tryParseJson(request)) ?? {};
  }
  if (contentType.includes("application/x-www-form-urlencoded")) {
    const form = await request.formData();
    const result = {};
    for (const [k, v] of form.entries()) {
      result[k] = String(v);
    }
    return result;
  }
  return {};
}

async function tryParseJson(request) {
  try {
    return await request.json();
  } catch (_) {
    return null;
  }
}

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Webhook-Token",
  };
}

function json(payload, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      ...corsHeaders(),
    },
  });
}
