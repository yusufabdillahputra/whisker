import { describe, expect, it, vi } from "vitest";
import { type CsrfRecoveryRouter, type RetryVisitOptions, installCsrfRecovery } from "./csrf-recovery";

type Listener = (event: CustomEvent) => void;

/** Router palsu: menyimpan listener dan mencatat `visit`. */
function fakeRouter() {
  const listeners = new Map<string, Set<Listener>>();
  const visits: { href: string; options: RetryVisitOptions }[] = [];
  const router: CsrfRecoveryRouter = {
    on(type: string, cb: Listener) {
      const set = listeners.get(type) ?? new Set<Listener>();
      set.add(cb);
      listeners.set(type, set);
      return () => set.delete(cb);
    },
    visit(href, options) {
      visits.push({ href, options });
      // Kunjungan ulang memicu `before` seperti router Inertia asli.
      emitBefore(href, options.method ?? "get", options.data ?? {}, options);
    },
  } as CsrfRecoveryRouter;

  function emit(type: string, detail: unknown) {
    const event = new CustomEvent(`inertia:${type}`, { detail, cancelable: true });
    for (const cb of listeners.get(type) ?? []) cb(event);
    return event;
  }
  function emitBefore(href: string, method: string, data: unknown, extra: Record<string, unknown> = {}) {
    return emit("before", {
      visit: { headers: {}, ...extra, url: new URL(href, "http://127.0.0.1:8080"), method, data },
    });
  }
  const httpException = (status: number) => emit("httpException", { response: { status } });

  return { router, visits, emitBefore, httpException, listeners };
}

describe("installCsrfRecovery", () => {
  it("419 pertama: modal dicegah dan request diulang tepat sekali", () => {
    const f = fakeRouter();
    const reload = vi.fn();
    installCsrfRecovery(f.router, { reload });

    f.emitBefore("/login", "post", { email: "a@b.test", password: "x" });
    const event = f.httpException(419);

    expect(event.defaultPrevented).toBe(true);
    expect(f.visits).toHaveLength(1);
    expect(f.visits[0].href).toBe("http://127.0.0.1:8080/login");
    expect(f.visits[0].options).toMatchObject({
      method: "post",
      data: { email: "a@b.test", password: "x" },
      preserveState: true,
      preserveScroll: true,
    });
    expect(reload).not.toHaveBeenCalled();
  });

  it("kunjungan ulang membawa method, data, opsi, dan callback asli (form tetap konsisten)", () => {
    const f = fakeRouter();
    installCsrfRecovery(f.router, { reload: vi.fn() });
    const onSuccess = vi.fn();
    const onError = vi.fn();
    const onFinish = vi.fn();
    const onStart = vi.fn();

    // Bentuk `PendingVisit` Inertia: opsi visit + callback + field internal.
    f.emitBefore(
      "/account/security/password",
      "put",
      { currentPassword: "lama", password: "baru-panjang-12", passwordConfirmation: "baru-panjang-12" },
      {
        id: "visit-1",
        completed: false,
        cancelled: false,
        interrupted: false,
        headers: { "X-Custom": "1" },
        preserveState: "errors",
        preserveScroll: false,
        replace: false,
        only: [],
        errorBag: "",
        forceFormData: false,
        onSuccess,
        onError,
        onFinish,
        onStart,
      },
    );
    f.httpException(419);

    expect(f.visits).toHaveLength(1);
    const { href, options } = f.visits[0];
    expect(href).toBe("http://127.0.0.1:8080/account/security/password");
    expect(options).toMatchObject({
      method: "put",
      data: { currentPassword: "lama", password: "baru-panjang-12", passwordConfirmation: "baru-panjang-12" },
      headers: { "X-Custom": "1" },
      preserveState: "errors",
      preserveScroll: false,
      replace: false,
      only: [],
    });
    expect(options.onSuccess).toBe(onSuccess);
    expect(options.onError).toBe(onError);
    expect(options.onFinish).toBe(onFinish);
    expect(options.onStart).toBe(onStart);
    // Field internal kunjungan lama tidak ikut (Inertia membuat id/status baru).
    for (const key of ["id", "url", "completed", "cancelled", "interrupted"]) {
      expect(options, key).not.toHaveProperty(key);
    }
  });

  it("419 lagi pada request ulang: tanpa ulang kedua, modal tetap dicegah, satu reload", () => {
    const f = fakeRouter();
    const reload = vi.fn();
    installCsrfRecovery(f.router, { reload });

    f.emitBefore("/login", "post", {});
    f.httpException(419); // memicu ulang
    const second = f.httpException(419); // ulang juga 419

    expect(second.defaultPrevented).toBe(true);
    expect(f.visits).toHaveLength(1);
    expect(reload).toHaveBeenCalledTimes(1);
  });

  it("kunjungan baru setelah pemulihan kembali mendapat jatah satu kali ulang", () => {
    const f = fakeRouter();
    installCsrfRecovery(f.router, { reload: vi.fn() });

    f.emitBefore("/login", "post", {});
    f.httpException(419);
    f.emitBefore("/logout", "post", {});
    f.httpException(419);

    expect(f.visits.map((v) => v.href)).toEqual([
      "http://127.0.0.1:8080/login",
      "http://127.0.0.1:8080/logout",
    ]);
  });

  it("status selain 419 tidak disentuh", () => {
    const f = fakeRouter();
    const reload = vi.fn();
    installCsrfRecovery(f.router, { reload });

    f.emitBefore("/login", "post", {});
    for (const status of [403, 422, 429, 500]) {
      expect(f.httpException(status).defaultPrevented).toBe(false);
    }
    expect(f.visits).toHaveLength(0);
    expect(reload).not.toHaveBeenCalled();
  });

  it("419 tanpa kunjungan yang dikenal: modal dicegah, satu reload", () => {
    const f = fakeRouter();
    const reload = vi.fn();
    installCsrfRecovery(f.router, { reload });

    expect(f.httpException(419).defaultPrevented).toBe(true);
    expect(f.visits).toHaveLength(0);
    expect(reload).toHaveBeenCalledTimes(1);
  });

  it("fungsi pelepas mencopot semua listener", () => {
    const f = fakeRouter();
    const uninstall = installCsrfRecovery(f.router, { reload: vi.fn() });
    uninstall();
    expect([...f.listeners.values()].every((s) => s.size === 0)).toBe(true);
  });
});
