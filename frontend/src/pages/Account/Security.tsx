import { useForm } from "@inertiajs/react";
import type { FormEvent } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { AccountLayout } from "@/layouts/account-layout";
import type { AccountSecurityProps } from "@/types/generated/AccountSecurityProps";
import type { ChangePasswordForm } from "@/types/generated/ChangePasswordForm";
import type { SharedProps } from "@/types/generated/SharedProps";

type Field = keyof ChangePasswordForm;

/** `errors` diisi protokol Inertia (422 `render_validation`), bukan bagian struct props Rust. */
type Props = AccountSecurityProps & SharedProps & { errors?: Partial<Record<Field, string>> };

const FIELDS: { name: Field; label: string; autoComplete: string; hint?: string }[] = [
  { name: "currentPassword", label: "Password saat ini", autoComplete: "current-password" },
  {
    name: "password",
    label: "Password baru",
    autoComplete: "new-password",
    hint: "Minimal 12 karakter. Frasa panjang lebih kuat daripada simbol acak.",
  },
  { name: "passwordConfirmation", label: "Ulangi password baru", autoComplete: "new-password" },
];

// Copy dari canvas AccountView (section Keamanan); pemberitahuan wajib-ganti & toast = turunan (Q14).
export default function Security({ forced, errors = {} }: Props) {
  const form = useForm<ChangePasswordForm>({ currentPassword: "", password: "", passwordConfirmation: "" });

  function submit(e: FormEvent) {
    e.preventDefault();
    form.put("/account/security/password", {
      // Benar tanpa bergantung pada `onSuccess` (constraint 419 review Task 11): state page hanya
      // dipertahankan saat ada error; sukses → page dipasang ulang sehingga form kosong dengan
      // sendirinya. Error dibaca dari props page, bukan `form.errors`.
      preserveState: "errors",
      preserveScroll: true,
      // Respons 422 membawa `url` = path request (`/account/security/password`), bukan path page;
      // pertahankan URL Keamanan. Saat `forced`, sukses berpindah ke `/` sehingga URL tak boleh
      // dipertahankan (bila 422, reload GET path itu dialihkan guard kembali ke Keamanan).
      preserveUrl: !forced,
      onSuccess: () => {
        toast.success("Password berhasil diganti.");
      },
    });
  }

  return (
    <AccountLayout section="security" title="Keamanan">
      {forced && (
        <div role="status" className="rounded-lg border border-border bg-accent p-4 text-sm text-foreground">
          Anda wajib mengganti password sebelum melanjutkan.
        </div>
      )}
      <section
        data-testid="security-card"
        aria-labelledby="security-title"
        className="flex flex-col gap-4 rounded-xl border border-border bg-card p-4 text-card-foreground md:gap-6 md:p-6"
      >
        <div className="flex flex-col gap-1.5">
          <h2 id="security-title" className="text-xl tracking-[-0.02em]">
            Keamanan
          </h2>
          <p className="text-sm text-muted-foreground">
            Ganti password. Setelah berhasil, sesi di perangkat lain akan keluar.
          </p>
        </div>
        <form onSubmit={submit} noValidate className="flex flex-col gap-4 md:gap-6">
          {FIELDS.map(({ name, label, autoComplete, hint }) => {
            const error = errors[name];
            const describedBy = [hint && `${name}-hint`, error && `${name}-error`].filter(Boolean).join(" ");
            return (
              <div key={name} className="flex flex-col gap-1.5">
                <Label htmlFor={name} className="font-semibold">
                  {label}
                </Label>
                <Input
                  id={name}
                  type="password"
                  autoComplete={autoComplete}
                  required
                  value={form.data[name]}
                  onChange={(e) => form.setData(name, e.target.value)}
                  aria-invalid={error ? true : undefined}
                  aria-describedby={describedBy || undefined}
                  className="h-11 bg-background text-base md:h-9 md:text-sm dark:bg-background"
                />
                {hint && (
                  <p id={`${name}-hint`} className="text-[13px] text-muted-foreground">
                    {hint}
                  </p>
                )}
                {error && (
                  <p id={`${name}-error`} role="alert" className="text-[13px] text-destructive">
                    {error}
                  </p>
                )}
              </div>
            );
          })}
          <div className="flex justify-end">
            <Button
              type="submit"
              disabled={form.processing}
              className="h-11 w-full text-[15px] font-semibold md:h-9 md:w-auto md:text-sm"
            >
              Ganti password
            </Button>
          </div>
        </form>
      </section>
    </AccountLayout>
  );
}
