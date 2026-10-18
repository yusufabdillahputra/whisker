// Env harness E2E: `.e2e.env` (gitignored) lalu `process.env` (nilai yang sudah ada menang).
import path from "node:path";
import dotenv from "dotenv";

dotenv.config({ path: path.resolve(import.meta.dirname, "..", ".e2e.env"), quiet: true });

function required(name: string): string {
  const v = process.env[name];
  if (!v) throw new Error(`${name} wajib diisi (lihat test/playwright/.e2e.env.example)`);
  return v;
}

export const baseUrl = process.env.E2E_BASE_URL ?? "http://127.0.0.1:8080";

/** URL DB dev yang sama dengan monolith (`db-whisker`, keputusan owner Q8). */
export function databaseUrl(): string {
  return required("E2E_DATABASE_URL");
}

/** Password semua user seed (min 12 karakter, aturan password backend). */
export function userPassword(): string {
  const v = required("E2E_USER_PASSWORD");
  if (v.length < 12) throw new Error("E2E_USER_PASSWORD minimal 12 karakter");
  return v;
}
