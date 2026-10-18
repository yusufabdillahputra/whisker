import { describe, expect, it } from "vitest";
import keys from "@/types/generated/avatar-keys.json";
import { AVATAR_GROUP_LABEL, avatarUrl } from "./avatars";

describe("avatars", () => {
  it("avatarUrl memetakan kunci ke /avatars/<kunci>.svg", () => {
    expect(avatarUrl("human-f-01")).toBe("/avatars/human-f-01.svg");
    expect(avatarUrl("animal-08")).toBe("/avatars/animal-08.svg");
  });

  it("AVATAR_GROUP_LABEL mencakup semua grup di avatar-keys.json", () => {
    const groups = new Set(keys.map((k) => k.group));
    expect([...groups].sort()).toEqual(Object.keys(AVATAR_GROUP_LABEL).sort());
    expect(AVATAR_GROUP_LABEL).toEqual({ female: "Perempuan", male: "Laki-laki", animal: "Hewan" });
  });
});
