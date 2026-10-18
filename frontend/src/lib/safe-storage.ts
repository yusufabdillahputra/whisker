// Storage yang tidak pernah melempar (review Task 11): di mode privat tertentu atau karena kebijakan
// browser, sekadar membaca `window.localStorage` sudah melempar `SecurityError`, sehingga provider
// tema yang mengaksesnya di luar `try` membuat aplikasi blank. Semua akses dibungkus `try/catch`;
// gagal baca = `null` (tema jatuh ke `system`), gagal tulis/hapus ditelan.

export type SafeStorage = Pick<Storage, "getItem" | "setItem" | "removeItem">;

export function createSafeStorage(resolve: () => Storage | null | undefined): SafeStorage {
  return {
    getItem(key) {
      try {
        return resolve()?.getItem(key) ?? null;
      } catch {
        return null;
      }
    },
    setItem(key, value) {
      try {
        resolve()?.setItem(key, value);
      } catch {
        // abaikan: preferensi tetap berlaku di sesi ini
      }
    },
    removeItem(key) {
      try {
        resolve()?.removeItem(key);
      } catch {
        // abaikan
      }
    },
  };
}

/** `window.localStorage` versi aman; `window` dibaca saat dipakai (aman di luar browser). */
export const safeStorage: SafeStorage = createSafeStorage(() =>
  typeof window === "undefined" ? null : window.localStorage,
);
