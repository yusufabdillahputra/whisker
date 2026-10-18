// Tes unit fixture data uji E2E (ruling K10): `npm --prefix test/playwright run test:unit`
// (`node --test`). Tanpa DB: query dicatat oleh Queryable palsu.
import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";
import {
  E2E_EMAIL_DOMAIN,
  E2E_EMAIL_PREFIX,
  type Queryable,
  assertTestEmail,
  cleanupTestData,
  hashPassword,
  newRunId,
  runPrefix,
  seedUserWith,
  uniqueEmail,
} from "./db.ts";

function recorder(rows: unknown[] = []) {
  const calls: { text: string; values: unknown[] }[] = [];
  const db: Queryable = {
    async query(text: string, values: unknown[] = []) {
      calls.push({ text, values });
      return { rows, rowCount: rows.length };
    },
  };
  return { db, calls };
}

const info = (testId: string, retry = 0) => ({ testId, retry });

beforeEach(() => {
  process.env.E2E_RUN_ID = "run42abc";
});

describe("uniqueEmail", () => {
  it("selalu berprefiks e2e+<run-id>- dan berdomain example.test", () => {
    const email = uniqueEmail(info("a1b2c3-d4e5"), "Login OK");
    assert.ok(email.startsWith(`${E2E_EMAIL_PREFIX}run42abc-`), email);
    assert.ok(email.endsWith(E2E_EMAIL_DOMAIN), email);
    assert.equal(email, email.toLowerCase());
    assert.doesNotThrow(() => assertTestEmail(email));
  });

  it("unik per tes, per project, per retry, dan per label", () => {
    // testId Playwright berbagi awalan per file → seluruh id ikut di-hash, bukan dipotong.
    const set = new Set([
      uniqueEmail(info("0123456789abcdef0123-aaaa"), "a"),
      uniqueEmail(info("0123456789abcdef0123-bbbb"), "a"),
      uniqueEmail(info("0123456789abcdef0123-aaaa", 1), "a"),
      uniqueEmail(info("0123456789abcdef0123-aaaa"), "b"),
      uniqueEmail({ ...info("0123456789abcdef0123-aaaa"), project: { name: "mobile-chromium" } }, "a"),
    ]);
    assert.equal(set.size, 5);
  });

  it("menolak tanpa run id", () => {
    delete process.env.E2E_RUN_ID;
    assert.throws(() => uniqueEmail(info("t1"), "a"), /E2E_RUN_ID/);
  });
});

describe("newRunId / runPrefix", () => {
  it("run id huruf kecil + angka, berbeda tiap panggilan", () => {
    const a = newRunId();
    const b = newRunId();
    assert.match(a, /^[a-z0-9]{8,}$/);
    assert.notEqual(a, b);
  });

  it("prefiks run = e2e+<run-id>-", () => {
    assert.equal(runPrefix(), "e2e+run42abc-");
  });
});

describe("assertTestEmail", () => {
  it("menolak email non-uji", () => {
    for (const email of ["owner@contoh.id", "e2e@example.test", "x-e2e+a@example.test", "e2e+a@contoh.id"]) {
      assert.throws(() => assertTestEmail(email), /bukan email uji/, email);
    }
  });
});

describe("cleanupTestData", () => {
  it("menolak berjalan tanpa prefiks e2e+ (tak pernah menyentuh baris non-uji)", async () => {
    for (const prefix of ["", "%", "e2e", "owner@", "e2e-", "E2E+"]) {
      const { db, calls } = recorder();
      await assert.rejects(cleanupTestData(db, prefix), /prefiks/, `prefix ${JSON.stringify(prefix)}`);
      assert.equal(calls.length, 0, `tak ada query untuk ${JSON.stringify(prefix)}`);
    }
  });

  it("hapus vaults milik user uji dulu (FK RESTRICT), lalu users; pola LIKE ter-escape", async () => {
    const { db, calls } = recorder();
    await cleanupTestData(db, "e2e+run_1%-");
    assert.equal(calls.length, 2);
    assert.match(calls[0].text, /DELETE FROM vaults/);
    assert.match(calls[1].text, /DELETE FROM users/);
    for (const c of calls) {
      assert.doesNotMatch(c.text, /TRUNCATE/i);
      assert.deepEqual(c.values, ["e2e+run\\_1\\%-%", `%${E2E_EMAIL_DOMAIN}`]);
    }
  });

  it("prefiks global e2e+ diizinkan untuk menyapu sisa run gagal", async () => {
    const { db, calls } = recorder();
    await cleanupTestData(db, E2E_EMAIL_PREFIX);
    assert.deepEqual(calls[0].values, ["e2e+%", `%${E2E_EMAIL_DOMAIN}`]);
  });
});

describe("seedUserWith", () => {
  it("menolak email tanpa prefiks run", async () => {
    const { db, calls } = recorder();
    await assert.rejects(
      seedUserWith(db, "password-uji-12", {
        email: "owner@contoh.id",
        displayName: "X",
        role: "member",
        mustChangePassword: false,
      }),
      /bukan email uji/,
    );
    assert.equal(calls.length, 0);
  });

  it("INSERT user dengan hash Argon2id dan avatar default", async () => {
    const { db, calls } = recorder([{ id: "0199-uuid" }]);
    const user = await seedUserWith(db, "password-uji-12", {
      email: "e2e+run42abc-t1-a@example.test",
      displayName: "Ani Uji",
      role: "member",
      mustChangePassword: true,
    });
    assert.equal(calls.length, 1);
    assert.match(calls[0].text, /INSERT INTO users/);
    const [email, hash, role, mcp, name, avatar] = calls[0].values as string[];
    assert.equal(email, "e2e+run42abc-t1-a@example.test");
    assert.match(hash, /^\$argon2id\$v=19\$m=19456,t=2,p=1\$/);
    assert.deepEqual([role, mcp, name, avatar], ["member", true, "Ani Uji", "animal-01"]);
    assert.deepEqual(user, {
      id: "0199-uuid",
      email: "e2e+run42abc-t1-a@example.test",
      password: "password-uji-12",
      displayName: "Ani Uji",
      role: "member",
      mustChangePassword: true,
      avatarKey: "animal-01",
    });
  });
});

describe("hashPassword", () => {
  it("Argon2id m=19456 t=2 p=1", async () => {
    assert.match(await hashPassword("password-uji-12"), /^\$argon2id\$v=19\$m=19456,t=2,p=1\$/);
  });
});
