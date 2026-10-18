import path from "node:path";
import type { Page } from "@playwright/test";
import { expect, test } from "./fixtures/auth.ts";

// Scenario: menyusul (D1 sebagian — tampilan /login Terang/Gelap, desktop/mobile).
// Asersi terukur (ruling K11): computed style + boundingBox, tanpa pembanding piksel.
// Screenshot bukti → evidence/ (gitignored; disalin ke vault oleh orchestrator).

const EVIDENCE = path.resolve(import.meta.dirname, "evidence");

const TOKENS = {
  light: { bg: "rgb(244, 245, 247)", surface: "rgb(255, 255, 255)", text: "rgb(20, 22, 27)", primary: "rgb(20, 22, 27)" },
  dark: { bg: "rgb(14, 16, 20)", surface: "rgb(22, 25, 31)", text: "rgb(244, 245, 247)", primary: "rgb(244, 245, 247)" },
} as const;

async function css(page: Page, selector: string, prop: string) {
  return page.locator(selector).first().evaluate((el, p) => getComputedStyle(el).getPropertyValue(p), prop);
}

async function openWithTheme(page: Page, theme: "light" | "dark" | "system") {
  await page.addInitScript((t) => window.localStorage.setItem("whisker-theme", t), theme);
  await page.goto("/login");
  await expect(page.getByRole("heading", { name: "Masuk" })).toBeVisible();
  await page.evaluate(() => document.fonts.ready);
}

for (const theme of ["light", "dark"] as const) {
  test(`/login tampil benar — tema ${theme}`, async ({ page }, testInfo) => {
    const t = TOKENS[theme];
    await openWithTheme(page, theme);

    expect(await page.evaluate(() => document.documentElement.classList.contains("dark"))).toBe(theme === "dark");
    expect(await css(page, "body", "background-color")).toBe(t.bg);
    expect(await css(page, "body", "color")).toBe(t.text);
    expect(await css(page, "[data-testid=login-card]", "background-color")).toBe(t.surface);
    expect(await css(page, "[data-testid=login-card]", "border-top-left-radius")).toBe("14px");
    const submit = page.getByRole("button", { name: "Masuk" });
    expect(await submit.evaluate((el) => getComputedStyle(el).backgroundColor)).toBe(t.primary);

    // Tipografi: judul Sora 600, isi Figtree; font benar-benar termuat (self-host).
    const heading = page.getByRole("heading", { name: "Masuk" });
    expect(await heading.evaluate((el) => getComputedStyle(el).fontFamily)).toMatch(/^"?Sora/);
    expect(await heading.evaluate((el) => getComputedStyle(el).fontWeight)).toBe("600");
    expect(await css(page, "body", "font-family")).toMatch(/^"?Figtree/);
    expect(await page.evaluate(() => document.fonts.check('600 16px "Sora"'))).toBe(true);
    expect(await page.evaluate(() => document.fonts.check('400 16px "Figtree"'))).toBe(true);

    // Logo tampil, di dalam viewport, titik hidung warna aksen.
    const logo = page.getByRole("img", { name: "Whisker" }).first();
    const box = await logo.boundingBox();
    const viewport = page.viewportSize();
    expect(box && viewport).toBeTruthy();
    expect(box!.width).toBeGreaterThan(80);
    expect(box!.x).toBeGreaterThanOrEqual(0);
    expect(box!.x + box!.width).toBeLessThanOrEqual(viewport!.width);
    expect(await page.locator("[data-logo-nose]").first().evaluate((el) => getComputedStyle(el).fill)).toBe(
      "rgb(255, 122, 69)",
    );

    // Tanpa scroll horizontal.
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);

    const card = (await page.getByTestId("login-card").boundingBox())!;
    if (testInfo.project.name.startsWith("mobile")) {
      // Target sentuh ≥ 44 px dan margin tepi 16 px.
      for (const el of [page.getByLabel("Email"), page.getByLabel("Password"), submit]) {
        expect((await el.boundingBox())!.height).toBeGreaterThanOrEqual(44);
      }
      for (const name of ["Terang", "Gelap", "Sistem"]) {
        const b = (await page.getByLabel(name, { exact: true }).boundingBox())!;
        expect(Math.min(b.width, b.height)).toBeGreaterThanOrEqual(44);
      }
      expect(Math.round(card.x)).toBeGreaterThanOrEqual(16);
      expect(await css(page, "input#email", "font-size")).toBe("16px");
    } else {
      // Kartu maks 400 px dan berada di tengah.
      expect(card.width).toBeLessThanOrEqual(400);
      const right = viewport!.width - (card.x + card.width);
      expect(Math.abs(card.x - right)).toBeLessThanOrEqual(2);
    }

    await page.screenshot({
      path: path.join(EVIDENCE, `login-${testInfo.project.name}-${theme}.png`),
      fullPage: true,
    });
  });
}

test("theme toggle: pilihan tersimpan, bertahan setelah reload, Sistem mengikuti perangkat", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light" });
  await page.goto("/login");
  const toggle = page.getByTestId("theme-toggle");
  await expect(toggle).toBeVisible();
  const isDark = () => page.evaluate(() => document.documentElement.classList.contains("dark"));

  await toggle.getByLabel("Gelap", { exact: true }).click();
  expect(await isDark()).toBe(true);
  expect(await page.evaluate(() => localStorage.getItem("whisker-theme"))).toBe("dark");
  await expect(toggle.getByLabel("Gelap", { exact: true })).toHaveAttribute("data-state", "on");

  // Skrip inline di <head> memasang tema sebelum React: cek tepat saat DOMContentLoaded.
  await page.addInitScript(() => {
    document.addEventListener("DOMContentLoaded", () => {
      (window as unknown as { __darkAtDcl: boolean }).__darkAtDcl =
        document.documentElement.classList.contains("dark");
    });
  });
  await page.reload();
  expect(await page.evaluate(() => (window as unknown as { __darkAtDcl: boolean }).__darkAtDcl)).toBe(true);

  await toggle.getByLabel("Sistem", { exact: true }).click();
  expect(await page.evaluate(() => localStorage.getItem("whisker-theme"))).toBe("system");
  expect(await isDark()).toBe(false);
  await page.emulateMedia({ colorScheme: "dark" });
  await expect.poll(isDark).toBe(true);

  await toggle.getByLabel("Terang", { exact: true }).click();
  expect(await isDark()).toBe(false);
});
