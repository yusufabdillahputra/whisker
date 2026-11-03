#!/usr/bin/env python3
"""Cek kontras WCAG 2.2 untuk token semantic Whisker.

Pakai: python3 design/tools/check-contrast.py [path/ke/whisker.tokens.json]
Keluar dengan kode 1 bila ada pasangan yang gagal.
"""
import json
import re
import sys
from pathlib import Path

TOKENS = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parents[1] / "tokens" / "whisker.tokens.json"

# (teks/ikon, latar, rasio minimum). 4.5 = teks normal (SC 1.4.3), 3.0 = komponen UI & fokus (SC 1.4.11).
PAIRS = [
    ("foreground", "background", 4.5),
    ("foreground", "card", 4.5),
    ("primaryForeground", "primary", 4.5),
    ("secondaryForeground", "secondary", 4.5),
    ("mutedForeground", "muted", 4.5),
    ("mutedForeground", "background", 4.5),
    ("destructiveForeground", "destructive", 4.5),
    ("errorForeground", "error", 4.5),
    ("successForeground", "success", 4.5),
    ("primary", "background", 3.0),
    ("input", "background", 3.0),
    ("ring", "background", 3.0),
]


def resolve(doc, value):
    m = re.fullmatch(r"\{(.+)\}", value)
    if not m:
        return value
    node = doc
    for part in m.group(1).split("."):
        node = node[part]
    return resolve(doc, node["$value"])


def luminance(hex_color):
    channels = [int(hex_color[i : i + 2], 16) / 255 for i in (1, 3, 5)]
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]


def ratio(a, b):
    hi, lo = sorted([luminance(a), luminance(b)], reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def main():
    doc = json.loads(TOKENS.read_text())
    failed = 0
    for theme, tokens in doc["semantic"].items():
        if theme.startswith("$"):
            continue
        for fg, bg, minimum in PAIRS:
            a, b = resolve(doc, tokens[fg]["$value"]), resolve(doc, tokens[bg]["$value"])
            r = ratio(a, b)
            ok = r >= minimum
            failed += not ok
            print(f"{'OK  ' if ok else 'GAGAL'} {theme:5} {fg:22} {a} di atas {bg:11} {b}  {r:5.2f}:1 (min {minimum})")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
