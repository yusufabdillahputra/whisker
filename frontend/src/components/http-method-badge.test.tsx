import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { HttpMethodBadge, httpMethodHue } from "./http-method-badge";

describe("httpMethodHue (Confirmation 10)", () => {
  it("GET sky · POST green · PUT/PATCH amber · DELETE red", () => {
    expect(httpMethodHue("GET")).toBe("sky");
    expect(httpMethodHue("POST")).toBe("green");
    expect(httpMethodHue("PUT")).toBe("amber");
    expect(httpMethodHue("PATCH")).toBe("amber");
    expect(httpMethodHue("DELETE")).toBe("red");
  });

  it("tidak peka huruf besar/kecil; method lain → gray", () => {
    expect(httpMethodHue("get")).toBe("sky");
    expect(httpMethodHue("Delete")).toBe("red");
    expect(httpMethodHue("HEAD")).toBe("gray");
    expect(httpMethodHue("OPTIONS")).toBe("gray");
  });
});

describe("HttpMethodBadge", () => {
  it("varian mono, label huruf besar, warna dari token hue", () => {
    const html = renderToStaticMarkup(<HttpMethodBadge method="post" />);
    expect(html).toContain(">POST<");
    expect(html).toContain("font-mono");
    expect(html).toContain("bg-badge-green");
    expect(html).toContain("text-badge-green-foreground");
    expect(html).toContain('data-hue="green"');
  });

  it("tiap method memakai hue-nya", () => {
    for (const [method, hue] of [
      ["GET", "sky"],
      ["PUT", "amber"],
      ["PATCH", "amber"],
      ["DELETE", "red"],
    ] as const) {
      expect(renderToStaticMarkup(<HttpMethodBadge method={method} />)).toContain(`bg-badge-${hue} `);
    }
  });
});
