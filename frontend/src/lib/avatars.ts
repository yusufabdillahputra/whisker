import type { AvatarGroup } from "@/types/generated/AvatarGroup";
import type { AvatarKey } from "@/types/generated/AvatarKey";

/** URL SVG statis avatar (dibuat saat build, disajikan dari root). */
export function avatarUrl(key: AvatarKey): string {
  return `/avatars/${key}.svg`;
}

export const AVATAR_GROUP_LABEL: Record<AvatarGroup, string> = {
  female: "Perempuan",
  male: "Laki-laki",
  animal: "Hewan",
};
