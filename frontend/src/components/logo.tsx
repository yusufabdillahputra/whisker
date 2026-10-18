import { cn } from "@/lib/utils";

// Geometri mark dari canvas Claude Design "Whisker Logo" (berkas acuan:
// `src/assets/logo/whisker-mark-light.svg`). Garis memakai `currentColor` agar mengikuti tema;
// hanya titik hidung yang memakai aksen brand (DESIGN.md §10).
const HEAD = "M52 98C44 98 40 90 40 80V42L56 22L68 38H92L104 22L120 42V80C120 90 116 98 108 98Z";

function Mark({ className, label }: { className?: string; label?: string }) {
  const a11y = label ? { role: "img", "aria-label": label } : { "aria-hidden": true };
  return (
    <svg viewBox="32 14 96 92" fill="none" className={className} {...a11y}>
      <path d={HEAD} stroke="currentColor" strokeWidth={7} strokeLinejoin="round" />
      <path d="M68 58v8M92 58v8" stroke="currentColor" strokeWidth={7} strokeLinecap="round" />
      <circle cx={80} cy={78} r={5} className="fill-brand" data-logo-nose="" />
      <path d="M70 78 51 74M70 85l-19 3M90 78l19-4M90 85l19 3" stroke="currentColor" strokeWidth={5} strokeLinecap="round" />
    </svg>
  );
}

export interface LogoProps {
  variant?: "horizontal" | "mark";
  className?: string;
}

/** Logo Whisker: `horizontal` = mark + wordmark (Sora 600), `mark` = ikon saja. */
export function Logo({ variant = "horizontal", className }: LogoProps) {
  if (variant === "mark") return <Mark label="Whisker" className={cn("h-[29px] w-[30px]", className)} />;
  return (
    <span role="img" aria-label="Whisker" className={cn("inline-flex items-center gap-2 text-foreground", className)}>
      <Mark className="h-[1.45em] w-[1.5em] shrink-0" />
      <span aria-hidden="true" className="font-heading leading-none font-semibold tracking-[-0.03em]">
        whisker
      </span>
    </span>
  );
}
