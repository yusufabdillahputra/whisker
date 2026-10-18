import { describe, expect, it } from "vitest";
import { ACCOUNT_SECTIONS, visibleSections } from "./account-sections";

describe("ACCOUNT_SECTIONS", () => {
  it("urutan, label, dan rute sub-menu Akun (canvas AccountView)", () => {
    expect(ACCOUNT_SECTIONS.map((s) => [s.id, s.label, s.href, s.adminOnly])).toEqual([
      ["profile", "Profil", "/account/profile", false],
      ["security", "Keamanan", "/account/security", false],
      ["tokens", "Tokens", "/account/tokens", false],
      ["admin", "Admin Users", "/account/admin", true],
    ]);
  });
});

describe("visibleSections", () => {
  it("member melihat 3 item (tanpa Admin Users)", () => {
    expect(visibleSections("member").map((s) => s.id)).toEqual(["profile", "security", "tokens"]);
  });

  it("admin melihat 4 item", () => {
    expect(visibleSections("admin").map((s) => s.id)).toEqual(["profile", "security", "tokens", "admin"]);
  });
});
