import { Head, useForm } from "@inertiajs/react";
import type { FormEvent } from "react";

// SEMENTARA (spike Task 01): diganti `import type { PingPageProps } from "@/types/generated/PingPageProps"`
// begitu export `ts` veer tersedia (part 2). Harus cocok persis dengan struct Rust.
interface PingPageProps {
  message: string;
}

export default function Ping({ message }: PingPageProps) {
  const form = useForm({ text: "" });

  function submit(e: FormEvent) {
    e.preventDefault();
    form.post("/spike/echo");
  }

  return (
    <main className="mx-auto max-w-md p-4">
      <Head title="Spike Ping" />
      <h1 className="text-xl font-semibold">Spike Ping</h1>
      <p data-testid="message">{message}</p>
      <form onSubmit={submit} className="mt-4 flex flex-col gap-2">
        <label htmlFor="text">Teks</label>
        <input
          id="text"
          className="rounded border px-2 py-1"
          value={form.data.text}
          onChange={(e) => form.setData("text", e.target.value)}
          aria-invalid={form.errors.text ? true : undefined}
        />
        {form.errors.text && <p role="alert">{form.errors.text}</p>}
        <button type="submit" disabled={form.processing} className="rounded border px-2 py-1">
          Kirim
        </button>
      </form>
    </main>
  );
}
