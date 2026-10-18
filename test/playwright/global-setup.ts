// Global setup/teardown harness E2E di DB dev bersama (keputusan owner Q8):
// 1. pasang E2E_RUN_ID (diwarisi worker), 2. sapu sisa data `e2e+` dari run gagal,
// 3. catat jumlah baris non-uji; teardown menghapus data run ini lalu memastikan baris non-uji
//    tidak berubah.
import { E2E_EMAIL_PREFIX, cleanupTestData, countNonTestRows, createPool, newRunId, runPrefix } from "./fixtures/db.ts";
import { databaseUrl } from "./fixtures/env.ts";

export default async function globalSetup() {
  process.env.E2E_RUN_ID = newRunId();
  const pool = createPool(databaseUrl());
  try {
    const swept = await cleanupTestData(pool, E2E_EMAIL_PREFIX);
    if (swept.users > 0) console.log(`[e2e] sisa data uji lama dihapus: ${swept.users} user, ${swept.vaults} vault`);
    const before = await countNonTestRows(pool);
    console.log(`[e2e] run ${process.env.E2E_RUN_ID}; baris non-uji: ${JSON.stringify(before)}`);

    return async () => {
      const db = createPool(databaseUrl());
      try {
        const removed = await cleanupTestData(db, runPrefix());
        const after = await countNonTestRows(db);
        console.log(`[e2e] teardown: ${removed.users} user uji dihapus; baris non-uji: ${JSON.stringify(after)}`);
        if (JSON.stringify(after) !== JSON.stringify(before)) {
          throw new Error(`baris non-uji berubah selama run E2E: ${JSON.stringify(before)} → ${JSON.stringify(after)}`);
        }
      } finally {
        await db.end();
      }
    };
  } finally {
    await pool.end();
  }
}
