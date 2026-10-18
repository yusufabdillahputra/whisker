import { expect, test, uniqueEmail } from "./fixtures/auth.ts";

// Scenario: 04.Login Gagal Pesan Generik

const GENERIC = "email atau password salah";

async function submitLogin(page: import("@playwright/test").Page, email: string, password: string) {
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Password").fill(password);
  const responsePromise = page.waitForResponse(
    (r) => new URL(r.url()).pathname === "/login" && r.request().method() === "POST",
  );
  await page.getByRole("button", { name: "Masuk" }).click();
  return responsePromise;
}

test("password salah dan email tak dikenal → pesan generik yang sama", async ({ page, seedUser }, testInfo) => {
  const user = await seedUser({
    email: uniqueEmail(testInfo, "gagal"),
    displayName: "Dewi Uji",
    role: "member",
    mustChangePassword: false,
  });
  await page.goto("/login");

  const wrongPassword = await submitLogin(page, user.email, "password-yang-keliru");
  expect(wrongPassword.status()).toBe(422);
  await expect(page.getByRole("alert")).toHaveText(GENERIC);
  await expect(page).toHaveURL(/\/login$/);
  // Password dikosongkan setelah gagal; email tetap.
  await expect(page.getByLabel("Password")).toHaveValue("");
  await expect(page.getByLabel("Email")).toHaveValue(user.email);

  const unknownEmail = await submitLogin(page, uniqueEmail(testInfo, "tidak-ada"), user.password);
  expect(unknownEmail.status()).toBe(422);
  await expect(page.getByRole("alert")).toHaveText(GENERIC);
  await expect(page).toHaveURL(/\/login$/);
});
