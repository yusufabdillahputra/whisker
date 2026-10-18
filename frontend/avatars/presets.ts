// Spesifikasi 40 preset avatar (PKM/Architecture/Avatar Pengguna.md). Kunci mengikuti
// `AvatarKey` (dari Rust via ts-rs); `Record<AvatarKey, …>` memaksa kelengkapan saat compile.
import type { AvatarKey } from "../src/types/generated/AvatarKey.ts";

export type PresetSpec =
  | { kind: "lorelei"; hair: string; mouth: string; earrings: boolean; beard: boolean; background: string }
  | { kind: "fluent"; file: string; background: string };

// 10 warna Tailwind 200, bergiliran menurut indeks preset mulai 0 (ruling K17).
export const BACKGROUNDS = [
  "#fecdd3",
  "#fbcfe8",
  "#ddd6fe",
  "#c7d2fe",
  "#bae6fd",
  "#99f6e4",
  "#bbf7d0",
  "#d9f99d",
  "#fde68a",
  "#fed7aa",
] as const;

const FEMALE_HAIR = [13, 14, 15, 16, 17, 18, 19, 21, 23, 24, 26, 29, 32, 35, 41, 45];
const MALE_HAIR = [1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 22, 25, 28, 43, 44];
const MALE_BEARD = new Set([4, 9, 14]);
const ANIMALS = ["cat_face", "dog_face", "fox", "panda", "rabbit_face", "bear", "koala", "tiger_face"];

const pad = (n: number) => String(n).padStart(2, "0");
const variant = (n: number) => `variant${pad(n)}`;

const entries: [string, PresetSpec][] = [];
const bg = () => BACKGROUNDS[entries.length % BACKGROUNDS.length]!;

FEMALE_HAIR.forEach((hair, i) => {
  const n = i + 1;
  entries.push([
    `human-f-${pad(n)}`,
    { kind: "lorelei", hair: variant(hair), mouth: `happy${pad(n)}`, earrings: n % 2 === 1, beard: false, background: bg() },
  ]);
});
MALE_HAIR.forEach((hair, i) => {
  const n = i + 1;
  entries.push([
    `human-m-${pad(n)}`,
    { kind: "lorelei", hair: variant(hair), mouth: `happy${pad(n)}`, earrings: false, beard: MALE_BEARD.has(n), background: bg() },
  ]);
});
ANIMALS.forEach((file, i) => {
  entries.push([`animal-${pad(i + 1)}`, { kind: "fluent", file, background: bg() }]);
});

export const PRESETS = Object.fromEntries(entries) as Record<AvatarKey, PresetSpec>;
