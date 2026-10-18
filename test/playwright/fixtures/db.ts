// Data uji E2E di DB dev bersama `db-whisker` (keputusan owner Q8): hanya user berprefiks
// `e2e+<run-id>-…@example.test` yang dibuat dan dihapus. Tanpa TRUNCATE, tanpa reset DB.
import { createHash } from "node:crypto";
import { hash } from "@node-rs/argon2";
import pg from "pg";

export const E2E_EMAIL_PREFIX = "e2e+";
export const E2E_EMAIL_DOMAIN = "@example.test";
export const DEFAULT_AVATAR_KEY = "animal-01";

/** Subset `pg.Pool` / `pg.Client` yang dipakai fixture (memudahkan tes unit tanpa DB). */
export interface Queryable {
  query(text: string, values?: unknown[]): Promise<{ rows: unknown[]; rowCount: number | null }>;
}

export type Role = "admin" | "member";

export interface SeedUserInput {
  email: string;
  displayName: string;
  role: Role;
  mustChangePassword: boolean;
  avatarKey?: string;
}

export interface SeededUser extends Required<SeedUserInput> {
  id: string;
  password: string;
}

/** Id run baru: huruf kecil + angka (aman untuk email dan pola LIKE). */
export function newRunId(): string {
  const rand = Math.random().toString(36).slice(2, 8).padEnd(6, "0");
  return `${Date.now().toString(36)}${rand}`;
}

/** Id run aktif — dipasang global setup di `process.env.E2E_RUN_ID`. */
export function currentRunId(): string {
  const id = process.env.E2E_RUN_ID;
  if (!id || !/^[a-z0-9]+$/.test(id)) {
    throw new Error("E2E_RUN_ID belum dipasang (global setup Playwright) atau tidak sah");
  }
  return id;
}

/** Prefiks email seluruh data uji run ini: `e2e+<run-id>-`. */
export function runPrefix(): string {
  return `${E2E_EMAIL_PREFIX}${currentRunId()}-`;
}

function slug(s: string): string {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 24);
}

/** Identitas tes yang dipakai untuk menurunkan data unik (subset `TestInfo`). */
export interface TestIdentity {
  testId: string;
  retry: number;
  project?: { name: string };
}

/** Hash pendek identitas tes: unik per tes, per project Playwright, dan per retry. */
export function testKey(t: TestIdentity, length = 12): string {
  return createHash("sha256")
    .update(`${t.project?.name ?? ""}|${t.testId}|${t.retry}`)
    .digest("hex")
    .slice(0, length);
}

/** Email uji unik per tes + project + retry + label: `e2e+<run-id>-<hash>-<label>@example.test`. */
export function uniqueEmail(testInfo: TestIdentity, label: string): string {
  return `${runPrefix()}${testKey(testInfo)}-${slug(label) || "user"}${E2E_EMAIL_DOMAIN}`;
}

/** Lempar galat bila `email` bukan email uji (`e2e+…@example.test`). */
export function assertTestEmail(email: string): void {
  if (!email.startsWith(E2E_EMAIL_PREFIX) || !email.endsWith(E2E_EMAIL_DOMAIN)) {
    throw new Error(`bukan email uji (wajib ${E2E_EMAIL_PREFIX}…${E2E_EMAIL_DOMAIN}): ${email}`);
  }
}

/** Hash password sama dengan backend: Argon2id m=19456 t=2 p=1 (default algoritma = Argon2id). */
export function hashPassword(password: string): Promise<string> {
  return hash(password, { memoryCost: 19456, timeCost: 2, parallelism: 1 });
}

export async function seedUserWith(db: Queryable, password: string, input: SeedUserInput): Promise<SeededUser> {
  assertTestEmail(input.email);
  const avatarKey = input.avatarKey ?? DEFAULT_AVATAR_KEY;
  const passwordHash = await hashPassword(password);
  const { rows } = await db.query(
    `INSERT INTO users (email, password_hash, role, must_change_password, display_name, avatar_key)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
    [input.email, passwordHash, input.role, input.mustChangePassword, input.displayName, avatarKey],
  );
  const id = String((rows[0] as { id: unknown }).id);
  return {
    id,
    email: input.email,
    password,
    displayName: input.displayName,
    role: input.role,
    mustChangePassword: input.mustChangePassword,
    avatarKey,
  };
}

function likePrefix(prefix: string): string {
  return `${prefix.replace(/[\\%_]/g, (c) => `\\${c}`)}%`;
}

/**
 * Hapus data uji berprefiks `prefix` (wajib diawali `e2e+`): `vaults` milik user uji dulu (FK
 * `RESTRICT`), lalu `users` uji (sesi + token ikut `CASCADE`). Idempoten.
 */
export async function cleanupTestData(db: Queryable, prefix: string): Promise<{ vaults: number; users: number }> {
  if (!prefix.startsWith(E2E_EMAIL_PREFIX)) {
    throw new Error(`cleanup ditolak: prefiks wajib diawali "${E2E_EMAIL_PREFIX}" (diberi ${JSON.stringify(prefix)})`);
  }
  const values = [likePrefix(prefix), `%${E2E_EMAIL_DOMAIN}`];
  const where = `email LIKE $1 ESCAPE '\\' AND email LIKE $2`;
  const vaults = await db.query(`DELETE FROM vaults WHERE owner_id IN (SELECT id FROM users WHERE ${where})`, values);
  const users = await db.query(`DELETE FROM users WHERE ${where}`, values);
  return { vaults: vaults.rowCount ?? 0, users: users.rowCount ?? 0 };
}

export interface NonTestCounts {
  users: number;
  vaults: number;
  accessTokens: number;
}

/** Jumlah baris non-uji (untuk membuktikan run E2E tidak menyentuhnya). */
export async function countNonTestRows(db: Queryable): Promise<NonTestCounts> {
  const testUser = `email LIKE 'e2e+%' AND email LIKE '%${E2E_EMAIL_DOMAIN}'`;
  const { rows } = await db.query(
    `SELECT
       (SELECT count(*) FROM users WHERE NOT (${testUser}))::int AS users,
       (SELECT count(*) FROM vaults WHERE owner_id NOT IN (SELECT id FROM users WHERE ${testUser}))::int AS vaults,
       (SELECT count(*) FROM access_tokens WHERE user_id NOT IN (SELECT id FROM users WHERE ${testUser}))::int AS "accessTokens"`,
  );
  return rows[0] as NonTestCounts;
}

export function createPool(databaseUrl: string): pg.Pool {
  return new pg.Pool({ connectionString: databaseUrl, max: 4 });
}
