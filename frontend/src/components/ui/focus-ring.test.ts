// Ring fokus DESIGN.md §5: `outline: 2px solid #FF7A45; outline-offset: 2px` pada `:focus-visible`
// (review Task 11). Aturan dasar ada di globals.css; komponen dasar shadcn tidak boleh menimpanya
// dengan ring shadcn (box-shadow 3px ring/50) atau mematikan outline.
import { readFileSync, readdirSync } from "node:fs";
import path from "node:path";
import { describe, expect, it } from "vitest";

const SRC = path.resolve(import.meta.dirname, "../..");
const css = readFileSync(path.join(SRC, "styles/globals.css"), "utf8");
const uiDir = path.join(SRC, "components/ui");
const uiFiles = readdirSync(uiDir).filter((f) => f.endsWith(".tsx"));

describe("ring fokus", () => {
  it("token --ring = aksen #FF7A45 dan aturan dasar :focus-visible sesuai DESIGN.md §5", () => {
    expect(css).toMatch(/:root\s*{[^}]*--ring:\s*#ff7a45;/i);
    expect(css).toMatch(/:focus-visible\s*{\s*outline:\s*2px solid var\(--ring\);\s*outline-offset:\s*2px;\s*}/);
  });

  it("komponen dasar ui/* tidak menimpa ring fokus dasar", () => {
    expect(uiFiles.length).toBeGreaterThan(0);
    for (const file of uiFiles) {
      const src = readFileSync(path.join(uiDir, file), "utf8");
      expect(src, file).not.toMatch(/focus-visible:ring-(\[3px\]|ring\/50)/);
      expect(src, file).not.toMatch(/focus-visible:border-ring/);
      expect(src, file).not.toMatch(/\boutline-(none|hidden)\b/);
    }
  });
});
