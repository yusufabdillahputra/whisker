import { useState } from "react";
import { AVATAR_GROUP_LABEL, avatarUrl } from "@/lib/avatars";
import { cn } from "@/lib/utils";
import type { AvatarKey } from "@/types/generated/AvatarKey";
import type { AvatarOption } from "@/types/generated/AvatarOption";
import { type AvatarFilter, filterAvatarOptions } from "./filter-avatar-options";

const FILTERS: { id: AvatarFilter; label: string }[] = [
  { id: "all", label: "Semua" },
  { id: "female", label: AVATAR_GROUP_LABEL.female },
  { id: "male", label: AVATAR_GROUP_LABEL.male },
  { id: "animal", label: AVATAR_GROUP_LABEL.animal },
];

export interface AvatarPickerProps {
  value: AvatarKey;
  onChange: (key: AvatarKey) => void;
  options: AvatarOption[];
}

/** Pemilih avatar (DESIGN.md §11): chip filter pill + grid; terpilih = ring 3 px aksen. */
export function AvatarPicker({ value, onChange, options }: AvatarPickerProps) {
  const [filter, setFilter] = useState<AvatarFilter>("all");
  const visible = filterAvatarOptions(options, filter);

  return (
    <div className="flex flex-col gap-4">
      <div role="group" aria-label="Filter avatar" className="flex flex-wrap gap-2">
        {FILTERS.map(({ id, label }) => (
          <button
            key={id}
            type="button"
            aria-pressed={filter === id}
            onClick={() => setFilter(id)}
            className={cn(
              "inline-flex min-h-11 items-center rounded-full border px-4 text-sm font-medium transition-colors md:min-h-8 md:px-3",
              filter === id
                ? "border-foreground bg-accent font-semibold text-foreground"
                : "border-border text-foreground hover:bg-accent",
            )}
          >
            {label}
          </button>
        ))}
      </div>
      <div role="group" aria-label="Pilihan avatar" className="flex flex-wrap gap-3">
        {visible.map(({ key }) => (
          <button
            key={key}
            type="button"
            aria-label={`Avatar ${key}`}
            aria-pressed={key === value}
            onClick={() => onChange(key)}
            className={cn(
              "size-11 shrink-0 rounded-full p-0 transition-shadow md:size-12",
              key === value ? "ring-[3px] ring-[#ff7a45]" : "ring-1 ring-border dark:ring-0",
            )}
          >
            <img
              src={avatarUrl(key)}
              alt=""
              width={48}
              height={48}
              loading="lazy"
              decoding="async"
              className="size-full rounded-full"
            />
          </button>
        ))}
      </div>
    </div>
  );
}
