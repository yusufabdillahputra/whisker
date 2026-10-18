import path from "node:path";
import dotenv from "dotenv";
import { defineConfig, devices } from "@playwright/test";

dotenv.config({ path: path.resolve(import.meta.dirname, ".e2e.env"), quiet: true });

export default defineConfig({
  testDir: ".",
  testMatch: "*.spec.ts",
  outputDir: "test-results",
  reporter: [["list"], ["html", { open: "never", outputFolder: "playwright-report" }]],
  retries: 0,
  use: {
    baseURL: process.env.E2E_BASE_URL ?? "http://127.0.0.1:8080",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
});
