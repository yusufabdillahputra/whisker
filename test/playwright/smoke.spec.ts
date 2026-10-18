import { expect, test } from "./fixtures/auth.ts";

// Scenario: 01.Smoke Monolith Ter-embed

test("/login tampil dari aset ter-embed", async ({ page }) => {
  const assets: string[] = [];
  page.on("response", (r) => {
    if (new URL(r.url()).pathname.startsWith("/build/")) assets.push(`${r.status()} ${r.url()}`);
  });
  const response = await page.goto("/login");
  expect(response?.status()).toBe(200);
  await expect(page.getByRole("heading", { name: "Masuk" })).toBeVisible();
  await expect(page.getByRole("img", { name: "Whisker" }).first()).toBeVisible();
  expect(assets.length).toBeGreaterThan(0);
  expect(assets.every((a) => a.startsWith("200 "))).toBe(true);
});

test("POST Inertia membawa header X-XSRF-TOKEN yang sama dengan cookie", async ({ page }) => {
  await page.goto("/login");
  await page.getByLabel("Email").fill("tidak-ada@example.test");
  await page.getByLabel("Password").fill("password-salah-sekali");
  const requestPromise = page.waitForRequest(
    (r) => new URL(r.url()).pathname === "/login" && r.method() === "POST",
  );
  await page.getByRole("button", { name: "Masuk" }).click();
  const request = await requestPromise;
  const header = await request.headerValue("x-xsrf-token");
  const cookie = (await page.context().cookies()).find((c) => c.name === "XSRF-TOKEN");
  expect(header).toBeTruthy();
  expect(header).toBe(decodeURIComponent(cookie?.value ?? ""));
  await expect(page.getByRole("alert")).toBeVisible();
});

test("path tak dikenal → 404 Errors/NotFound dirender client", async ({ page }) => {
  const response = await page.goto("/tidak-ada-di-sini");
  expect(response?.status()).toBe(404);
  await expect(page.getByRole("heading", { name: "Halaman tidak ditemukan" })).toBeVisible();
});

test("rute spike sudah dihapus", async ({ page }) => {
  for (const path of ["/spike/forbidden", "/spike/echo"]) {
    const response = await page.goto(path);
    expect(response?.status(), path).toBe(404);
  }
});
