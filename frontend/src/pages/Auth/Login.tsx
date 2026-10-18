import { Head, useForm } from "@inertiajs/react";
import type { FormEvent } from "react";
import { Logo } from "@/components/logo";
import { ThemeToggle } from "@/components/theme-toggle";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { LoginPageProps } from "@/types/generated/LoginPageProps";
import type { SharedProps } from "@/types/generated/SharedProps";

/** `errors` diisi protokol Inertia (veer), bukan bagian struct props Rust. */
type Props = LoginPageProps & SharedProps & { errors?: { email?: string; password?: string } };

// Turunan dari token canvas (DESIGN.md §12) — canvas tidak punya artboard Login (asumsi Q14).
export default function Login({ errors }: Props) {
  const form = useForm({ email: "", password: "" });
  // Error dibaca dari props page (bukan `form.errors`) agar tetap tampil setelah request diulang
  // oleh pemulihan 419 CSRF di luar `useForm`.
  const message = errors?.email ?? errors?.password;

  function submit(e: FormEvent) {
    e.preventDefault();
    form.post("/login", { onError: () => form.reset("password") });
  }

  return (
    <div className="flex min-h-svh flex-col">
      <Head title="Masuk" />
      <div className="flex justify-end p-4 md:px-8">
        <ThemeToggle />
      </div>
      <main className="flex flex-1 flex-col items-center px-4 pt-8 pb-16 md:justify-center md:pt-0">
        <div className="flex w-full max-w-[400px] flex-col items-center gap-8">
          <div className="flex flex-col items-center gap-2">
            <Logo className="text-[32px]" />
            <p className="text-[15px] text-muted-foreground">sense the context.</p>
          </div>
          <section
            data-testid="login-card"
            aria-labelledby="login-title"
            className="flex w-full flex-col gap-4 rounded-xl border border-border bg-card p-4 text-card-foreground md:gap-6 md:p-6"
          >
            <div className="flex flex-col gap-1.5">
              <h1 id="login-title" className="text-xl tracking-[-0.02em]">
                Masuk
              </h1>
              <p className="text-sm text-muted-foreground">Masuk ke Whisker dengan email dan password akun Anda.</p>
            </div>
            <form onSubmit={submit} noValidate className="flex flex-col gap-4">
              <div className="flex flex-col gap-2">
                <Label htmlFor="email" className="font-semibold">
                  Email
                </Label>
                <Input
                  id="email"
                  type="email"
                  autoComplete="username"
                  required
                  value={form.data.email}
                  onChange={(e) => form.setData("email", e.target.value)}
                  aria-invalid={message ? true : undefined}
                  aria-describedby={message ? "login-error" : undefined}
                  className="h-11 bg-background text-base md:h-9 md:text-sm dark:bg-background"
                />
              </div>
              <div className="flex flex-col gap-2">
                <Label htmlFor="password" className="font-semibold">
                  Password
                </Label>
                <Input
                  id="password"
                  type="password"
                  autoComplete="current-password"
                  required
                  value={form.data.password}
                  onChange={(e) => form.setData("password", e.target.value)}
                  aria-invalid={message ? true : undefined}
                  aria-describedby={message ? "login-error" : undefined}
                  className="h-11 bg-background text-base md:h-9 md:text-sm dark:bg-background"
                />
              </div>
              {message && (
                <p id="login-error" role="alert" className="text-[13px] text-destructive">
                  {message}
                </p>
              )}
              <Button
                type="submit"
                disabled={form.processing}
                className="h-11 w-full text-[15px] font-semibold md:h-9 md:text-sm"
              >
                Masuk
              </Button>
            </form>
          </section>
        </div>
      </main>
    </div>
  );
}
