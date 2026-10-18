import type { AvatarGroup } from "@/types/generated/AvatarGroup";
import type { AvatarOption } from "@/types/generated/AvatarOption";

export type AvatarFilter = "all" | AvatarGroup;

/** Pilihan avatar untuk filter kelompok; urutan asli dipertahankan. */
export function filterAvatarOptions(options: AvatarOption[], filter: AvatarFilter): AvatarOption[] {
  return filter === "all" ? options : options.filter((o) => o.group === filter);
}
