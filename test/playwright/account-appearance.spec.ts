import path from "node:path";
import type { Page } from "@playwright/test";
import { expect, loginAs, test, uniqueEmail } from "./fixtures/auth.ts";

// Scenario: menyusul (tampilan Akun › Keamanan + menu akun, Terang/Gelap, desktop/mobile).
// Asersi terukur (ruling K11): computed style + boundingBox, tanpa pembanding piksel.
// Screenshot bukti → evidence/ (gitignored; disalin ke vault oleh orchestrator).

const EVIDENCE = path.resolve(import.meta.dirname, "evidence");

const TOKENS = {
  light: { bg: "rgb(244, 245, 247)", surface: "rgb(255, 255, 255)", link: "rgb(180, 71, 26)" },
  dark: { bg: "rgb(14, 16, 20)", surface: "rgb(22, 25, 31)", link: "rgb(253, 186, 116)" },
} as const;

const noHorizontalScroll = (page: Page) =>
  page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth);

for (const theme of ["light", "dark"] as const) {
  test(`Akun › Keamanan + menu akun tampil benar — tema ${theme}`, async ({ page, seedUser }, testInfo) => {
    const t = TOKENS[theme];
    const mobile = testInfo.project.name.startsWith("mobile");
    const user = await seedUser({
      email: uniqueEmail(testInfo, `tampilan-${theme}`),
      displayName: "Hana Uji",
      role: "admin",
      mustChangePassword: false,
    });
    await page.addInitScript((v) => window.localStorage.setItem("whisker-theme", v), theme);
    await loginAs(page, user);
    await page.goto("/account/security");
    await expect(page.getByRole("heading", { name: "Keamanan" })).toBeVisible();
    await page.evaluate(() => document.fonts.ready);

    expect(await page.evaluate(() => document.documentElement.classList.contains("dark"))).toBe(theme === "dark");
    expect(await page.locator("body").evaluate((el) => getComputedStyle(el).backgroundColor)).toBe(t.bg);
    // Token `--link` per tema (Confirmation 10: override `.dark` lolos AA di #0E1014).
    expect(
      await page.evaluate(() => getComputedStyle(document.documentElement).getPropertyValue("--link").trim()),
    ).toBe(theme === "dark" ? "#fdba74" : "#b4471a");

    // Header h-14: logo, theme toggle, tombol menu akun.
    const header = page.getByRole("banner");
    expect(Math.round((await header.boundingBox())!.height)).toBeGreaterThanOrEqual(56);
    expect(await header.evaluate((el) => getComputedStyle(el).backgroundColor)).toBe(t.surface);
    await expect(header.getByTestId("theme-toggle")).toBeVisible();
    const accountButton = header.getByRole("button", { name: "Menu akun Hana Uji" });
    expect(Math.round((await accountButton.boundingBox())!.height)).toBe(44);

    // Sub-menu Akun: admin melihat 4 item; Keamanan aktif.
    const nav = page.getByRole("navigation", { name: "Menu akun" });
    await expect(nav.getByRole("link")).toHaveText(["Profil", "Keamanan", "Tokens", "Admin Users"]);
    await expect(nav.getByRole("link", { name: "Keamanan" })).toHaveAttribute("aria-current", "page");

    // Kartu Keamanan: surface, radius 14.
    const card = page.getByTestId("security-card");
    expect(await card.evaluate((el) => getComputedStyle(el).backgroundColor)).toBe(t.surface);
    expect(await card.evaluate((el) => getComputedStyle(el).borderTopLeftRadius)).toBe("14px");

    // Ring fokus DESIGN.md §5 (keyboard).
    const current = page.getByLabel("Password saat ini", { exact: true });
    await current.focus();
    await page.keyboard.press("Tab");
    await page.keyboard.press("Shift+Tab");
    const ring = await current.evaluate((el) => {
      const s = getComputedStyle(el);
      return `${s.outlineStyle} ${s.outlineWidth} ${s.outlineColor} ${s.outlineOffset}`;
    });
    expect(ring).toBe("solid 2px rgb(255, 122, 69) 2px");

    if (mobile) {
      // Target sentuh ≥ 44 px; sub-menu = tab horizontal h-11.
      const targets = [
        ...(await nav.getByRole("link").all()),
        current,
        page.getByRole("button", { name: "Ganti password" }),
      ];
      for (const el of targets) expect(Math.round((await el.boundingBox())!.height)).toBeGreaterThanOrEqual(44);
      const links = await nav.getByRole("link").all();
      const [first, second] = [await links[0].boundingBox(), await links[1].boundingBox()];
      expect(Math.abs(first!.y - second!.y)).toBeLessThanOrEqual(1);
      expect(await page.locator("input#currentPassword").evaluate((el) => getComputedStyle(el).fontSize)).toBe("16px");
    }
    expect(await noHorizontalScroll(page)).toBe(true);

    await page.screenshot({ path: path.join(EVIDENCE, `account-security-${testInfo.project.name}-${theme}.png`), fullPage: true });

    // Menu akun: identitas, item, lisensi pihak ketiga, Logout.
    await accountButton.click();
    const menu = page.getByRole("menu");
    await expect(menu).toBeVisible();
    await expect(menu.getByText("Hana Uji")).toBeVisible();
    await expect(menu.getByRole("menuitem")).toHaveText([
      "Tokens",
      "Account",
      "Admin Users",
      "Lisensi pihak ketiga",
      "Logout",
    ]);
    await expect(menu.getByRole("menuitem", { name: "Lisensi pihak ketiga" })).toHaveAttribute(
      "href",
      "/third-party-notices.txt",
    );
    expect(await menu.evaluate((el) => getComputedStyle(el).backgroundColor)).toBe(t.surface);
    const menuBox = (await menu.boundingBox())!;
    expect(Math.round(menuBox.width)).toBe(224);
    expect(menuBox.x + menuBox.width).toBeLessThanOrEqual(page.viewportSize()!.width);
    for (const item of await menu.getByRole("menuitem").all()) {
      // Dibulatkan: DPR 2,625 (Pixel 7) memberi 43,99999 px untuk 44 px CSS.
      expect(Math.round((await item.boundingBox())!.height)).toBeGreaterThanOrEqual(mobile ? 44 : 40);
    }
    await page.screenshot({ path: path.join(EVIDENCE, `account-menu-${testInfo.project.name}-${theme}.png`) });

    // Berkas notice MIT tersaji (Task 12).
    const notices = await page.request.get("/third-party-notices.txt");
    expect(notices.status()).toBe(200);

    // Logout dari menu → /login.
    await menu.getByRole("menuitem", { name: "Logout" }).click();
    await expect(page).toHaveURL(/\/login$/);
  });
}

test("menu akun member: tanpa Admin Users; sub-menu 3 item", async ({ page, seedUser }, testInfo) => {
  const user = await seedUser({
    email: uniqueEmail(testInfo, "menu-member"),
    displayName: "Indra Uji",
    role: "member",
    mustChangePassword: false,
  });
  await loginAs(page, user);
  await page.goto("/account/security");
  await expect(page.getByRole("navigation", { name: "Menu akun" }).getByRole("link")).toHaveText([
    "Profil",
    "Keamanan",
    "Tokens",
  ]);
  await page.getByRole("button", { name: "Menu akun Indra Uji" }).click();
  await expect(page.getByRole("menu").getByRole("menuitem")).toHaveText([
    "Tokens",
    "Account",
    "Lisensi pihak ketiga",
    "Logout",
  ]);
});
