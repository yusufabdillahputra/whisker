import { avatarUrl } from "@/lib/avatars";
import { cn } from "@/lib/utils";
import type { AvatarKey } from "@/types/generated/AvatarKey";

export interface UserAvatarProps {
  avatarKey: AvatarKey;
  /** Nama tampilan pengguna; dipakai sebagai teks alternatif (bukan nama preset). */
  name: string;
  /** Sisi gambar dalam px. */
  size?: number;
  className?: string;
}

/** Avatar bulat; ring token Border di tema Terang agar tepi pastel terlihat (DESIGN.md). */
export function UserAvatar({ avatarKey, name, size = 32, className }: UserAvatarProps) {
  return (
    <img
      src={avatarUrl(avatarKey)}
      alt={name}
      width={size}
      height={size}
      loading="lazy"
      decoding="async"
      className={cn("shrink-0 rounded-full ring-1 ring-border dark:ring-0", className)}
      style={{ width: size, height: size }}
    />
  );
}
