import path from "node:path";
import { request } from "@playwright/test";
import { expect, loginAs, test, uniqueEmail } from "./fixtures/auth.ts";

// Scenario: 09.Buat Salin Revoke Token
// Token polos hanya ada di memori tes; tidak pernah dicetak, di-screenshot, atau dinamai ke berkas.

const MCP_HEADERS = {
  Accept: "application/json, text/event-stream",
  "Content-Type": "application/json",
};

async function mcpStatus(baseURL: string, bearer: string): Promise<number> {
  // Context tanpa cookie sesi: hanya Bearer yang menentukan.
  const ctx = await request.newContext({ baseURL });
  const r = await ctx.post("/mcp", {
    headers: { ...MCP_HEADERS, Authorization: `Bearer ${bearer}` },
    data: { jsonrpc: "2.0", id: 1, method: "tools/list", params: {} },
  });
  const status = r.status();
  await ctx.dispose();
  return status;
}

test("buat token → tampil sekali + Salin; reload menghilangkan; daftar; revoke → /mcp 401", async ({
  page,
  context,
  seedUser,
  baseURL,
}, testInfo) => {
  const user = await seedUser({
    email: uniqueEmail(testInfo, "tokens"),
    displayName: "Tia Token",
    role: "member",
    mustChangePassword: false,
  });
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
  await loginAs(page, user);

  await page.goto("/account/tokens");
  await expect(page.getByRole("heading", { name: "Tokens" })).toBeVisible();
  await expect(page.getByRole("status").filter({ hasText: "whk_" })).toHaveCount(0);

  // Nama kosong → error per field.
  const nameInput = page.getByLabel("Nama token");
  await page.getByRole("button", { name: "Buat token" }).click();
  await expect(page.getByText("Nama token wajib diisi")).toBeVisible();
  await expect(nameInput).toHaveAttribute("aria-invalid", "true");
  await expect(nameInput).toHaveAccessibleDescription(/Nama token wajib diisi/);

  // Buat.
  await nameInput.fill("Laptop E2E");
  const created = page.waitForResponse(
    (r) => new URL(r.url()).pathname === "/account/tokens" && r.request().method() === "POST",
  );
  await page.getByRole("button", { name: "Buat token" }).click();
  expect((await created).status()).toBe(200);

  const tokenBox = page.getByTestId("created-token");
  await expect(tokenBox).toBeVisible();
  const plain = (await tokenBox.getByTestId("created-token-value").innerText()).trim();
  expect(plain).toMatch(/^whk_[A-Za-z0-9_-]+$/);
  expect(plain).toHaveLength(53);
  await expect(page.getByText(/tidak akan ditampilkan lagi/i)).toBeVisible();

  // Salin → clipboard = token + toast.
  await tokenBox.getByRole("button", { name: "Salin" }).click();
  await expect(page.getByText("Token disalin")).toBeVisible();
  expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(plain);

  // Token berfungsi di /mcp.
  expect(await mcpStatus(baseURL!, plain)).toBe(200);

  // Daftar: kolom + baris.
  const row = page.getByRole("row", { name: /Laptop E2E/ });
  await expect(row).toBeVisible();
  await expect(page.getByRole("columnheader", { name: "Nama" })).toBeVisible();
  await expect(page.getByRole("columnheader", { name: "Prefix" })).toBeVisible();
  await expect(page.getByRole("columnheader", { name: "Dibuat" })).toBeVisible();
  await expect(page.getByRole("columnheader", { name: "Terakhir dipakai" })).toBeVisible();
  await expect(page.getByRole("columnheader", { name: "Status" })).toBeVisible();
  await expect(row.getByText(plain.slice(0, 12))).toBeVisible();
  await expect(row.getByText("Aktif")).toBeVisible();

  // Reload → token polos hilang, baris tetap ada.
  await page.reload();
  await expect(page.getByTestId("created-token")).toHaveCount(0);
  await expect(page.getByText(plain)).toHaveCount(0);
  await expect(page.getByRole("row", { name: /Laptop E2E/ }).getByText(plain.slice(0, 12))).toBeVisible();
  // Terakhir dipakai terisi (bukan "Belum pernah") setelah dipakai di /mcp.
  await expect(page.getByRole("row", { name: /Laptop E2E/ }).getByText("Belum pernah")).toHaveCount(0);

  // Back/forward tidak membawa token polos.
  await page.goto("/account/profile");
  await page.goBack();
  await expect(page.getByText(plain)).toHaveCount(0);

  // Revoke → badge berubah, /mcp 401.
  await page.getByRole("button", { name: "Revoke Laptop E2E" }).click();
  const revokedRow = page.getByRole("row", { name: /Laptop E2E/ });
  await expect(revokedRow.getByText("Revoked")).toBeVisible();
  await expect(page.getByRole("button", { name: "Revoke Laptop E2E" })).toHaveCount(0);
  expect(await mcpStatus(baseURL!, plain)).toBe(401);
});

test("nama token dihitung per code point (100 emoji boleh, 101 ditolak)", async ({ page, seedUser }, testInfo) => {
  const user = await seedUser({
    email: uniqueEmail(testInfo, "tokens-len"),
    displayName: "Lena Panjang",
    role: "member",
    mustChangePassword: false,
  });
  await loginAs(page, user);
  await page.goto("/account/tokens");
  await page.getByLabel("Nama token").fill("😀".repeat(101));
  await page.getByRole("button", { name: "Buat token" }).click();
  await expect(page.getByText("Nama token maksimal 100 karakter")).toBeVisible();
  await page.getByLabel("Nama token").fill("😀".repeat(100));
  await page.getByRole("button", { name: "Buat token" }).click();
  await expect(page.getByTestId("created-token")).toBeVisible();
});

test("token polos tidak ikut riwayat: pergi lalu kembali tidak menampilkannya lagi", async ({ page, seedUser }, testInfo) => {
  const user = await seedUser({
    email: uniqueEmail(testInfo, "tokens-hist"),
    displayName: "Hana Riwayat",
    role: "member",
    mustChangePassword: false,
  });
  await loginAs(page, user);
  await page.goto("/account/tokens");
  await page.getByLabel("Nama token").fill("Riwayat");
  await page.getByRole("button", { name: "Buat token" }).click();
  const value = page.getByTestId("created-token-value");
  await expect(value).toBeVisible();
  const plain = (await value.innerText()).trim();

  await page.getByRole("link", { name: "Profil" }).first().click();
  await expect(page).toHaveURL(/\/account\/profile$/);
  await page.goBack();
  await expect(page).toHaveURL(/\/account\/tokens$/);
  await expect(page.getByRole("heading", { name: "Tokens" })).toBeVisible();
  await expect(page.getByText(plain)).toHaveCount(0);
});

// Bukti visual → evidence/ (gitignored; nama berkas tanpa nilai token; user & token uji dihapus saat teardown).
const EVIDENCE = path.resolve(import.meta.dirname, "evidence");
for (const theme of ["light", "dark"] as const) {
  test(`tampilan Tokens ${theme}: tanpa scroll horizontal, target sentuh 44px di ponsel`, async ({
    page,
    seedUser,
  }, testInfo) => {
    const mobile = testInfo.project.name.startsWith("mobile");
    const user = await seedUser({
      email: uniqueEmail(testInfo, `tokens-vis-${theme}`),
      displayName: "Vera Visual",
      role: "member",
      mustChangePassword: false,
    });
    await page.addInitScript((v) => window.localStorage.setItem("whisker-theme", v), theme);
    await loginAs(page, user);
    await page.goto("/account/tokens");
    for (const name of ["Laptop kerja", "CI runner"]) {
      await page.getByLabel("Nama token").fill(name);
      await page.getByRole("button", { name: "Buat token" }).click();
      await expect(page.getByTestId("created-token")).toContainText(name);
    }
    await page.getByRole("button", { name: "Revoke CI runner" }).click();
    await expect(page.getByRole("row", { name: /CI runner/ }).getByText("Revoked")).toBeVisible();
    await page.getByLabel("Nama token").fill("Laptop baru");
    await page.getByRole("button", { name: "Buat token" }).click();
    await expect(page.getByTestId("created-token")).toBeVisible();
    await page.evaluate(() => document.fonts.ready);
    // Toast sonner masuk dari kanan (fixed) → tunggu animasi selesai sebelum mengukur.
    await expect
      .poll(() => page.evaluate(() => document.documentElement.scrollWidth <= document.body.clientWidth))
      .toBe(true);
    if (mobile) {
      const box = await page.getByRole("button", { name: "Buat token" }).boundingBox();
      expect(Math.round(box!.height)).toBeGreaterThanOrEqual(44);
    }
    await page.screenshot({ path: path.join(EVIDENCE, `account-tokens-${testInfo.project.name}-${theme}.png`), fullPage: true });
  });
}
