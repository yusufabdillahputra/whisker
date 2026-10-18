import { mkdtemp, readFile, readdir } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import { PRESETS } from "../avatars/presets.ts";
import { generateAvatars, loreleiOptions } from "./generate-avatars.mts";

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

describe("loreleiOptions", () => {
  const opts = (key: keyof typeof PRESETS) => {
    const p = PRESETS[key];
    if (p.kind !== "lorelei") throw new Error("bukan lorelei");
    return loreleiOptions(key, p) as Record<string, unknown>;
  };

  it("laki-laki: hairAccessoriesProbability 0 dan earringsProbability 0", () => {
    const o = opts("human-m-03");
    expect(o.hairAccessoriesProbability).toBe(0);
    expect(o.earringsProbability).toBe(0);
  });

  it("perempuan: tanpa kunci hairAccessoriesProbability", () => {
    expect("hairAccessoriesProbability" in opts("human-f-01")).toBe(false);
    expect("hairAccessoriesProbability" in opts("human-f-02")).toBe(false);
  });

  it("anting: f-01 100, f-02 0", () => {
    expect(opts("human-f-01").earringsProbability).toBe(100);
    expect(opts("human-f-02").earringsProbability).toBe(0);
  });

  it("janggut: m-04 100, m-03 0", () => {
    expect(opts("human-m-04").beardProbability).toBe(100);
    expect(opts("human-m-03").beardProbability).toBe(0);
  });
});
