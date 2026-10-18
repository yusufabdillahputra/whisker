import { createInertiaApp } from "@inertiajs/react";
import type { ComponentType } from "react";
import { createRoot } from "react-dom/client";
import "./styles/globals.css";

const pages = import.meta.glob<{ default: ComponentType }>("./pages/**/*.tsx");

void createInertiaApp({
  resolve: (name) => {
    const page = pages[`./pages/${name}.tsx`];
    if (!page) throw new Error(`Inertia page tidak ditemukan: ${name}`);
    return page().then((m) => m.default);
  },
  setup({ el, App, props }) {
    if (!el) throw new Error("Elemen root Inertia (#app) tidak ada");
    createRoot(el).render(<App {...props} />);
  },
});
