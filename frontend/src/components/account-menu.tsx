import { Link, router } from "@inertiajs/react";
import { ChevronDown, FileText, KeyRound, LogOut, type LucideIcon, Shield, User } from "lucide-react";
import { UserAvatar } from "@/components/user-avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import type { Role } from "@/types/generated/Role";
import type { UserProps } from "@/types/generated/UserProps";

const ROLE_LABEL: Record<Role, string> = { admin: "Admin", member: "Member" };

interface NavItem {
  label: string;
  href: string;
  Icon: LucideIcon;
  adminOnly?: boolean;
}

// Urutan canvas `Main` (menu akun): Tokens, Account, Admin Users (admin), lalu Logout.
const NAV_ITEMS: NavItem[] = [
  { label: "Tokens", href: "/account/tokens", Icon: KeyRound },
  { label: "Account", href: "/account/profile", Icon: User },
  { label: "Admin Users", href: "/account/admin", Icon: Shield, adminOnly: true },
];

/** Item menu DESIGN.md §6: `min-h-10 px-2 gap-2`, radius 6; mobile 44 px. */
const ITEM_CLASS = "min-h-11 gap-2 rounded-sm px-2 py-0 text-sm text-foreground md:min-h-10";

/** Menu akun di header (DESIGN.md §6): tombol pill avatar 34 px + chevron, menu 224 px. */
export function AccountMenu({ user }: { user: UserProps }) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <button
          type="button"
          aria-label={`Menu akun ${user.displayName}`}
          className="inline-flex h-11 shrink-0 items-center gap-2 rounded-full border border-border bg-card py-0 pr-2 pl-1 text-foreground transition-colors hover:bg-accent data-[state=open]:bg-accent"
        >
          <UserAvatar avatarKey={user.avatarKey} name={user.displayName} size={34} />
          <ChevronDown className="size-4" aria-hidden="true" />
        </button>
      </DropdownMenuTrigger>
      <DropdownMenuContent
        align="end"
        sideOffset={8}
        className="w-56 rounded-lg p-1 shadow-[0_16px_32px_rgb(20_22_27/0.14)]"
      >
        <DropdownMenuLabel className="mb-1 flex flex-col gap-0.5 border-b border-border p-2 font-normal">
          <span className="truncate text-sm font-semibold">{user.displayName}</span>
          <span className="text-[13px] text-muted-foreground">{ROLE_LABEL[user.role]}</span>
        </DropdownMenuLabel>
        {NAV_ITEMS.filter((item) => !item.adminOnly || user.role === "admin").map(({ label, href, Icon }) => (
          <DropdownMenuItem key={href} asChild className={ITEM_CLASS}>
            <Link href={href}>
              <Icon aria-hidden="true" />
              {label}
            </Link>
          </DropdownMenuItem>
        ))}
        <DropdownMenuSeparator />
        {/* Berkas statis (notice MIT, Task 12) — bukan rute Inertia (ruling K6). */}
        <DropdownMenuItem asChild className={ITEM_CLASS}>
          <a href="/third-party-notices.txt">
            <FileText aria-hidden="true" />
            Lisensi pihak ketiga
          </a>
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem className={ITEM_CLASS} onSelect={() => router.post("/logout")}>
          <LogOut aria-hidden="true" />
          Logout
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
