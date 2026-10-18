import { createInertiaApp, router } from "@inertiajs/react";
import type { ComponentType } from "react";
import { createRoot } from "react-dom/client";
import { ThemeProvider } from "@/components/theme-provider";
import { installCsrfRecovery } from "@/lib/csrf-recovery";
import "./styles/globals.css";

const pages = import.meta.glob<{ default: ComponentType }>("./pages/**/*.tsx");

// 419 CSRF → satu kali coba ulang tanpa modal "CSRF token mismatch" (AC Task 11).
installCsrfRecovery(router);

void createInertiaApp({
  resolve: (name) => {
    const page = pages[`./pages/${name}.tsx`];
    if (!page) throw new Error(`Inertia page tidak ditemukan: ${name}`);
    return page().then((m) => m.default);
  },
  setup({ el, App, props }) {
    if (!el) throw new Error("Elemen root Inertia (#app) tidak ada");
    createRoot(el).render(
      <ThemeProvider>
        <App {...props} />
      </ThemeProvider>,
    );
  },
});
