import { type ReactNode, createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import {
  type ResolvedTheme,
  type ThemePreference,
  applyTheme,
  readStoredPreference,
  resolveTheme,
  writeStoredPreference,
} from "@/lib/theme";

const DARK_QUERY = "(prefers-color-scheme: dark)";

interface ThemeContextValue {
  preference: ThemePreference;
  setPreference: (pref: ThemePreference) => void;
  resolved: ResolvedTheme;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

function systemPrefersDark(): boolean {
  return typeof window.matchMedia === "function" && window.matchMedia(DARK_QUERY).matches;
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [preference, setPreferenceState] = useState<ThemePreference>(() => readStoredPreference(window.localStorage));
  const [systemDark, setSystemDark] = useState(systemPrefersDark);

  // Mode Sistem mengikuti perubahan preferensi perangkat secara langsung.
  useEffect(() => {
    if (typeof window.matchMedia !== "function") return;
    const media = window.matchMedia(DARK_QUERY);
    const onChange = () => setSystemDark(media.matches);
    media.addEventListener("change", onChange);
    return () => media.removeEventListener("change", onChange);
  }, []);

  const resolved = resolveTheme(preference, systemDark);

  useEffect(() => {
    applyTheme(resolved, document.documentElement);
  }, [resolved]);

  const setPreference = useCallback((pref: ThemePreference) => {
    writeStoredPreference(window.localStorage, pref);
    setPreferenceState(pref);
  }, []);

  const value = useMemo(() => ({ preference, setPreference, resolved }), [preference, setPreference, resolved]);
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme(): ThemeContextValue {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error("useTheme() harus dipakai di dalam <ThemeProvider>");
  return ctx;
}
