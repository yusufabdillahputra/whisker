#!/usr/bin/env python3
"""Bangun style DiceBear `whisker-critters`: remix Critters (DiceBear, CC0 1.0) menjadi kucing calico.

Perubahan dari Critters: hanya telinga kucing (telinga kiri oranye, kanan hitam), bentuk badan yang
membulat, belang calico di badan (dipotong mengikuti clipPath badan bawaan), dan warna dari token calico.
Pakai: cd design/tools && npm install && python3 build-critters-cat.py
Hasil: design/dicebear/whisker-critters.json
"""
import copy
import json
from pathlib import Path

HERE = Path(__file__).parent
src = json.loads((HERE / "node_modules/@dicebear/styles/src/critters.json").read_text())
style = copy.deepcopy(src)


def color(name):
    return {"type": "color", "name": name}


# 1. Telinga: kucing saja, kiri = patchA (oranye), kanan = patchB (hitam).
EARS = {
    "earsPointy": ("M7 40V28L5 2l16 24v14Z", "M41 40V28l2-26-16 24v14Z"),
}
top = style["components"]["top"]
keep_top = {}
for name, (left, right) in EARS.items():
    variant = copy.deepcopy(top["variants"][name])
    shadow = [e for e in variant["elements"] if e["name"] == "g"]
    keep_top[name] = {"elements": shadow + [
        {"name": "path", "type": "element", "attributes": {"d": left, "fill": color("earLeft")}},
        {"name": "path", "type": "element", "attributes": {"d": right, "fill": color("earRight")}},
    ]}
top["variants"] = keep_top
top.pop("probability", None)

# 2. Badan: hanya bentuk membulat, dan sisipkan komponen `calico` di grup yang ter-clip.
BODIES = ["dome", "round", "squat", "blob", "tilt", "peak", "bell"]
body = style["components"]["body"]
body["variants"] = {k: v for k, v in body["variants"].items() if k in BODIES}


def inject(elements):
    for e in elements:
        if e.get("attributes", {}).get("clip-path", "").startswith("url(#dbcrb-"):
            e.setdefault("children", []).insert(0, {"name": "calico", "type": "component"})
            return True
        if inject(e.get("children", [])):
            return True
    return False


for name, variant in body["variants"].items():
    assert inject(variant["elements"]), f"clip group tidak ditemukan di body {name}"


def blob(cx, cy, rx, ry, name, rot=0):
    return {"name": "ellipse", "type": "element", "attributes": {
        "cx": str(cx), "cy": str(cy), "rx": str(rx), "ry": str(ry), "fill": color(name),
        "transform": f"rotate({rot} {cx} {cy})"}}


# Koordinat kanvas 100; mata ada di sekitar x 27–73, y 36–50 → belang hitam dijauhkan dari mata.
style["components"]["calico"] = {"width": 100, "height": 100, "variants": {
    "classic": {"elements": [blob(20, 42, 22, 18, "patchA", -15), blob(84, 82, 18, 24, "patchB", 15), blob(46, 106, 20, 9, "patchA")]},
    "mask": {"elements": [blob(50, 26, 42, 9, "patchB"), blob(86, 70, 14, 22, "patchA", 10), blob(16, 92, 14, 12, "patchB", -15)]},
    "splash": {"elements": [blob(82, 46, 18, 16, "patchA", 15), blob(16, 78, 14, 18, "patchB", -20), blob(60, 104, 18, 8, "patchA")]},
}}

# 3. Wajah: mulut & mata yang ramah, tanpa pola putih bawaan (tak terlihat di bulu krem).
MOUTHS = ["catMouth", "smile", "tinySmile", "grin", "laugh", "ooh", "smirk", "blep", "tongue"]
style["components"]["mouth"]["variants"] = {k: v for k, v in style["components"]["mouth"]["variants"].items() if k in MOUTHS}
style["components"]["mouth"]["variants"]["catMouth"]["weight"] = 4
EYES = ["round", "dots", "bigPupils", "sideeye", "happy", "wink", "squint", "wide", "sleepy", "closedLine"]
style["components"]["eyes"]["variants"] = {k: v for k, v in style["components"]["eyes"]["variants"].items() if k in EYES}
style["components"]["pattern"]["probability"] = 0
style["components"]["animation"]["variants"]["none"]["weight"] = 1
for k in style["components"]["animation"]["variants"]:
    if k != "none":
        style["components"]["animation"]["variants"][k]["weight"] = 0

# 4. Warna calico (dari design/tokens/whisker.tokens.json).
style["colors"] = {
    "background": {"values": ["#F47806", "#CD6505", "#307E46", "#B83255", "#3C3731"]},
    "body": {"values": ["#FEF9F4"]},
    "accent": {"values": ["#F47806"]},
    "patchA": {"values": ["#F47806", "#CD6505", "#FEA065"], "notEqualTo": ["background"]},
    "patchB": {"values": ["#221E1A", "#3C3731"], "notEqualTo": ["background"]},
    "earLeft": {"values": ["#F47806", "#FEA065"], "notEqualTo": ["background"]},
    "earRight": {"values": ["#221E1A", "#3C3731"], "notEqualTo": ["background"]},
    "ink": {"values": ["#221E1A"]},
}
style["$comment"] = "Dibangun oleh design/tools/build-critters-cat.py dari Critters (DiceBear, CC0 1.0) — jangan edit manual."
style["meta"] = {
    "license": src["meta"]["license"],
    "creator": {"name": "Whisker (remix Critters oleh DiceBear)", "url": "https://github.com/yusufabdillahputra/whisker"},
    "source": {"name": "Whisker Critters", "url": "https://github.com/yusufabdillahputra/whisker"},
}
out = HERE.parent / "dicebear" / "whisker-critters.json"
out.write_text(json.dumps(style, indent=2, ensure_ascii=False) + "\n")
print("tulis", out)
