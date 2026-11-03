#!/usr/bin/env python3
"""Generator token warna → Dart untuk whisker_flutter.

Membaca design/tokens/whisker.tokens.json dan menulis
whisker_flutter/lib/app/tokens.g.dart. Jalankan ulang setiap token berubah:

    python3 design/tools/gen-dart-tokens.py
"""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "design/tokens/whisker.tokens.json"
OUT = ROOT / "whisker_flutter/lib/app/tokens.g.dart"


def main() -> None:
    data = json.loads(SRC.read_text())
    scales = {k: v for k, v in data["color"].items() if not k.startswith("$")}

    def resolve(value: str) -> str:
        m = re.fullmatch(r"\{color\.(\w+)\.(\d+)\}", value)
        if m:
            return scales[m.group(1)][m.group(2)]["$value"]
        return value

    def dart_color(hexv: str) -> str:
        h = hexv.lstrip("#").upper()
        if len(h) == 6:
            h = "FF" + h
        elif len(h) == 8:  # RRGGBBAA → AARRGGBB
            h = h[6:] + h[:6]
        return f"Color(0x{h})"

    lines = [
        "// GENERATED oleh design/tools/gen-dart-tokens.py — jangan diedit manual.",
        "// Sumber: design/tokens/whisker.tokens.json",
        "",
        "import 'dart:ui';",
        "",
        "/// Skala warna calico mentah.",
        "abstract final class WhiskerTokens {",
    ]
    for scale, steps in scales.items():
        for step, tok in steps.items():
            if step.startswith("$"):
                continue
            lines.append(f"  static const {scale}{step} = {dart_color(tok['$value'])};")
    lines.append("}")
    lines.append("")

    semantic_keys = [k for k in data["semantic"]["light"] if not k.startswith("$")]
    lines.append("/// Warna semantik untuk satu brightness.")
    lines.append("final class WhiskerSemantic {")
    for k in semantic_keys:
        lines.append(f"  final Color {k};")
    lines.append("")
    lines.append("  const WhiskerSemantic({")
    for k in semantic_keys:
        lines.append(f"    required this.{k},")
    lines.append("  });")
    for mode in ("light", "dark"):
        lines.append("")
        lines.append(f"  static const {mode} = WhiskerSemantic(")
        for k in semantic_keys:
            val = data["semantic"][mode][k]["$value"]
            ref = re.fullmatch(r"\{color\.(\w+)\.(\d+)\}", val)
            expr = f"WhiskerTokens.{ref.group(1)}{ref.group(2)}" if ref else dart_color(val)
            lines.append(f"    {k}: {expr},")
        lines.append("  );")
    lines.append("}")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines) + "\n")
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
