// Sapu manual data uji E2E di DB dev bersama: `npm --prefix test/playwright run cleanup [-- <prefiks>]`.
// Default prefiks `e2e+` (semua run); hanya user `e2e+…@example.test` dan vault miliknya yang dihapus.
import { cleanupTestData, createPool, E2E_EMAIL_PREFIX } from "../fixtures/db.ts";
import { databaseUrl } from "../fixtures/env.ts";

const prefix = process.argv[2] ?? E2E_EMAIL_PREFIX;
const pool = createPool(databaseUrl());
try {
  const removed = await cleanupTestData(pool, prefix);
  console.log(`dihapus: ${removed.users} user uji, ${removed.vaults} vault (prefiks ${prefix})`);
} finally {
  await pool.end();
}
