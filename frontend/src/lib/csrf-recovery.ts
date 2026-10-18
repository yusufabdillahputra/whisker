// Pemulihan 419 CSRF (AC Task 11, dari review Task 10). `CsrfLayer` menolak POST dengan cookie
// `XSRF-TOKEN` basi/tidak sah memakai `419` teks polos — tanpa penanganan, Inertia menampilkan modal
// "CSRF token mismatch". Respons 419 itu sekaligus menerbitkan cookie baru, jadi request diulang
// tepat sekali (klien HTTP Inertia membaca ulang cookie saat mengirim). Bila ulangan juga 419, modal
// tetap dicegah dan halaman di-reload sekali (GET tidak dicek CSRF, jadi tak bisa berulang).
import type { router } from "@inertiajs/react";

type InertiaVisitOptions = NonNullable<Parameters<typeof router.visit>[1]>;
type Method = NonNullable<InertiaVisitOptions["method"]>;
type RequestPayload = NonNullable<InertiaVisitOptions["data"]>;

export interface VisitSnapshot {
  url: URL;
  method: Method;
  data: RequestPayload;
  headers: Record<string, string>;
  errorBag?: string | null;
  forceFormData?: boolean;
}

export interface RetryVisitOptions {
  method?: Method;
  data?: RequestPayload;
  headers?: Record<string, string>;
  errorBag?: string | null;
  forceFormData?: boolean;
  preserveState?: boolean;
  preserveScroll?: boolean;
}

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
    const { visit } = last;
    retryStarting = true;
    router.visit(visit.url.href, {
      method: visit.method,
      data: visit.data,
      headers: visit.headers,
      errorBag: visit.errorBag,
      forceFormData: visit.forceFormData,
      preserveState: true,
      preserveScroll: true,
    });
  });

  return () => {
    offBefore();
    offException();
  };
}
