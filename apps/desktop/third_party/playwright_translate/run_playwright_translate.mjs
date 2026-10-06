#!/usr/bin/env node
/**
 * stdin: one UTF-8 JSON object:
 *   { "text": "...", "from": "en", "to": "vi", "mode": "google_web|deepl_web" }
 * stdout: UTF-8 JSON:
 *   { "translatedText": "...", "detectedSourceLanguage": "..." }
 * stderr: errors / warnings
 */
import { chromium, request as playwrightRequest } from "playwright";

function reconfigureUtf8() {
  try {
    if (typeof process.stdout.reconfigure === "function") {
      process.stdout.reconfigure({ encoding: "utf-8" });
    }
    if (typeof process.stderr.reconfigure === "function") {
      process.stderr.reconfigure({ encoding: "utf-8" });
    }
  } catch {
    // ignore
  }
}

async function readStdinJson() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const raw = Buffer.concat(chunks).toString("utf-8").trim();
  if (!raw) {
    return null;
  }
  return JSON.parse(raw);
}

function normalizeGoogleLang(code) {
  const raw = String(code || "").trim();
  if (!raw) return "";
  if (raw.toLowerCase() === "autodetect") return "auto";
  if (raw.toLowerCase() === "zh") return "zh-CN";
  if (raw.toLowerCase() === "zt") return "zh-TW";
  return raw;
}

async function waitForGoogleOutput(page) {
  const candidates = [
    '[jsname="W297wb"]',
    'div[aria-live="polite"] span',
    'span[data-language-for-alternatives]',
    'div[role="region"] span[jsname]',
    '[data-result-index] [jsname]',
  ];
  const started = Date.now();
  let last = '';
  let stableHits = 0;
  while (Date.now() - started < 30000) {
    for (const selector of candidates) {
      const target = page.locator(selector);
      const count = await target.count();
      if (count <= 0) {
        continue;
      }
      const candidate = (await target.first().innerText()).trim();
      if (!candidate) {
        continue;
      }
      if (candidate && candidate !== last) {
        last = candidate;
        stableHits = 1;
      } else if (candidate === last) {
        stableHits += 1;
        if (stableHits >= 2) {
          return candidate;
        }
      }
    }
    await page.waitForTimeout(250);
  }
  return '';
}

async function waitForDeepLOutput(page) {
  const selectors = [
    'd-textarea[data-testid="translator-target-input"]',
    'textarea[aria-labelledby="translation-target-heading"]',
    '[data-testid="translator-target-input"]',
    'section[aria-labelledby="translation-target-heading"] d-textarea',
  ];
  const started = Date.now();
  let last = "";
  let stableHits = 0;
  while (Date.now() - started < 30000) {
    for (const selector of selectors) {
      const node = page.locator(selector).first();
      if ((await node.count()) <= 0) {
        continue;
      }
      const candidate =
        ((await node.inputValue().catch(() => "")) || "").trim() ||
        ((await node.innerText().catch(() => "")) || "").trim() ||
        ((await node.textContent().catch(() => "")) || "").trim();
      if (!candidate) {
        continue;
      }
      if (candidate !== last) {
        last = candidate;
        stableHits = 1;
      } else {
        stableHits += 1;
        if (stableHits >= 2) {
          return candidate;
        }
      }
    }
    await page.waitForTimeout(150);
  }
  return "";
}

async function acceptDeepLConsentIfPresent(page) {
  const consentButtons = [
    'button:has-text("Accept")',
    'button:has-text("Accept all")',
    'button:has-text("I agree")',
    '[id*="onetrust-accept"]',
    '[aria-label*="accept"]',
  ];
  for (const selector of consentButtons) {
    const btn = page.locator(selector).first();
    if (await btn.count()) {
      try {
        await btn.click({ timeout: 2500 });
        await page.waitForTimeout(500);
        return;
      } catch {
        // ignore and continue
      }
    }
  }
}

async function tryTypeDeepLSource(page, text) {
  const selectors = [
    'd-textarea[data-testid="translator-source-input"]',
    'textarea[aria-labelledby="translation-source-heading"]',
    '[data-testid="translator-source-input"]',
    'section[aria-labelledby="translation-source-heading"] textarea',
  ];
  for (const selector of selectors) {
    const node = page.locator(selector).first();
    if ((await node.count()) <= 0) {
      continue;
    }
    try {
      await node.click({ timeout: 2000 });
      await node.fill(text, { timeout: 6000 });
      return true;
    } catch {
      // try next selector
    }
  }
  return false;
}

async function translateViaGoogleHttp(text, from, to) {
  const sl = normalizeGoogleLang(from);
  const tl = normalizeGoogleLang(to);
  const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=${encodeURIComponent(sl)}&tl=${encodeURIComponent(tl)}&dt=t&q=${encodeURIComponent(text)}`;
  const ctx = await playwrightRequest.newContext();
  try {
    const res = await ctx.get(url, { timeout: 30000 });
    if (!res.ok()) {
      process.stderr.write(`google_http status=${res.status()}\n`);
      return null;
    }
    const json = await res.json();
    if (!Array.isArray(json) || !Array.isArray(json[0])) {
      process.stderr.write("google_http unexpected payload shape\n");
      return null;
    }
    const chunks = [];
    for (const part of json[0]) {
      if (Array.isArray(part) && typeof part[0] === "string") {
        chunks.push(part[0]);
      }
    }
    const translatedText = chunks.join("").trim();
    const detected = typeof json[2] === "string" ? json[2].trim() : "";
    if (!translatedText) {
      return null;
    }
    return {
      translatedText,
      detectedSourceLanguage: detected,
    };
  } catch (e) {
    process.stderr.write(`google_http error: ${e}\n`);
    return null;
  } finally {
    await ctx.dispose();
  }
}

async function acceptConsentIfPresent(page) {
  const consentButtons = [
    'button:has-text("I agree")',
    'button:has-text("Accept all")',
    'button:has-text("Accept everything")',
    '[role="button"]:has-text("Accept all")',
  ];
  for (const selector of consentButtons) {
    const btn = page.locator(selector).first();
    if (await btn.count()) {
      try {
        await btn.click({ timeout: 3000 });
        await page.waitForTimeout(700);
        return;
      } catch {
        // ignore and continue with next selector
      }
    }
  }
}

async function translateViaGoogleWeb(text, from, to) {
  const sl = normalizeGoogleLang(from);
  const tl = normalizeGoogleLang(to);
  const encoded = encodeURIComponent(text);
  const url = `https://translate.google.com/?sl=${encodeURIComponent(sl)}&tl=${encodeURIComponent(tl)}&text=${encoded}&op=translate`;
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: "domcontentloaded", timeout: 60000 });
    await acceptConsentIfPresent(page);
    let output = await waitForGoogleOutput(page);
    if (!output) {
      await page.reload({ waitUntil: "domcontentloaded", timeout: 60000 });
      await acceptConsentIfPresent(page);
      output = await waitForGoogleOutput(page);
    }
    if (output && output.trim().toLowerCase() === text.trim().toLowerCase()) {
      process.stderr.write("google_web returned same text as source\n");
    }
    return output;
  } finally {
    await browser.close();
  }
}

function normalizeDeepLLang(code) {
  const raw = String(code || "").trim().toLowerCase();
  if (!raw) return "";
  if (raw === "autodetect" || raw === "auto") return "auto";
  if (raw === "zt") return "zh";
  if (raw === "zh-cn" || raw === "zh-tw") return "zh";
  return raw.split("-")[0];
}

async function translateViaDeepLWeb(text, from, to) {
  const src = normalizeDeepLLang(from);
  const dst = normalizeDeepLLang(to);
  const encoded = encodeURIComponent(text);
  const url = `https://www.deepl.com/translator#${encodeURIComponent(src || "auto")}/${encodeURIComponent(dst)}/${encoded}`;
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: "domcontentloaded", timeout: 60000 });
    await acceptDeepLConsentIfPresent(page);
    let output = await waitForDeepLOutput(page);
    if (!output) {
      const typed = await tryTypeDeepLSource(page, text.trim());
      if (typed) {
        output = await waitForDeepLOutput(page);
      }
    }
    if (!output) {
      await page.reload({ waitUntil: "domcontentloaded", timeout: 60000 });
      await acceptDeepLConsentIfPresent(page);
      output = await waitForDeepLOutput(page);
    }
    if (output && output.trim().toLowerCase() === text.trim().toLowerCase()) {
      process.stderr.write("deepl_web returned same text as source\n");
    }
    return output;
  } finally {
    await browser.close();
  }
}

async function main() {
  reconfigureUtf8();
  let payload;
  try {
    payload = await readStdinJson();
  } catch (e) {
    process.stderr.write(`invalid json: ${e}\n`);
    process.exit(2);
  }
  if (!payload || typeof payload !== "object") {
    process.exit(3);
  }
  const text = payload.text;
  const from = payload.from;
  const to = payload.to;
  const mode = String(payload.mode || "google_web").trim().toLowerCase();

  if (typeof text !== "string" || !text.trim()) {
    process.stderr.write("missing text\n");
    process.exit(3);
  }
  if (typeof from !== "string" || !from.trim()) {
    process.stderr.write("missing from\n");
    process.exit(3);
  }
  if (typeof to !== "string" || !to.trim()) {
    process.stderr.write("missing to\n");
    process.exit(3);
  }
  if (mode !== "google_web" && mode !== "deepl_web") {
    process.stderr.write(`unsupported mode: ${mode}\n`);
    process.exit(3);
  }

  let out = null;
  let detectedSourceLanguage = "";
  try {
    if (mode === "google_web") {
      const httpOut = await translateViaGoogleHttp(
        text.trim(),
        from.trim(),
        to.trim(),
      );
      if (httpOut && httpOut.translatedText) {
        out = httpOut.translatedText;
        detectedSourceLanguage =
          typeof httpOut.detectedSourceLanguage === "string"
            ? httpOut.detectedSourceLanguage.trim()
            : "";
      } else {
        out = await translateViaGoogleWeb(text.trim(), from.trim(), to.trim());
      }
    } else {
      out = await translateViaDeepLWeb(text.trim(), from.trim(), to.trim());
    }
  } catch (e) {
    process.stderr.write(`${mode} path: ${e}\n`);
    process.exit(1);
  }
  if (out == null || String(out).trim() === "") {
    process.stderr.write("empty translation\n");
    process.exit(1);
  }
  if (!detectedSourceLanguage) {
    const normalizedFrom = String(from || "").trim().toLowerCase();
    if (normalizedFrom && normalizedFrom !== "auto" && normalizedFrom !== "autodetect") {
      detectedSourceLanguage = normalizedFrom;
    }
  }
  process.stdout.write(
    JSON.stringify({
      translatedText: String(out).trim(),
      detectedSourceLanguage,
    }),
  );
}

main().catch((e) => {
  process.stderr.write(String(e) + "\n");
  process.exit(1);
});
