import { useForm } from "@inertiajs/react";
import type { FormEvent } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { UserAvatar } from "@/components/user-avatar";
import { AvatarPicker } from "@/features/profile/avatar-picker";
import { AccountLayout } from "@/layouts/account-layout";
import type { AccountProfileProps } from "@/types/generated/AccountProfileProps";
import type { AvatarKey } from "@/types/generated/AvatarKey";
import type { ProfileForm } from "@/types/generated/ProfileForm";
import type { SharedProps } from "@/types/generated/SharedProps";

type Field = keyof ProfileForm;

/** `errors` diisi protokol Inertia (422 `render_validation`), bukan bagian struct props Rust. */
type Props = AccountProfileProps & SharedProps & { errors?: Partial<Record<Field, string>> };

export default function Profile({ avatarOptions, auth, errors = {} }: Props) {
  if (!auth) throw new Error("Profil butuh sesi login (shared props auth)");
  const { user } = auth;
  const form = useForm<ProfileForm>({ displayName: user.displayName, avatarKey: user.avatarKey });

  function submit(e: FormEvent) {
    e.preventDefault();
    form.put("/account/profile", {
      // Sama seperti Keamanan: benar tanpa `onSuccess`; error dibaca dari props page.
      preserveState: "errors",
      preserveScroll: true,
      onSuccess: () => {
        toast.success("Profil disimpan.");
      },
    });
  }

  const nameError = errors.displayName;
  const avatarError = errors.avatarKey;

  return (
    <AccountLayout section="profile" title="Profil">
      <section
        data-testid="profile-card"
        aria-labelledby="profile-title"
        className="flex flex-col gap-4 rounded-xl border border-border bg-card p-4 text-card-foreground md:gap-6 md:p-6"
      >
        <div className="flex flex-col gap-1.5">
          <h2 id="profile-title" className="text-xl tracking-[-0.02em]">
            Profil
          </h2>
          <p className="text-sm text-muted-foreground">Nama tampilan dan avatar Anda.</p>
        </div>
        <form onSubmit={submit} noValidate className="flex flex-col gap-4 md:gap-6">
          <div className="flex items-center gap-4">
            <UserAvatar
              avatarKey={form.data.avatarKey as AvatarKey}
              name={`Avatar saat ini: ${form.data.avatarKey}`}
              size={80}
            />
            <p className="text-sm text-muted-foreground">Pilih salah satu dari 40 avatar di bawah.</p>
          </div>
          <div className="flex flex-col gap-1.5">
            <span className="text-sm font-semibold">Avatar</span>
            <AvatarPicker
              value={form.data.avatarKey as AvatarKey}
              onChange={(key) => form.setData("avatarKey", key)}
              options={avatarOptions}
            />
            {avatarError && (
              <p id="avatarKey-error" role="alert" className="text-[13px] text-destructive">
                {avatarError}
              </p>
            )}
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="displayName" className="font-semibold">
              Nama tampilan
            </Label>
            <Input
              id="displayName"
              autoComplete="name"
              required
              value={form.data.displayName}
              onChange={(e) => form.setData("displayName", e.target.value)}
              aria-invalid={nameError ? true : undefined}
              aria-describedby={nameError ? "displayName-error" : undefined}
              className="h-11 bg-background text-base md:h-9 md:text-sm dark:bg-background"
            />
            {nameError && (
              <p id="displayName-error" role="alert" className="text-[13px] text-destructive">
                {nameError}
              </p>
            )}
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="email" className="font-semibold">
              Email
            </Label>
            <Input
              id="email"
              type="email"
              readOnly
              value={user.email}
              aria-describedby="email-hint"
              className="h-11 bg-muted text-base md:h-9 md:text-sm"
            />
            <p id="email-hint" className="text-[13px] text-muted-foreground">
              Email diubah oleh admin.
            </p>
          </div>
          <div className="flex justify-end">
            <Button
              type="submit"
              disabled={form.processing}
              className="h-11 w-full text-[15px] font-semibold md:h-9 md:w-auto md:text-sm"
            >
              Simpan
            </Button>
          </div>
        </form>
      </section>
    </AccountLayout>
  );
}
