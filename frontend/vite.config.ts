import path from "node:path";
import inertia from "@inertiajs/vite";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// Aset build di /build/ (bukan /assets/) agar tidak bentrok dengan GET /assets/{id} (ADR-006).
export default defineConfig({
  plugins: [inertia({ ssr: false }), react(), tailwindcss()],
  resolve: { alias: { "@": path.resolve(import.meta.dirname, "src") } },
  base: "/",
  build: {
    outDir: "dist",
    assetsDir: "build",
    manifest: true,
    rollupOptions: { input: "src/app.tsx" },
  },
  server: { port: 5173, strictPort: true, origin: "http://localhost:5173" },
});
