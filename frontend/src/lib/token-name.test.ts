import { describe, expect, it } from "vitest";
import { validateTokenName } from "./token-name";

describe("validateTokenName", () => {
  it("menolak kosong dan spasi saja", () => {
    expect(validateTokenName("")).toBe("Nama token wajib diisi");
    expect(validateTokenName("   ")).toBe("Nama token wajib diisi");
  });
  it("menghitung code point setelah trim: 100 emoji lolos, 101 ditolak", () => {
    expect(validateTokenName("😀".repeat(100))).toBeNull();
    expect(validateTokenName("😀".repeat(101))).toBe("Nama token maksimal 100 karakter");
    expect(validateTokenName(` ${"x".repeat(100)} `)).toBeNull();
  });
});
