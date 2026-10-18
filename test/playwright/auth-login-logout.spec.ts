import { expect, loginAs, test, uniqueEmail } from "./fixtures/auth.ts";

// Scenario: 03.Login dan Logout

test("login sukses ke Projects lalu logout kembali ke /login", async ({ page, seedUser }, testInfo) => {
  const user = await seedUser({
    email: uniqueEmail(testInfo, "login"),
    displayName: "Ani Uji",
    role: "member",
    mustChangePassword: false,
  });

  await page.goto("/login");
  await page.getByLabel("Email").fill(user.email);
  await page.getByLabel("Password").fill(user.password);
  await page.getByRole("button", { name: "Masuk" }).click();

  await expect(page).toHaveURL(/\/$/);
  await expect(page.getByRole("heading", { name: "Projects" })).toBeVisible();
  await expect(page.getByText("Ani Uji")).toBeVisible();
  expect((await page.context().cookies()).some((c) => c.name === "whisker_session")).toBe(true);
  // Header stub muat di lebar ponsel (tanpa scroll horizontal).
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);

  await page.getByRole("button", { name: "Logout" }).click();
  await expect(page).toHaveURL(/\/login$/);
  await expect(page.getByRole("heading", { name: "Masuk" })).toBeVisible();

  // Sesi sudah tidak berlaku: halaman terlindungi kembali ke /login.
  await page.goto("/");
  await expect(page).toHaveURL(/\/login$/);
});

test("user wajib ganti password diarahkan ke /account/security", async ({ page, seedUser }, testInfo) => {
  const user = await seedUser({
    email: uniqueEmail(testInfo, "wajib-ganti"),
    displayName: "Budi Uji",
    role: "member",
    mustChangePassword: true,
  });
  await loginAs(page, user);
  await expect(page).toHaveURL(/\/account\/security$/);
});

test("sudah login lalu membuka /login diarahkan ke /", async ({ page, seedUser }, testInfo) => {
  const user = await seedUser({
    email: uniqueEmail(testInfo, "sudah-login"),
    displayName: "Citra Uji",
    role: "admin",
    mustChangePassword: false,
  });
  await loginAs(page, user);
  await page.goto("/login");
  await expect(page).toHaveURL(/\/$/);
  await expect(page.getByRole("heading", { name: "Projects" })).toBeVisible();
});
