import path from "node:path";
import { defineConfig, devices } from "@playwright/test";
import { baseUrl } from "./fixtures/env.ts";

const base = new URL(baseUrl);
const binary = path.resolve(import.meta.dirname, "../../target/release/whisker");

// Admin bootstrap (ruling K5): binary gagal start di DB kosong tanpa env ini. E2E sendiri memakai
// user seed, bukan admin bootstrap.
const adminEmail = process.env.E2E_ADMIN_EMAIL ?? process.env.WHISKER_ADMIN_EMAIL;
const adminPassword = process.env.E2E_ADMIN_PASSWORD ?? process.env.WHISKER_ADMIN_PASSWORD;

export default defineConfig({
  testDir: ".",
  testMatch: "*.spec.ts",
  outputDir: "test-results",
  globalSetup: "./global-setup.ts",
  reporter: [["list"], ["html", { open: "never", outputFolder: "playwright-report" }]],
  retries: 0,
  use: {
    baseURL: baseUrl,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  projects: [
    { name: "desktop-chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "mobile-chromium", use: { ...devices["Pixel 7"] } },
  ],
  // Binary release ber-embed (`cargo build --release -p whisker`, frontend sudah di-build).
  webServer: {
    command: `"${binary}"`,
    url: new URL("/health", base).href,
    reuseExistingServer: !process.env.CI,
    timeout: 60_000,
    stdout: "pipe",
    stderr: "pipe",
    env: {
      DATABASE_URL: process.env.E2E_DATABASE_URL ?? "",
      WHISKER_HTTP_ADDR: base.host,
      WHISKER_PUBLIC_URL: base.origin,
      WHISKER_COOKIE_SECURE: "false",
      // XFF dari runner (loopback) dipercaya → IP klien unik per tes (fixture `clientIp`).
      WHISKER_TRUSTED_PROXIES: "127.0.0.1/32,::1/128",
      ...(adminEmail && adminPassword
        ? { WHISKER_ADMIN_EMAIL: adminEmail, WHISKER_ADMIN_PASSWORD: adminPassword }
        : {}),
    },
  },
});
