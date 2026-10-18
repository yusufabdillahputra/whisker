// Kontras WCAG token warna di globals.css (Confirmation 10): `--link` mode gelap wajib lolos AA
// (≥ 4,5:1) di atas `#0E1014`; teks badge metode HTTP lolos AA di atas latarnya, kedua tema.
import { readFileSync } from "node:fs";
import path from "node:path";
import { describe, expect, it } from "vitest";

const css = readFileSync(path.resolve(import.meta.dirname, "globals.css"), "utf8");

function block(selector: string): Record<string, string> {
  const match = css.match(new RegExp(`(?:^|\\n)${selector.replace(".", "\\.")}\\s*{([^}]*)}`));
  if (!match) throw new Error(`blok ${selector} tidak ada`);
  return Object.fromEntries([...match[1].matchAll(/(--[\w-]+):\s*([^;]+);/g)].map((m) => [m[1], m[2].trim()]));
}

function luminance(hex: string): number {
  const [r, g, b] = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255);
  const lin = (c: number) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
  return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
}

function contrast(a: string, b: string): number {
  const [x, y] = [luminance(a), luminance(b)].sort((p, q) => q - p);
  return (x + 0.05) / (y + 0.05);
}

const light = block(":root");
const dark = { ...light, ...block(".dark") };

describe("kontras --link", () => {
  it("mode gelap punya override sendiri (bukan nilai terang)", () => {
    expect(block(".dark")["--link"]).toBeDefined();
    expect(block(".dark")["--link-hover"]).toBeDefined();
    expect(dark["--link"]).not.toBe(light["--link"]);
  });

  it("mode gelap: link & hover ≥ 4,5:1 di #0E1014 dan di surface", () => {
    expect(dark["--background"].toLowerCase()).toBe("#0e1014");
    for (const token of ["--link", "--link-hover"]) {
      expect(contrast(dark[token], "#0e1014"), token).toBeGreaterThanOrEqual(4.5);
      expect(contrast(dark[token], dark["--card"]), `${token} di surface`).toBeGreaterThanOrEqual(4.5);
    }
  });

  it("mode terang: link & hover ≥ 4,5:1 di bg dan surface", () => {
    for (const token of ["--link", "--link-hover"]) {
      expect(contrast(light[token], light["--background"]), token).toBeGreaterThanOrEqual(4.5);
      expect(contrast(light[token], light["--card"]), `${token} di surface`).toBeGreaterThanOrEqual(4.5);
    }
  });
});

describe("kontras badge metode HTTP", () => {
  for (const hue of ["sky", "green", "amber", "red", "gray"]) {
    it(`${hue}: teks ≥ 4,5:1 di latar badge, kedua tema`, () => {
      for (const [name, theme] of [
        ["terang", light],
        ["gelap", dark],
      ] as const) {
        const bg = theme[`--badge-${hue}`];
        const fg = theme[`--badge-${hue}-foreground`];
        expect(bg && fg, `${name} ${hue}`).toBeTruthy();
        expect(contrast(fg, bg), `${name} ${hue}`).toBeGreaterThanOrEqual(4.5);
      }
    });
  }
});
