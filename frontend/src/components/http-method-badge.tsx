import { cn } from "@/lib/utils";

// Badge metode HTTP (Confirmation 10, DESIGN.md §7): GET sky · POST green · PUT/PATCH amber ·
// DELETE red; varian mono. Method lain (HEAD, OPTIONS, …) memakai gray.
export type BadgeHue = "sky" | "green" | "amber" | "red" | "gray";

const HUE_BY_METHOD: Record<string, BadgeHue> = {
  GET: "sky",
  POST: "green",
  PUT: "amber",
  PATCH: "amber",
  DELETE: "red",
};

export function httpMethodHue(method: string): BadgeHue {
  return HUE_BY_METHOD[method.toUpperCase()] ?? "gray";
}

// Kelas literal (bukan template) agar terdeteksi Tailwind.
const HUE_CLASS: Record<BadgeHue, string> = {
  sky: "bg-badge-sky text-badge-sky-foreground",
  green: "bg-badge-green text-badge-green-foreground",
  amber: "bg-badge-amber text-badge-amber-foreground",
  red: "bg-badge-red text-badge-red-foreground",
  gray: "bg-badge-gray text-badge-gray-foreground",
};

export function HttpMethodBadge({ method, className }: { method: string; className?: string }) {
  const hue = httpMethodHue(method);
  return (
    <span
      data-hue={hue}
      className={cn(
        HUE_CLASS[hue],
        "inline-flex h-[22px] shrink-0 items-center rounded-sm px-2 font-mono text-xs font-medium whitespace-nowrap",
        className,
      )}
    >
      {method.toUpperCase()}
    </span>
  );
}
