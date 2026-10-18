// @vitest-environment jsdom
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { useState } from "react";
import { afterEach, describe, expect, it } from "vitest";
import type { AvatarKey } from "@/types/generated/AvatarKey";
import type { AvatarOption } from "@/types/generated/AvatarOption";
import keys from "@/types/generated/avatar-keys.json";
import { AvatarPicker } from "./avatar-picker";

afterEach(cleanup);

function Harness({ initial }: { initial: AvatarKey }) {
  const [value, setValue] = useState<AvatarKey>(initial);
  return <AvatarPicker value={value} onChange={setValue} options={keys as AvatarOption[]} />;
}

describe("AvatarPicker", () => {
  it("menampilkan 40 pilihan dan filter Hewan menyisakan 8", () => {
    render(<Harness initial="human-f-01" />);
    expect(screen.getAllByRole("button", { name: /^Avatar / })).toHaveLength(40);
    fireEvent.click(screen.getByRole("button", { name: "Hewan" }));
    expect(screen.getAllByRole("button", { name: /^Avatar / })).toHaveLength(8);
    expect(screen.getByRole("button", { name: "Hewan" }).getAttribute("aria-pressed")).toBe("true");
    expect(screen.getByRole("button", { name: "Semua" }).getAttribute("aria-pressed")).toBe("false");
  });

  it("memilih avatar menandai aria-pressed dan memanggil onChange", () => {
    render(<Harness initial="human-f-01" />);
    fireEvent.click(screen.getByRole("button", { name: "Hewan" }));
    const pick = screen.getByRole("button", { name: "Avatar animal-03" });
    expect(pick.getAttribute("aria-pressed")).toBe("false");
    fireEvent.click(pick);
    expect(screen.getByRole("button", { name: "Avatar animal-03" }).getAttribute("aria-pressed")).toBe("true");
  });
});
