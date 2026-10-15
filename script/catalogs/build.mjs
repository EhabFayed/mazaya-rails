// Prints every category's /catalog/:category/print page to catalog-<slug>.pdf (A4).
//
//   cd script/catalogs && npm install
//   node build.mjs https://new-mazaya.mila-knight.com ../../tmp/catalogs     # Arabic (attached on the site)
//   LOCALE=en node build.mjs https://new-mazaya.mila-knight.com ../../tmp/catalogs-en
//
// Then: bin/rails catalogs:attach DIR=tmp/catalogs (see lib/tasks/catalogs.rake).
// Needs a local Chrome/Chromium: CHROME=/path/to/chrome (default /usr/bin/google-chrome).
import puppeteer from "puppeteer-core";
import fs from "node:fs";

const [base = "http://localhost:3000", outDir = "../../tmp/catalogs"] = process.argv.slice(2);
const prefix = process.env.LOCALE === "en" ? "/en" : "";
fs.mkdirSync(outDir, { recursive: true });

// Category slugs from the sitemap: /products/<slug> with nothing after it.
const sitemap = await (await fetch(`${base}/sitemap.xml`)).text();
const slugs = [...new Set([...sitemap.matchAll(/<loc>[^<]*?\/products\/([a-z0-9-]+)<\/loc>/g)].map((m) => m[1]))];
if (!slugs.length) throw new Error(`no categories found in ${base}/sitemap.xml`);

const browser = await puppeteer.launch({ executablePath: process.env.CHROME || "/usr/bin/google-chrome", headless: true, args: ["--no-sandbox"] });
let failed = 0;
for (const slug of slugs) {
  const page = await browser.newPage();
  const res = await page.goto(`${base}${prefix}/catalog/${slug}/print`, { waitUntil: "networkidle0", timeout: 180000 });
  if (res.status() === 404) { console.log(`skip ${slug}: no products`); await page.close(); continue; }
  if (!res.ok()) { console.log(`FAIL ${slug}: HTTP ${res.status()}`); failed++; await page.close(); continue; }
  // Wait for fonts + images, then let the page's fit script settle before printing.
  await page.evaluate(async () => {
    await document.fonts.ready;
    await Promise.all([...document.images].map((i) => (i.complete ? 0 : new Promise((r) => { i.onload = i.onerror = r; }))));
  });
  await new Promise((r) => setTimeout(r, 300));
  const check = await page.evaluate(() => ({
    sheets: document.querySelectorAll(".sheet").length,
    broken: [...document.images].filter((i) => !i.naturalWidth).length,
    missing: (document.body.innerText.match(/translation missing/gi) || []).length,
  }));
  const file = `${outDir}/catalog-${slug}.pdf`;
  await page.pdf({ path: file, format: "A4", printBackground: true, preferCSSPageSize: true, margin: { top: 0, right: 0, bottom: 0, left: 0 } });
  const mb = (fs.statSync(file).size / 1048576).toFixed(1);
  const bad = check.broken || check.missing;
  if (bad) failed++;
  console.log(`${bad ? "WARN" : "ok  "} ${slug}: ${check.sheets} pages, ${mb} MB, broken images ${check.broken}, missing text ${check.missing} → ${file}`);
  await page.close();
}
await browser.close();
process.exit(failed ? 1 : 0);
