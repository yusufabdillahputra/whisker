import type { Page } from "@playwright/test";
import { expect, loginAs, test, uniqueEmail } from "./fixtures/auth.ts";

// Scenario: 06.Ganti Password Wajib Login Pertama
// User seed `mustChangePassword: true` (admin bootstrap dibuktikan tes integrasi Task 06/10 —
// konsekuensi Q8). Ruling K12: rute yang dibuka `/` dan `/account/profile` (Tokens baru Task 15).

async function changePassword(page: Page, current: string, next: string) {
  await page.getByLabel("Password saat ini", { exact: true }).fill(current);
  await page.getByLabel("Password baru", { exact: true }).fill(next);
  await page.getByLabel("Ulangi password baru", { exact: true }).fill(next);
  await page.getByRole("button", { name: "Ganti password" }).click();
}

for (const role of ["admin", "member"] as const) {
  test(`${role} wajib ganti password: dipaksa ke /account/security sampai password diganti`, async ({
    page,
    seedUser,
  }, testInfo) => {
    const user = await seedUser({
      email: uniqueEmail(testInfo, `wajib-${role}`),
      displayName: role === "admin" ? "Admin Uji" : "Member Uji",
      role,
      mustChangePassword: true,
    });

    await loginAs(page, user);
    await expect(page).toHaveURL(/\/account\/security$/);
    await expect(page.getByRole("heading", { name: "Keamanan" })).toBeVisible();
    await expect(page.getByText("Anda wajib mengganti password sebelum melanjutkan.")).toBeVisible();

    // Halaman lain belum boleh dibuka: guard mengembalikan ke Keamanan.
    for (const path of ["/", "/account/profile"]) {
      await page.goto(path);
      await expect(page, `membuka ${path}`).toHaveURL(/\/account\/security$/);
      await expect(page.getByRole("heading", { name: "Keamanan" })).toBeVisible();
    }

    // Error per field tetap dalam alur wajib; reload setelah 422 kembali ke Keamanan.
    await changePassword(page, "password-saat-ini-keliru", `${user.password}-baru-${role}`);
    await expect(page.getByText("Password saat ini salah")).toBeVisible();
    await page.reload();
    await expect(page).toHaveURL(/\/account\/security$/);
    await expect(page.getByRole("heading", { name: "Keamanan" })).toBeVisible();

    await changePassword(page, user.password, `${user.password}-baru-${role}`);
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByRole("heading", { name: "Projects" })).toBeVisible();
    await expect(page.getByText("Password berhasil diganti.")).toBeVisible();

    // Tanda wajib ganti sudah hilang: `/` tetap terbuka, Keamanan tanpa pemberitahuan wajib.
    await page.goto("/");
    await expect(page).toHaveURL(/\/$/);
    await page.goto("/account/security");
    await expect(page.getByRole("heading", { name: "Keamanan" })).toBeVisible();
    await expect(page.getByText("Anda wajib mengganti password sebelum melanjutkan.")).toHaveCount(0);
  });
}
