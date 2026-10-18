import { describe, expect, it } from "vitest";
import { formatDateTime } from "./format-date";

describe("formatDateTime", () => {
  it("memformat RFC 3339 UTC ke tanggal+jam lokal (id-ID)", () => {
    const out = formatDateTime("2026-10-18T03:04:05.123456Z");
    expect(out).toMatch(/2026/);
    expect(out).toMatch(/\d{2}[.:]\d{2}/);
  });
  it("mengembalikan string asli bila tidak terurai", () => {
    expect(formatDateTime("bukan-tanggal")).toBe("bukan-tanggal");
  });
});
