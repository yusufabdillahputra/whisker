import { describe, expect, it } from "vitest";
import {
  THEME_STORAGE_KEY,
  applyTheme,
  readStoredPreference,
  resolveTheme,
  writeStoredPreference,
} from "./theme";

function fakeRoot() {
  const classes = new Set<string>();
  const root = {
    classList: {
      toggle: (name: string, force?: boolean) => {
        const on = force ?? !classes.has(name);
        if (on) classes.add(name);
        else classes.delete(name);
        return on;
      },
    },
    style: { colorScheme: "" },
  };
  return { root: root as unknown as HTMLElement, classes };
}

describe("resolveTheme", () => {
  it("system mengikuti preferensi perangkat", () => {
    expect(resolveTheme("system", true)).toBe("dark");
    expect(resolveTheme("system", false)).toBe("light");
  });

  it("pilihan eksplisit mengabaikan preferensi perangkat", () => {
    expect(resolveTheme("light", true)).toBe("light");
    expect(resolveTheme("dark", false)).toBe("dark");
  });
});

describe("readStoredPreference", () => {
  it("memakai kunci whisker-theme", () => {
    expect(THEME_STORAGE_KEY).toBe("whisker-theme");
    const keys: string[] = [];
    readStoredPreference({
      getItem: (k) => {
        keys.push(k);
        return "dark";
      },
    });
    expect(keys).toEqual(["whisker-theme"]);
  });

  it("nilai sah dikembalikan apa adanya", () => {
    for (const v of ["light", "dark", "system"] as const) {
      expect(readStoredPreference({ getItem: () => v })).toBe(v);
    }
  });

  it("nilai tersimpan tak sah atau kosong → system", () => {
    expect(readStoredPreference({ getItem: () => "ungu" })).toBe("system");
    expect(readStoredPreference({ getItem: () => "" })).toBe("system");
    expect(readStoredPreference({ getItem: () => null })).toBe("system");
  });

  it("storage yang melempar galat → system", () => {
    const storage = {
      getItem: (): string | null => {
        throw new Error("SecurityError");
      },
    };
    expect(readStoredPreference(storage)).toBe("system");
  });
});

describe("writeStoredPreference", () => {
  it("menyimpan di kunci whisker-theme dan menelan galat storage", () => {
    const saved: Record<string, string> = {};
    writeStoredPreference({ setItem: (k, v) => void (saved[k] = v) }, "dark");
    expect(saved).toEqual({ "whisker-theme": "dark" });
    expect(() =>
      writeStoredPreference(
        {
          setItem: () => {
            throw new Error("QuotaExceeded");
          },
        },
        "light",
      ),
    ).not.toThrow();
  });
});

describe("applyTheme", () => {
  it("gelap memasang kelas dark + color-scheme", () => {
    const { root, classes } = fakeRoot();
    applyTheme("dark", root);
    expect(classes.has("dark")).toBe(true);
    expect(root.style.colorScheme).toBe("dark");
  });

  it("terang melepas kelas dark", () => {
    const { root, classes } = fakeRoot();
    applyTheme("dark", root);
    applyTheme("light", root);
    expect(classes.has("dark")).toBe(false);
    expect(root.style.colorScheme).toBe("light");
  });
});
