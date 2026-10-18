import path from "node:path";
import { expect, loginAs, test, uniqueEmail, xsrfHeaders } from "./fixtures/auth.ts";

// Scenario: [[Test/Scenario/08.Profil Avatar dan Nama Tampilan]]
// Bukti visual → evidence/ (gitignored; disalin ke vault oleh orchestrator).

const EVIDENCE = path.resolve(import.meta.dirname, "evidence");
const picks = (page: import("@playwright/test").Page) => page.getByRole("button", { name: /^Avatar / });

test("Profil: 40 avatar tampil, filter Hewan = 8, pilih + simpan bertahan setelah reload", async ({
  page,
  seedUser,
}, testInfo) => {
  const user = await seedUser({
    email: uniqueEmail(testInfo, "profil"),
    displayName: "Hana Uji",
    role: "member",
    mustChangePassword: false,
  });
  await loginAs(page, user);
  await page.goto("/account/profile");
  await expect(page.getByRole("heading", { name: "Profil", level: 2 })).toBeVisible();
  await expect(page.getByRole("navigation", { name: "Menu akun" }).getByRole("link", { name: "Profil" })).toHaveAttribute(
    "aria-current",
    "page",
  );

  // 40 pilihan; seluruh SVG benar-benar termuat dan punya dimensi (bukan gambar rusak).
  await expect(picks(page)).toHaveCount(40);
  const broken = await page.evaluate(async () => {
    const srcs = [...document.querySelectorAll<HTMLImageElement>('[aria-label="Pilihan avatar"] img')].map((i) => i.src);
    const bad: string[] = [];
    await Promise.all(
      srcs.map(async (src) => {
        const img = new Image();
        img.src = src;
        try {
          await img.decode();
          if (img.naturalWidth === 0) bad.push(src);
        } catch {
          bad.push(src);
        }
      }),
    );
    return { total: srcs.length, bad };
  });
  expect(broken).toEqual({ total: 40, bad: [] });

  // Email read-only + keterangan.
  const email = page.getByLabel("Email", { exact: true });
  await expect(email).toHaveAttribute("readonly", "");
  await expect(email).toHaveValue(user.email);
  await expect(page.getByText("diubah oleh admin")).toBeVisible();

  // Filter.
  const hewan = page.getByRole("button", { name: "Hewan", exact: true });
  await hewan.click();
  await expect(hewan).toHaveAttribute("aria-pressed", "true");
  await expect(picks(page)).toHaveCount(8);
  await page.getByRole("button", { name: "Perempuan", exact: true }).click();
  await expect(picks(page)).toHaveCount(16);
  await page.getByRole("button", { name: "Laki-laki", exact: true }).click();
  await expect(picks(page)).toHaveCount(16);
  await hewan.click();

  // Pilih animal-03 + ubah nama → simpan.
  await page.getByRole("button", { name: "Avatar animal-03" }).click();
  await expect(page.getByRole("button", { name: "Avatar animal-03" })).toHaveAttribute("aria-pressed", "true");
  await page.getByLabel("Nama tampilan").fill("Hana Baru");
  await page.getByRole("button", { name: "Simpan" }).click();
  await expect(page.getByText("Profil disimpan.")).toBeVisible();

  // Header (AccountMenu) ikut berubah, juga setelah reload.
  for (const reload of [false, true]) {
    if (reload) await page.reload();
    const trigger = page.getByRole("banner").getByRole("button", { name: "Menu akun Hana Baru" });
    await expect(trigger).toBeVisible();
    await expect(trigger.locator('img[src="/avatars/animal-03.svg"]')).toBeVisible();
    await expect(page.getByLabel("Nama tampilan")).toHaveValue("Hana Baru");
    await page.getByRole("button", { name: "Hewan", exact: true }).click();
    await expect(page.getByRole("button", { name: "Avatar animal-03" })).toHaveAttribute("aria-pressed", "true");
    await expect(page.locator('main img[src="/avatars/animal-03.svg"]').first()).toBeVisible();
  }
});

test("Profil: avatarKey di luar allowlist → 422; nama kosong → pesan per field", async ({ page, seedUser }, testInfo) => {
  const user = await seedUser({
    email: uniqueEmail(testInfo, "profil-422"),
    displayName: "Indra Uji",
    role: "member",
    mustChangePassword: false,
  });
  await loginAs(page, user);
  await page.goto("/account/profile");

  const res = await page.request.put("/account/profile", {
    headers: { ...(await xsrfHeaders(page)), "X-Inertia": "true", "X-Inertia-Version": "x" },
    data: { displayName: "Indra Uji", avatarKey: "evil" },
  });
  expect(res.status()).toBe(422);

  // Nama kosong lewat UI → error per field, terhubung aria-describedby.
  await page.getByLabel("Nama tampilan").fill("   ");
  await page.getByRole("button", { name: "Simpan" }).click();
  const input = page.getByLabel("Nama tampilan");
  await expect(page.getByRole("alert").filter({ hasText: "Nama tampilan wajib diisi" })).toBeVisible();
  await expect(input).toHaveAttribute("aria-invalid", "true");
  await expect(input).toHaveAttribute("aria-describedby", "displayName-error");
});

for (const theme of ["light", "dark"] as const) {
  test(`Profil: tampilan ${theme} (bukti visual)`, async ({ page, seedUser }, testInfo) => {
    const mobile = testInfo.project.name.startsWith("mobile");
    const user = await seedUser({
      email: uniqueEmail(testInfo, `profil-${theme}`),
      displayName: "Hana Uji",
      role: "admin",
      mustChangePassword: false,
    });
    await page.addInitScript((v) => window.localStorage.setItem("whisker-theme", v), theme);
    await loginAs(page, user);
    await page.goto("/account/profile");
    await expect(picks(page)).toHaveCount(40);
    await page.evaluate(() => document.fonts.ready);
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
    const first = picks(page).first();
    expect(Math.round((await first.boundingBox())!.height)).toBeGreaterThanOrEqual(mobile ? 44 : 40);
    await page.getByRole("button", { name: "Avatar human-f-02" }).click();
    await page.screenshot({ path: path.join(EVIDENCE, `account-profile-${testInfo.project.name}-${theme}.png`), fullPage: true });
  });
}
