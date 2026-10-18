// Tema Terang / Gelap / Sistem (DESIGN.md §9). Skrip inline di root view Rust
// (`crates/whisker/src/app.rs`, HEAD_EXTRAS) memakai kunci + logika yang sama.

export type ThemePreference = "light" | "dark" | "system";
export type ResolvedTheme = "light" | "dark";

export const THEME_STORAGE_KEY = "whisker-theme";

export function isThemePreference(value: unknown): value is ThemePreference {
  return value === "light" || value === "dark" || value === "system";
}

export function resolveTheme(pref: ThemePreference, systemPrefersDark: boolean): ResolvedTheme {
  if (pref === "system") return systemPrefersDark ? "dark" : "light";
  return pref;
}

/** Preferensi tersimpan; kosong, tak sah, atau storage tak bisa dibaca → `"system"`. */
export function readStoredPreference(storage: Pick<Storage, "getItem">): ThemePreference {
  try {
    const value = storage.getItem(THEME_STORAGE_KEY);
    return isThemePreference(value) ? value : "system";
  } catch {
    return "system";
  }
}

/** Simpan preferensi; galat storage (mode privat, kuota) ditelan — tema tetap berlaku di sesi ini. */
export function writeStoredPreference(storage: Pick<Storage, "setItem">, pref: ThemePreference): void {
  try {
    storage.setItem(THEME_STORAGE_KEY, pref);
  } catch {
    // abaikan
  }
}

/** Pasang tema efektif: kelas `dark` + `color-scheme` di elemen root. */
export function applyTheme(resolved: ResolvedTheme, root: HTMLElement): void {
  root.classList.toggle("dark", resolved === "dark");
  root.style.colorScheme = resolved;
}
