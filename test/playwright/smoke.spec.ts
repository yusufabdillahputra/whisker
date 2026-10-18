import { expect, test } from "@playwright/test";

// Scenario: 01.Smoke Monolith Ter-embed

test("halaman Inertia ter-embed tampil", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Spike Ping" })).toBeVisible();
  await expect(page.getByTestId("message")).not.toBeEmpty();
});

test("POST useForm membawa header X-XSRF-TOKEN dan memperbarui page + URL", async ({ page }) => {
  await page.goto("/");
  await page.getByLabel("Teks").fill("halo");
  const requestPromise = page.waitForRequest(
    (r) => r.url().endsWith("/spike/echo") && r.method() === "POST",
  );
  await page.getByRole("button", { name: "Kirim" }).click();
  const request = await requestPromise;
  expect(await request.headerValue("x-xsrf-token")).toBeTruthy();
  // butir f: POST me-render page (tanpa redirect) -> page + URL diperbarui
  await expect(page.getByTestId("message")).toHaveText("echo: halo");
  await expect(page).toHaveURL(/\/spike\/echo$/);
});

test("error 422 tampil di form", async ({ page }) => {
  await page.goto("/");
  await page.getByLabel("Teks").fill("");
  const responsePromise = page.waitForResponse(
    (r) => r.url().endsWith("/spike/echo") && r.request().method() === "POST",
  );
  await page.getByRole("button", { name: "Kirim" }).click();
  expect((await responsePromise).status()).toBe(422);
  await expect(page.getByRole("alert")).toBeVisible();
});

test("halaman Inertia berstatus 403 dirender client", async ({ page }) => {
  const response = await page.goto("/spike/forbidden");
  expect(response?.status()).toBe(403);
  await expect(page.getByRole("heading", { name: "Spike Ping" })).toBeVisible();
  await expect(page.getByTestId("message")).toHaveText("akses ditolak");
});
