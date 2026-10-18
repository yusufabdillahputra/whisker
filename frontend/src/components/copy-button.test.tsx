// @vitest-environment jsdom
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

const toast = vi.hoisted(() => ({ success: vi.fn(), error: vi.fn() }));
vi.mock("sonner", () => ({ toast }));

import { CopyButton } from "./copy-button";

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

describe("CopyButton", () => {
  it("menyalin teks ke clipboard dan menampilkan toast", async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.defineProperty(navigator, "clipboard", { value: { writeText }, configurable: true });
    render(<CopyButton text="rahasia" label="Salin" />);
    fireEvent.click(screen.getByRole("button", { name: "Salin" }));
    await waitFor(() => expect(writeText).toHaveBeenCalledWith("rahasia"));
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith("Token disalin"));
  });

  it("menampilkan toast error bila clipboard gagal", async () => {
    const writeText = vi.fn().mockRejectedValue(new Error("ditolak"));
    Object.defineProperty(navigator, "clipboard", { value: { writeText }, configurable: true });
    render(<CopyButton text="x" label="Salin" />);
    fireEvent.click(screen.getByRole("button", { name: "Salin" }));
    await waitFor(() => expect(toast.error).toHaveBeenCalled());
  });
});
