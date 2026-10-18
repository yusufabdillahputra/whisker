// Generator 40 avatar saat build: DiceBear `lorelei` (CC0) + Fluent Emoji Flat (MIT, di-vendor).
// Tanpa jaringan: semua masukan lokal; keluaran deterministik.
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { Avatar, Style } from "@dicebear/core";
import lorelei from "@dicebear/styles/lorelei.json" with { type: "json" };
import { PRESETS, type PresetSpec } from "../avatars/presets.ts";

export interface GenerateOptions {
  keysFile: string;
  outDir: string;
  fluentDir: string;
}

const SIZE = 128;
const ICON_RATIO = 0.64;
const loreleiStyle = new Style(lorelei as never);

const FLUENT_METADATA =
  '<metadata><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dc="http://purl.org/dc/elements/1.1/">' +
  "<rdf:Description><dc:title>Fluent Emoji (Flat)</dc:title><dc:creator>Microsoft Corporation</dc:creator>" +
  "<dc:source>https://github.com/microsoft/fluentui-emoji</dc:source>" +
  "<dc:rights>MIT License. Copyright (c) Microsoft Corporation.</dc:rights></rdf:Description></rdf:RDF></metadata>";

type LoreleiPreset = Extract<PresetSpec, { kind: "lorelei" }>;

/** Opsi DiceBear per preset (spesifikasi "Kunci dan opsi bersama"); murni, tanpa efek samping. */
export function loreleiOptions(key: string, p: LoreleiPreset) {
  const male = key.startsWith("human-m-");
  return {
    seed: `whisker-${key}`,
    borderRadius: 50,
    backgroundColorFill: "solid" as const,
    backgroundColor: [p.background],
    hairVariant: p.hair,
    mouthVariant: p.mouth,
    earringsProbability: p.earrings ? 100 : 0,
    beardProbability: p.beard ? 100 : 0,
    ...(p.beard ? { beardVariant: "variant02" } : {}),
    ...(male ? { hairAccessoriesProbability: 0 } : {}),
    glassesProbability: 0,
    frecklesProbability: 0,
    size: SIZE,
  };
}

function renderLorelei(key: string, p: LoreleiPreset): string {
  return new Avatar(loreleiStyle, loreleiOptions(key, p) as never).toString();
}

async function renderFluent(p: Extract<PresetSpec, { kind: "fluent" }>, fluentDir: string): Promise<string> {
  const src = await readFile(path.join(fluentDir, `${p.file}_flat.svg`), "utf8");
  const inner = src.replace(/^[\s\S]*?<svg[^>]*>/, "").replace(/<\/svg>\s*$/, "");
  const icon = Math.round(SIZE * ICON_RATIO);
  const offset = (SIZE - icon) / 2;
  const r = SIZE / 2;
  return (
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${SIZE} ${SIZE}" width="${SIZE}" height="${SIZE}" fill="none" aria-hidden="true">` +
    FLUENT_METADATA +
    `<circle cx="${r}" cy="${r}" r="${r}" fill="${p.background}"/>` +
    `<svg x="${offset}" y="${offset}" width="${icon}" height="${icon}" viewBox="0 0 32 32" fill="none">${inner.trim()}</svg></svg>`
  );
}

/** Menulis satu SVG per kunci di `avatar-keys.json`; mengembalikan nama berkas (`<key>.svg`). */
export async function generateAvatars({ keysFile, outDir, fluentDir }: GenerateOptions): Promise<string[]> {
  const keys: { key: keyof typeof PRESETS }[] = JSON.parse(await readFile(keysFile, "utf8"));
  await mkdir(outDir, { recursive: true });
  const names: string[] = [];
  for (const { key } of keys) {
    const preset = PRESETS[key];
    if (!preset) throw new Error(`Preset tidak ada untuk kunci ${key}`);
    const svg = preset.kind === "lorelei" ? renderLorelei(key, preset) : await renderFluent(preset, fluentDir);
    const name = `${key}.svg`;
    await writeFile(path.join(outDir, name), svg);
    names.push(name);
  }
  return names;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
  const root = path.resolve(import.meta.dirname, "..");
  const files = await generateAvatars({
    keysFile: path.join(root, "src/types/generated/avatar-keys.json"),
    outDir: path.join(root, "public/avatars"),
    fluentDir: path.join(root, "avatars/fluent"),
  });
  console.log(`generate-avatars: ${files.length} SVG -> public/avatars`);
}
