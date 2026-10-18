import { Monitor, Moon, Sun } from "lucide-react";
import { useTheme } from "@/components/theme-provider";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import { type ThemePreference, isThemePreference } from "@/lib/theme";
import { cn } from "@/lib/utils";

const MODES: { value: ThemePreference; label: string; Icon: typeof Sun }[] = [
  { value: "light", label: "Terang", Icon: Sun },
  { value: "dark", label: "Gelap", Icon: Moon },
  { value: "system", label: "Sistem", Icon: Monitor },
];

/** Segmented control tema (DESIGN.md §6 "Theme toggle"): 40 px web, 44 px mobile. */
export function ThemeToggle({ className }: { className?: string }) {
  const { preference, setPreference } = useTheme();
  return (
    <ToggleGroup
      type="single"
      value={preference}
      onValueChange={(v) => {
        // Radix mengirim "" saat item aktif diklik lagi — tema tetap.
        if (isThemePreference(v)) setPreference(v);
      }}
      aria-label="Tema tampilan"
      data-testid="theme-toggle"
      spacing={0.5}
      className={cn("rounded-lg border border-border bg-background p-0.5", className)}
    >
      {MODES.map(({ value, label, Icon }) => (
        <ToggleGroupItem
          key={value}
          value={value}
          aria-label={label}
          title={label}
          className={cn(
            "size-11 min-w-0 rounded-md px-0 text-muted-foreground md:size-10",
            "hover:bg-transparent hover:text-foreground",
            "data-[state=on]:bg-card data-[state=on]:text-foreground data-[state=on]:shadow-[0_1px_2px_rgb(20_22_27/0.14)]",
          )}
        >
          <Icon className="size-[18px]" aria-hidden="true" />
        </ToggleGroupItem>
      ))}
    </ToggleGroup>
  );
}
