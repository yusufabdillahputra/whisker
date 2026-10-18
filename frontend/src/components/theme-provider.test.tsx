// @vitest-environment jsdom
import { act, cleanup, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { ThemeProvider, useTheme } from "./theme-provider";

function Probe() {
  const { preference, resolved, setPreference } = useTheme();
  return (
    <div>
      <span data-testid="pref">{preference}</span>
      <span data-testid="resolved">{resolved}</span>
      <button type="button" onClick={() => setPreference("dark")}>
        gelap
      </button>
    </div>
  );
}

const original = Object.getOwnPropertyDescriptor(window, "localStorage");

afterEach(() => {
  cleanup();
  if (original) Object.defineProperty(window, "localStorage", original);
  document.documentElement.className = "";
});

describe("ThemeProvider dengan storage diblokir", () => {
  beforeEach(() => {
    // Mode privat / kebijakan browser: sekadar membaca `window.localStorage` melempar SecurityError.
    Object.defineProperty(window, "localStorage", {
      configurable: true,
      get() {
        throw new DOMException("akses storage ditolak", "SecurityError");
      },
    });
  });

  it("tetap me-render (tidak blank) dan jatuh ke preferensi system", () => {
    render(
      <ThemeProvider>
        <Probe />
      </ThemeProvider>,
    );
    expect(screen.getByTestId("pref").textContent).toBe("system");
  });

  it("mengganti tema tetap berlaku di sesi ini walau tak tersimpan", () => {
    render(
      <ThemeProvider>
        <Probe />
      </ThemeProvider>,
    );
    act(() => screen.getByRole("button", { name: "gelap" }).click());
    expect(screen.getByTestId("resolved").textContent).toBe("dark");
    expect(document.documentElement.classList.contains("dark")).toBe(true);
  });
});
