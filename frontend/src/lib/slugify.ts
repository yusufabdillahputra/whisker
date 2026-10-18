// Cermin `whisker-core::vault::slug` (Rust). Divalidasi vektor bersama
// crates/whisker-core/tests/fixtures/slug_vectors.json. Server tetap otoritas akhir.

export const SLUG_MAX_LEN = 63;
export const SLUG_FALLBACK = "project";

const TRANSLITERATION: Record<string, string> = {
  ß: "ss",
  æ: "ae",
  œ: "oe",
  ø: "o",
  đ: "d",
  ł: "l",
  þ: "th",
  ð: "d",
};

const trimDashes = (s: string): string => s.replace(/^-+|-+$/g, "");

export function slugify(name: string): string {
  const folded = name.normalize("NFKD").replace(/\p{M}/gu, "");
  let out = "";
  for (const ch of folded) {
    const lower = ch.toLowerCase();
    const mapped = TRANSLITERATION[lower];
    if (mapped !== undefined) {
      out += mapped;
    } else if (/^[a-z0-9]$/.test(lower)) {
      out += lower;
    } else if (!out.endsWith("-")) {
      out += "-";
    }
  }
  const slug = trimDashes(trimDashes(out).slice(0, SLUG_MAX_LEN));
  return slug === "" ? SLUG_FALLBACK : slug;
}

export function slugCandidate(base: string, attempt: number): string {
  if (attempt <= 1) return base;
  const suffix = `-${attempt}`;
  const room = SLUG_MAX_LEN - suffix.length;
  let head = trimDashes(base.slice(0, Math.max(room, 0)));
  if (head === "") head = trimDashes(SLUG_FALLBACK.slice(0, Math.max(room, 0)));
  return head + suffix;
}

export function previewSlug(name: string, takenSlugs: readonly string[]): string {
  const base = slugify(name);
  const taken = new Set(takenSlugs);
  for (let attempt = 1; ; attempt += 1) {
    const candidate = slugCandidate(base, attempt);
    if (!taken.has(candidate)) return candidate;
  }
}
