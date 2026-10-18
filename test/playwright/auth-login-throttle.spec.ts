import { expect, test, uniqueEmail } from "./fixtures/auth.ts";

// Scenario: 05.Throttle Login 429
// IP klien unik per tes (fixture `clientIp` → X-Forwarded-For), jadi kuota tes ini tidak
// memblokir tes lain yang juga berasal dari 127.0.0.1.

const THROTTLED = "Terlalu banyak percobaan. Coba lagi nanti.";

test("5 gagal lalu percobaan ke-6 → 429 + Retry-After, password benar pun ditolak", async (
  { page, seedUser },
  testInfo,
) => {
  const user = await seedUser({
    email: uniqueEmail(testInfo, "throttle"),
    displayName: "Eko Uji",
    role: "member",
    mustChangePassword: false,
  });
  await page.goto("/login");

  const attempt = async (password: string) => {
    await page.getByLabel("Email").fill(user.email);
    await page.getByLabel("Password").fill(password);
    const responsePromise = page.waitForResponse(
      (r) => new URL(r.url()).pathname === "/login" && r.request().method() === "POST",
    );
    await page.getByRole("button", { name: "Masuk" }).click();
    return responsePromise;
  };

  for (let i = 1; i <= 5; i++) {
    const r = await attempt(`password-salah-${i}`);
    expect(r.status(), `percobaan ${i}`).toBe(422);
  }

  const sixth = await attempt("password-salah-6");
  expect(sixth.status()).toBe(429);
  expect(Number(sixth.headers()["retry-after"])).toBeGreaterThan(0);
  await expect(page.getByRole("alert")).toHaveText(THROTTLED);

  const correct = await attempt(user.password);
  expect(correct.status()).toBe(429);
  await expect(page).toHaveURL(/\/login$/);
  await expect(page.getByRole("alert")).toHaveText(THROTTLED);
});
