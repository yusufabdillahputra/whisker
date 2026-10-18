// Sub-menu halaman Akun (canvas AccountView; DESIGN.md §1: istilah produk "Tokens", "Admin Users").
import type { Role } from "@/types/generated/Role";

export type AccountSectionId = "profile" | "security" | "tokens" | "admin";

export interface AccountSection {
  id: AccountSectionId;
  label: string;
  href: string;
  /** Hanya tampil untuk admin. */
  adminOnly: boolean;
}

export const ACCOUNT_SECTIONS: readonly AccountSection[] = [
  { id: "profile", label: "Profil", href: "/account/profile", adminOnly: false },
  { id: "security", label: "Keamanan", href: "/account/security", adminOnly: false },
  { id: "tokens", label: "Tokens", href: "/account/tokens", adminOnly: false },
  { id: "admin", label: "Admin Users", href: "/account/admin", adminOnly: true },
];

/** Item sub-menu yang boleh dilihat role ini (Admin Users hanya untuk admin). */
export function visibleSections(role: Role): AccountSection[] {
  return ACCOUNT_SECTIONS.filter((s) => !s.adminOnly || role === "admin");
}
