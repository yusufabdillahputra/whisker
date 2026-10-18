// Fixture Playwright: seed user uji, login, IP klien per tes, header XSRF.
import { type BrowserContext, type Page, test as base, expect } from "@playwright/test";
import type pg from "pg";
import {
  type SeedUserInput,
  type SeededUser,
  type TestIdentity,
  createPool,
  seedUserWith,
  testKey,
  uniqueEmail,
} from "./db.ts";
import { databaseUrl, userPassword } from "./env.ts";

export { expect, uniqueEmail };
export type { SeededUser };

/** IP klien deterministik per tes + project + retry, dari blok benchmarking 198.18.0.0/15. */
export function ipForTest(testInfo: TestIdentity): string {
  const h = Buffer.from(testKey(testInfo, 8), "hex");
  return `198.${18 + (h[0] & 1)}.${h[1]}.${1 + (h[2] % 254)}`;
}

/**
 * Semua request context lewat `X-Forwarded-For: ip`. Monolith E2E memercayai proxy loopback
 * (`WHISKER_TRUSTED_PROXIES`), jadi kuota throttle per IP terpisah per tes.
 */
export async function useClientIp(context: BrowserContext, ip: string): Promise<void> {
  await context.setExtraHTTPHeaders({ "X-Forwarded-For": ip });
}

/** Header CSRF untuk `page.request.post` (nilai cookie `XSRF-TOKEN`). */
export async function xsrfHeaders(page: Page): Promise<Record<string, string>> {
  const cookie = (await page.context().cookies()).find((c) => c.name === "XSRF-TOKEN");
  if (!cookie) throw new Error("cookie XSRF-TOKEN belum ada — buka satu halaman dulu");
  return { "X-XSRF-TOKEN": decodeURIComponent(cookie.value) };
}

/** Login lewat form `/login` dan tunggu sampai keluar dari halaman login. */
export async function loginAs(page: Page, user: Pick<SeededUser, "email" | "password">): Promise<void> {
  await page.goto("/login");
  await page.getByLabel("Email").fill(user.email);
  await page.getByLabel("Password").fill(user.password);
  await page.getByRole("button", { name: "Masuk" }).click();
  await page.waitForURL((url) => url.pathname !== "/login");
}

type TestFixtures = {
  /** IP klien tes ini (otomatis dipasang di setiap tes). */
  clientIp: string;
  seedUser: (input: SeedUserInput) => Promise<SeededUser>;
};

type WorkerFixtures = { db: pg.Pool };

export const test = base.extend<TestFixtures, WorkerFixtures>({
  db: [
    async ({}, use) => {
      const pool = createPool(databaseUrl());
      await use(pool);
      await pool.end();
    },
    { scope: "worker" },
  ],
  clientIp: [
    async ({ context }, use, testInfo) => {
      const ip = ipForTest(testInfo);
      await useClientIp(context, ip);
      await use(ip);
    },
    { auto: true },
  ],
  seedUser: async ({ db }, use) => {
    const password = userPassword();
    await use((input) => seedUserWith(db, password, input));
  },
});
