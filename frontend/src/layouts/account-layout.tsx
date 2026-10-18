import { Head, Link, usePage } from "@inertiajs/react";
import { KeyRound, Lock, type LucideIcon, Shield, User } from "lucide-react";
import type { ReactNode } from "react";
import { TopHeader } from "@/components/top-header";
import { type AccountSectionId, visibleSections } from "@/lib/account-sections";
import { cn } from "@/lib/utils";
import type { SharedProps } from "@/types/generated/SharedProps";

const ICONS: Record<AccountSectionId, LucideIcon> = {
  profile: User,
  security: Lock,
  tokens: KeyRound,
  admin: Shield,
};

/**
 * Kerangka halaman `/account/*` (canvas AccountView): header atas, sub-menu, konten section.
 * Web: sub-menu vertikal 200 px di kiri. Mobile: tab horizontal `h-11` yang bisa digeser.
 */
export function AccountLayout({
  section,
  title,
  children,
}: {
  section: AccountSectionId;
  title: string;
  children: ReactNode;
}) {
  const { auth } = usePage<SharedProps>().props;
  if (!auth) throw new Error("AccountLayout butuh sesi login (shared props auth)");
  const sections = visibleSections(auth.user.role);

  return (
    <div className="min-h-svh">
      <Head title={title} />
      <TopHeader user={auth.user} />
      <main className="mx-auto flex max-w-7xl flex-col gap-4 px-4 pt-4 pb-8 md:gap-8 md:px-8 md:pt-12 md:pb-16">
        <h1 className="text-[28px] tracking-[-0.03em]">Akun</h1>
        <div className="flex flex-col gap-4 md:flex-row md:gap-8">
          <nav
            aria-label="Menu akun"
            className="-mx-4 flex shrink-0 gap-2 overflow-x-auto px-4 py-1 md:mx-0 md:w-[200px] md:flex-col md:gap-1 md:overflow-visible md:px-0 md:py-0"
          >
            {sections.map(({ id, label, href }) => {
              const Icon = ICONS[id];
              const current = id === section;
              return (
                <Link
                  key={id}
                  href={href}
                  aria-current={current ? "page" : undefined}
                  className={cn(
                    "flex min-h-11 shrink-0 items-center gap-2 rounded-md border px-3 text-sm whitespace-nowrap text-foreground transition-colors hover:bg-accent",
                    "md:min-h-8 md:border-0 md:px-2",
                    current ? "border-foreground bg-accent font-semibold" : "border-border font-medium",
                  )}
                >
                  <Icon className="size-4 shrink-0" aria-hidden="true" />
                  {label}
                </Link>
              );
            })}
          </nav>
          <div className="flex min-w-0 flex-1 flex-col gap-6">{children}</div>
        </div>
      </main>
    </div>
  );
}
