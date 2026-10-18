import { describe, expect, it } from "vitest";
import { createSafeStorage } from "./safe-storage";
import { readStoredPreference, writeStoredPreference } from "./theme";

function memoryStorage(): Storage {
  const data = new Map<string, string>();
  return {
    get length() {
      return data.size;
    },
    clear: () => data.clear(),
    key: (i) => [...data.keys()][i] ?? null,
    getItem: (k) => data.get(k) ?? null,
    setItem: (k, v) => void data.set(k, String(v)),
    removeItem: (k) => void data.delete(k),
  };
}

const securityError = () => {
  throw new DOMException("akses storage ditolak", "SecurityError");
};

describe("createSafeStorage", () => {
  it("meneruskan baca/tulis/hapus ke storage yang sehat", () => {
    const backing = memoryStorage();
    const storage = createSafeStorage(() => backing);
    storage.setItem("k", "v");
    expect(backing.getItem("k")).toBe("v");
    expect(storage.getItem("k")).toBe("v");
    storage.removeItem("k");
    expect(storage.getItem("k")).toBeNull();
  });

  it("akses `window.localStorage` yang melempar (mode privat/kebijakan) → baca null, tulis senyap", () => {
    const storage = createSafeStorage(securityError);
    expect(storage.getItem("whisker-theme")).toBeNull();
    expect(() => storage.setItem("whisker-theme", "dark")).not.toThrow();
    expect(() => storage.removeItem("whisker-theme")).not.toThrow();
  });

  it("metode storage yang melempar (kuota, SecurityError) ditelan", () => {
    const storage = createSafeStorage(() => ({
      ...memoryStorage(),
      getItem: securityError,
      setItem: securityError,
      removeItem: securityError,
    }));
    expect(storage.getItem("k")).toBeNull();
    expect(() => storage.setItem("k", "v")).not.toThrow();
    expect(() => storage.removeItem("k")).not.toThrow();
  });

  it("storage tidak tersedia (null/undefined, mis. tanpa window) → null", () => {
    expect(createSafeStorage(() => null).getItem("k")).toBeNull();
    expect(createSafeStorage(() => undefined).getItem("k")).toBeNull();
  });

  it("tema jatuh ke `system` saat storage diblokir", () => {
    const storage = createSafeStorage(securityError);
    expect(readStoredPreference(storage)).toBe("system");
    expect(() => writeStoredPreference(storage, "dark")).not.toThrow();
  });
});
