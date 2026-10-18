// @vitest-environment jsdom
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import type { AnchorHTMLAttributes, Ref } from "react";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import type { UserProps } from "@/types/generated/UserProps";
import { AccountMenu } from "./account-menu";

const post = vi.fn();

// Router & Link Inertia di luar aplikasi Inertia: cukup `<a href>` dan pencatat `router.post`.
vi.mock("@inertiajs/react", () => ({
  router: { post: (...args: unknown[]) => post(...args) },
  Link: ({ ref, ...props }: AnchorHTMLAttributes<HTMLAnchorElement> & { ref?: Ref<HTMLAnchorElement> }) => (
    <a ref={ref} {...props} />
  ),
}));

beforeAll(() => {
  // Radix Popper butuh ResizeObserver (tidak ada di jsdom).
  globalThis.ResizeObserver ??= class {
    observe() {}
    unobserve() {}
    disconnect() {}
  };
});

afterEach(() => {
  cleanup();
  post.mockReset();
});

function user(role: UserProps["role"]): UserProps {
  return {
    id: "0199-uuid",
    email: "ani@example.test",
    displayName: "Ani Uji",
    avatarKey: "animal-01",
    role,
    mustChangePassword: false,
  };
}

function openMenu(role: UserProps["role"]) {
  render(<AccountMenu user={user(role)} />);
  const trigger = screen.getByRole("button", { name: "Menu akun Ani Uji" });
  fireEvent.keyDown(trigger, { key: "Enter" });
  return screen.getByRole("menu");
}

describe("AccountMenu", () => {
  it("tombol akun memuat avatar user (alt = nama tampilan)", () => {
    render(<AccountMenu user={user("member")} />);
    const trigger = screen.getByRole("button", { name: "Menu akun Ani Uji" });
    expect(trigger.querySelector("img")?.getAttribute("src")).toBe("/avatars/animal-01.svg");
  });

  it("memuat item Lisensi pihak ketiga yang menaut ke /third-party-notices.txt (ruling K6)", () => {
    openMenu("member");
    const item = screen.getByRole("menuitem", { name: "Lisensi pihak ketiga" });
    expect(item.getAttribute("href")).toBe("/third-party-notices.txt");
  });

  it("member: Tokens, Account, Lisensi, Logout — tanpa Admin Users", () => {
    openMenu("member");
    const items = screen.getAllByRole("menuitem");
    expect(items.map((i) => i.textContent)).toEqual(["Tokens", "Account", "Lisensi pihak ketiga", "Logout"]);
    expect(screen.getByRole("menuitem", { name: "Tokens" }).getAttribute("href")).toBe("/account/tokens");
    expect(screen.getByRole("menuitem", { name: "Account" }).getAttribute("href")).toBe("/account/profile");
    expect(screen.queryByRole("menuitem", { name: "Admin Users" })).toBeNull();
  });

  it("admin: Admin Users → /account/admin; identitas user di kepala menu", () => {
    const menu = openMenu("admin");
    expect(screen.getByRole("menuitem", { name: "Admin Users" }).getAttribute("href")).toBe("/account/admin");
    expect(menu.textContent).toContain("Ani Uji");
    expect(menu.textContent).toContain("Admin");
  });

  it("Logout → router.post('/logout')", () => {
    openMenu("member");
    fireEvent.click(screen.getByRole("menuitem", { name: "Logout" }));
    expect(post).toHaveBeenCalledWith("/logout");
  });
});
