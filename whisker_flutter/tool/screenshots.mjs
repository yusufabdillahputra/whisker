// Screenshot aplikasi demo (light/dark × ponsel/desktop).
// Pakai: flutter build web --dart-define=WHISKER_DEMO=true --no-web-resources-cdn
//        NODE_PATH=$(npm root -g) node tool/screenshots.mjs [port]
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';
import { createRequire } from 'node:module';

// `require` menghormati NODE_PATH (Playwright terpasang global).
const { chromium } = createRequire(import.meta.url)('playwright');

const root = new URL('../build/web/', import.meta.url).pathname;
const out = new URL('../../docs/screenshots/', import.meta.url).pathname;
const port = Number(process.argv[2] ?? 8099);
const types = {
  '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png', '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf', '.otf': 'font/otf',
};

const server = createServer(async (req, res) => {
  const path = normalize(decodeURIComponent(new URL(req.url, 'http://x').pathname));
  try {
    const file = join(root, path.endsWith('/') ? `${path}index.html` : path);
    if (!file.startsWith(root)) throw new Error('luar root');
    res.writeHead(200, { 'content-type': types[extname(file)] ?? 'application/octet-stream' });
    res.end(await readFile(file));
  } catch {
    res.writeHead(404).end();
  }
}).listen(port);

const doc = encodeURIComponent('PKM/Catatan/Kucing Calico.md');
const shots = [
  { name: 'desktop-light', scheme: 'light', viewport: { width: 1440, height: 900 } },
  { name: 'desktop-dark', scheme: 'dark', viewport: { width: 1440, height: 900 } },
  { name: 'ponsel-light', scheme: 'light', viewport: { width: 390, height: 844 }, mobile: true },
  { name: 'ponsel-dark', scheme: 'dark', viewport: { width: 390, height: 844 }, mobile: true },
];

const browser = await chromium.launch();
try {
  for (const s of shots) {
    const page = await browser.newPage({
      viewport: s.viewport,
      colorScheme: s.scheme,
      deviceScaleFactor: 2,
      isMobile: !!s.mobile,
      hasTouch: !!s.mobile,
    });
    await page.goto(`http://localhost:${port}/#/hub/1?doc=${doc}`);
    await page.waitForSelector('flt-glass-pane, flutter-view', { timeout: 60000 });
    await page.waitForTimeout(4000);
    await page.screenshot({ path: `${out}${s.name}.png` });
    console.log(`OK ${s.name}`);
    await page.close();
  }
} finally {
  await browser.close();
  server.close();
}
