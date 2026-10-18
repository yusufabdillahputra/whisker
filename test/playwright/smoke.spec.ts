import { expect, test } from "@playwright/test";

// Scenario: 01.Smoke Monolith Ter-embed

test("halaman Inertia ter-embed tampil", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Spike Ping" })).toBeVisible();
  await expect(page.getByTestId("message")).not.toBeEmpty();
});

test("POST useForm membawa header X-XSRF-TOKEN", async ({ page }) => {
  await page.goto("/");
  await page.getByLabel("Teks").fill("halo");
  const requestPromise = page.waitForRequest(
    (r) => r.url().endsWith("/spike/echo") && r.method() === "POST",
  );
  await page.getByRole("button", { name: "Kirim" }).click();
  const request = await requestPromise;
  expect(await request.headerValue("x-xsrf-token")).toBeTruthy();
});

test("error 422 tampil di form", async ({ page }) => {
  await page.goto("/");
  await page.getByLabel("Teks").fill("");
  await page.getByRole("button", { name: "Kirim" }).click();
  await expect(page.getByRole("alert")).toBeVisible();
});
