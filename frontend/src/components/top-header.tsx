import { Link } from "@inertiajs/react";
import { AccountMenu } from "@/components/account-menu";
import { Logo } from "@/components/logo";
import { ThemeToggle } from "@/components/theme-toggle";
import type { UserProps } from "@/types/generated/UserProps";

/** Header atas (DESIGN.md §6/§8): `h-14` + safe area, logo → Projects, tema, menu akun. */
export function TopHeader({ user }: { user: UserProps }) {
  return (
    <header className="box-content border-b border-border bg-card pt-[env(safe-area-inset-top)]">
      <div className="flex h-14 items-center justify-between gap-2 px-2 md:gap-4 md:px-8">
        <Link href="/" aria-label="Whisker — semua project" className="flex shrink-0 items-center rounded-md">
          <Logo className="text-[20px]" />
        </Link>
        <div className="flex items-center gap-2 md:gap-3">
          <ThemeToggle />
          <AccountMenu user={user} />
        </div>
      </div>
    </header>
  );
}
