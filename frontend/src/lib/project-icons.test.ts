import { iconNames } from "lucide-react/dynamic";
import { describe, expect, it } from "vitest";
import allowlist from "../types/generated/project-icons.json";
import { PROJECT_ICONS } from "./project-icons";

describe("PROJECT_ICONS", () => {
  it("kunci sama dengan project-icons.json (jumlah dan urutan)", () => {
    expect(allowlist).toHaveLength(61);
    expect(Object.keys(PROJECT_ICONS)).toEqual(allowlist);
  });

  it("tiap nama allowlist ada di Lucide", () => {
    const known = new Set<string>(iconNames);
    for (const name of allowlist) expect(known.has(name), name).toBe(true);
  });

  it("tiap nama dipetakan ke komponen Lucide", () => {
    for (const name of allowlist) {
      const icon = PROJECT_ICONS[name as keyof typeof PROJECT_ICONS];
      expect(icon, name).toBeDefined();
      expect(["function", "object"]).toContain(typeof icon);
    }
  });
});
