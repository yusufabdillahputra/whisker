import { describe, expect, it } from "vitest";
import keys from "@/types/generated/avatar-keys.json";
import type { AvatarOption } from "@/types/generated/AvatarOption";
import { filterAvatarOptions } from "./filter-avatar-options";

const options = keys as AvatarOption[];

describe("filterAvatarOptions", () => {
  it("hitungan filter 40/16/16/8", () => {
    expect(filterAvatarOptions(options, "all")).toHaveLength(40);
    expect(filterAvatarOptions(options, "female")).toHaveLength(16);
    expect(filterAvatarOptions(options, "male")).toHaveLength(16);
    expect(filterAvatarOptions(options, "animal")).toHaveLength(8);
  });

  it("mempertahankan urutan dan hanya memuat grup yang diminta", () => {
    const animals = filterAvatarOptions(options, "animal");
    expect(animals.every((o) => o.group === "animal")).toBe(true);
    expect(animals.map((o) => o.key)).toEqual([...animals.map((o) => o.key)].sort());
  });
});
