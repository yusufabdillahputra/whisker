import type { Page } from "@playwright/test";
import { expect, loginAs, test, uniqueEmail, useClientIp } from "./fixtures/auth.ts";

// Scenario: 07.Ganti Password Mengeluarkan Sesi Lain
// User KHUSUS tes ini: ganti password menghapus sesi lain milik user yang sama (Review Focus).

async function fillChange(page: Page, current: string, next: string, confirmation = next) {
  await page.getByLabel("Password saat ini", { exact: true }).fill(current);
  await page.getByLabel("Password baru", { exact: true }).fill(next);
  await page.getByLabel("Ulangi password baru", { exact: true }).fill(confirmation);
  const response = page.waitForResponse(
    (r) => new URL(r.url()).pathname === "/account/security/password" && r.request().method() === "PUT",
  );
  await page.getByRole("button", { name: "Ganti password" }).click();
  return response;
}

test("ganti password: error per field; sukses → sesi lain keluar, sesi ini tetap, password lama ditolak", async ({
  page,
  browser,
  seedUser,
  clientIp,
}, testInfo) => {
  const user = await seedUser({
    email: uniqueEmail(testInfo, "sesi-khusus"),
    displayName: "Gita Uji",
    role: "member",
    mustChangePassword: false,
  });
  const newPassword = `${user.password}-sesi-baru`;

  // Context A (page) dan B login sebagai user yang sama.
  const contextB = await browser.newContext({ baseURL: testInfo.project.use.baseURL });
  await useClientIp(contextB, clientIp);
  const pageB = await contextB.newPage();
  await loginAs(page, user);
  await loginAs(pageB, user);
  await expect(pageB.getByRole("heading", { name: "Projects" })).toBeVisible();

  await page.goto("/account/security");
  await expect(page.getByRole("heading", { name: "Keamanan" })).toBeVisible();

  // Error per field — ketiganya sekaligus.
  const invalid = await fillChange(page, "password-saat-ini-keliru", "pendek", "lain-sama-sekali");
  expect(invalid.status()).toBe(422);
  const current = page.getByLabel("Password saat ini", { exact: true });
  const next = page.getByLabel("Password baru", { exact: true });
  const confirmation = page.getByLabel("Ulangi password baru", { exact: true });
  await expect(page.getByText("Password saat ini salah")).toBeVisible();
  await expect(page.getByText("Password minimal 12 karakter")).toBeVisible();
  await expect(page.getByText("Ulangan password tidak cocok")).toBeVisible();
  for (const field of [current, next, confirmation]) await expect(field).toHaveAttribute("aria-invalid", "true");
  await expect(current).toHaveAccessibleDescription(/Password saat ini salah/);
  await expect(page).toHaveURL(/\/account\/security$/);

  // Satu field salah saja → hanya error field itu.
  const mismatch = await fillChange(page, user.password, newPassword, `${newPassword}-x`);
  expect(mismatch.status()).toBe(422);
  await expect(page.getByText("Ulangan password tidak cocok")).toBeVisible();
  await expect(page.getByText("Password saat ini salah")).toHaveCount(0);
  await expect(page.getByText("Password minimal 12 karakter")).toHaveCount(0);

  // Sukses: tetap di Keamanan, toast tampil, form dikosongkan, tanpa error.
  await fillChange(page, user.password, newPassword);
  await expect(page.getByText("Password berhasil diganti.")).toBeVisible();
  await expect(page).toHaveURL(/\/account\/security$/);
  for (const field of [current, next, confirmation]) await expect(field).toHaveValue("");
  await expect(page.getByRole("alert")).toHaveCount(0);

  // Sesi B dihapus → kembali ke /login; sesi A tetap.
  await pageB.goto("/");
  await expect(pageB).toHaveURL(/\/login$/);
  await page.goto("/");
  await expect(page).toHaveURL(/\/$/);
  await expect(page.getByRole("heading", { name: "Projects" })).toBeVisible();

  // Password lama ditolak, password baru diterima (context baru).
  await pageB.goto("/login");
  await pageB.getByLabel("Email").fill(user.email);
  await pageB.getByLabel("Password").fill(user.password);
  await pageB.getByRole("button", { name: "Masuk" }).click();
  await expect(pageB.getByRole("alert")).toHaveText("email atau password salah");
  await expect(pageB).toHaveURL(/\/login$/);
  await loginAs(pageB, { email: user.email, password: newPassword });
  await expect(pageB).toHaveURL(/\/$/);
  await expect(pageB.getByRole("heading", { name: "Projects" })).toBeVisible();

  await contextB.close();
});
