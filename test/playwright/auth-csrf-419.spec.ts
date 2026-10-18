import { expect, test, uniqueEmail } from "./fixtures/auth.ts";

// Scenario: menyusul (AC dari review Task 10 — penanganan 419 CSRF).
// Cookie XSRF-TOKEN dirusak → server menjawab 419 (dan menerbitkan cookie baru) → frontend
// mengulang POST tepat sekali tanpa modal "CSRF token mismatch".

test("419 CSRF: satu kali coba ulang, tanpa modal, login tetap berhasil", async ({ page, seedUser }, testInfo) => {
  const user = await seedUser({
    email: uniqueEmail(testInfo, "csrf"),
    displayName: "Fajar Uji",
    role: "member",
    mustChangePassword: false,
  });
  await page.goto("/login");

  const url = new URL(page.url());
  await page.context().addCookies([
    { name: "XSRF-TOKEN", value: "rusak.tidak-sah", domain: url.hostname, path: "/" },
  ]);

  const statuses: number[] = [];
  page.on("response", (r) => {
    if (new URL(r.url()).pathname === "/login" && r.request().method() === "POST") statuses.push(r.status());
  });

  await page.getByLabel("Email").fill(user.email);
  await page.getByLabel("Password").fill(user.password);
  await page.getByRole("button", { name: "Masuk" }).click();

  await expect(page).toHaveURL(/\/$/);
  await expect(page.getByRole("heading", { name: "Projects" })).toBeVisible();
  expect(statuses[0]).toBe(419);
  expect(statuses).toHaveLength(2);
  expect(statuses[1]).not.toBe(419);
  await expect(page.locator("#inertia-error-dialog")).toHaveCount(0);
  await expect(page.getByText("CSRF token mismatch")).toHaveCount(0);
});
