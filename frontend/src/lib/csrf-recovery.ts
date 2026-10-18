// Pemulihan 419 CSRF (AC Task 11, dari review Task 10). `CsrfLayer` menolak POST dengan cookie
// `XSRF-TOKEN` basi/tidak sah memakai `419` teks polos — tanpa penanganan, Inertia menampilkan modal
// "CSRF token mismatch". Respons 419 itu sekaligus menerbitkan cookie baru, jadi request diulang
// tepat sekali (klien HTTP Inertia membaca ulang cookie saat mengirim). Bila ulangan juga 419, modal
// tetap dicegah dan halaman di-reload sekali (GET tidak dicek CSRF, jadi tak bisa berulang).
//
// Kunjungan ulang membawa **seluruh** opsi + callback kunjungan asli (`onSuccess`, `onError`,
// `onFinish`, `preserveState`, header, …; review Task 11): event `before` Inertia membawa
// `PendingVisit` yang memuat semua opsi `router.visit`/`useForm`, termasuk callback. Hanya field
// internal (`id`, `url`, status) yang dibuang — Inertia membuat yang baru.
import type { router } from "@inertiajs/react";

/** Opsi `router.visit` (termasuk callback `useForm`). */
export type RetryVisitOptions = NonNullable<Parameters<typeof router.visit>[1]>;

/** Isi `event.detail.visit` pada event `before` (`PendingVisit` Inertia). */
export type VisitSnapshot = RetryVisitOptions & {
  url: URL;
  id?: string;
  completed?: boolean;
  cancelled?: boolean;
  interrupted?: boolean;
};

/** Subset router Inertia yang dipakai (memudahkan tes unit). */
export interface CsrfRecoveryRouter {
  on(type: "before", callback: (event: CustomEvent<{ visit: VisitSnapshot }>) => void): () => void;
  on(type: "httpException", callback: (event: CustomEvent<{ response: { status: number } }>) => void): () => void;
  visit(href: string, options: RetryVisitOptions): void;
}

export const CSRF_MISMATCH_STATUS = 419;

export function installCsrfRecovery(
  router: CsrfRecoveryRouter,
  { reload = () => window.location.reload() }: { reload?: () => void } = {},
): () => void {
  let current: { visit: VisitSnapshot; isRetry: boolean } | null = null;
  let retryStarting = false;

  const offBefore = router.on("before", (event) => {
    current = { visit: event.detail.visit, isRetry: retryStarting };
    retryStarting = false;
  });

  const offException = router.on("httpException", (event) => {
    if (event.detail.response.status !== CSRF_MISMATCH_STATUS) return;
    event.preventDefault(); // cegah modal "CSRF token mismatch"

    const last = current;
    if (!last || last.isRetry) {
      current = null;
      reload();
      return;
    }
    const { url, id: _id, completed: _done, cancelled: _cancelled, interrupted: _interrupted, ...options } = last.visit;
    retryStarting = true;
    // Default lama (Task 11) hanya bila kunjungan asli tidak menyebutnya; Inertia selalu mengisinya.
    router.visit(url.href, { preserveState: true, preserveScroll: true, ...options });
  });

  return () => {
    offBefore();
    offException();
  };
}
