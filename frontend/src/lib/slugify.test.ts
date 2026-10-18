import { describe, expect, it } from "vitest";
import vectors from "../../../crates/whisker-core/tests/fixtures/slug_vectors.json";
import { previewSlug, slugCandidate, slugify } from "./slugify";

describe("slugify (vektor bersama dengan Rust)", () => {
  it("fixture tidak kosong", () => {
    expect(vectors.slugify.length).toBeGreaterThan(0);
    expect(vectors.candidate.length).toBeGreaterThan(0);
  });

  it.each(vectors.slugify)("slugify($name) = $expected", ({ name, expected }) => {
    expect(slugify(name)).toBe(expected);
  });

  it.each(vectors.candidate)(
    "slugCandidate($base, $attempt) = $expected",
    ({ base, attempt, expected }) => {
      expect(slugCandidate(base, attempt)).toBe(expected);
    },
  );
});

describe("previewSlug", () => {
  it("tanpa tabrakan memakai slug dasar", () => {
    expect(previewSlug("Catatan Kerja", [])).toBe("catatan-kerja");
  });
  it("tabrakan menghasilkan -2", () => {
    expect(previewSlug("Catatan Kerja", ["catatan-kerja"])).toBe("catatan-kerja-2");
  });
  it("-2 terpakai menghasilkan -3", () => {
    expect(previewSlug("Catatan Kerja", ["catatan-kerja", "catatan-kerja-2"])).toBe(
      "catatan-kerja-3",
    );
  });
});
