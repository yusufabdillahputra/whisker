import { mkdtemp, readFile, readdir } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import { generateAvatars } from "./generate-avatars.mts";

const root = path.resolve(import.meta.dirname, "..");
const keysFile = path.join(root, "src/types/generated/avatar-keys.json");
const fluentDir = path.join(root, "avatars/fluent");

async function run() {
  const outDir = await mkdtemp(path.join(tmpdir(), "whisker-avatars-"));
  const files = await generateAvatars({ keysFile, outDir, fluentDir });
  return { outDir, files };
}

afterEach(() => vi.unstubAllGlobals());

describe("generateAvatars", () => {
  it("menulis tepat 40 SVG sama dengan avatar-keys.json", async () => {
    const keys: { key: string }[] = JSON.parse(await readFile(keysFile, "utf8"));
    const { outDir, files } = await run();
    const expected = keys.map((k) => `${k.key}.svg`).sort();
    expect(expected).toHaveLength(40);
    expect([...files].sort()).toEqual(expected);
    expect((await readdir(outDir)).sort()).toEqual(expected);
  });

  it("tiap SVG memuat <metadata lisensi", async () => {
    const { outDir, files } = await run();
    for (const f of files) {
      expect(await readFile(path.join(outDir, f), "utf8")).toContain("<metadata");
    }
  });

  it("SVG Fluent memuat Microsoft dan MIT; lorelei memuat Lorelei", async () => {
    const { outDir } = await run();
    const animal = await readFile(path.join(outDir, "animal-03.svg"), "utf8");
    expect(animal).toContain("Microsoft");
    expect(animal).toContain("MIT");
    expect(await readFile(path.join(outDir, "human-f-01.svg"), "utf8")).toContain("Lorelei");
  });

  it("urutan latar = indeks preset mulai 0 mod 10 (K17)", async () => {
    const { outDir } = await run();
    const f01 = await readFile(path.join(outDir, "human-f-01.svg"), "utf8");
    const a08 = await readFile(path.join(outDir, "animal-08.svg"), "utf8");
    expect(f01.toLowerCase()).toContain("#fecdd3");
    expect(a08.toLowerCase()).toContain("#fed7aa");
  });

  it("deterministik: dua run byte-identik", async () => {
    const a = await run();
    const b = await run();
    for (const f of a.files) {
      expect(await readFile(path.join(b.outDir, f), "utf8")).toBe(await readFile(path.join(a.outDir, f), "utf8"));
    }
  });

  it("tanpa jaringan: fetch global melempar", async () => {
    const fetchMock = vi.fn(() => {
      throw new Error("jaringan dilarang");
    });
    vi.stubGlobal("fetch", fetchMock);
    const { files } = await run();
    expect(files).toHaveLength(40);
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
