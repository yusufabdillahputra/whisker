#!/usr/bin/env python3
"""Bangun style DiceBear `whisker-lorelei-cat`: kepala kucing calico + mata/alis/mulut dari Lorelei.

Lorelei (Lisa Wischofsky) berlisensi CC0 1.0, jadi boleh di-remix.
Pakai: cd design/tools && npm install && python3 build-lorelei-cat.py
Hasil: design/dicebear/whisker-lorelei-cat.json
"""
import json
from pathlib import Path

HERE = Path(__file__).parent
lorelei = json.loads((HERE / "node_modules/@dicebear/styles/src/lorelei.json").read_text())


def color(name):
    return {"type": "color", "name": name}


def el(name, children=None, **attrs):
    node = {"name": name, "type": "element", "attributes": {k.replace("_", "-"): v for k, v in attrs.items()}}
    if children:
        node["children"] = children
    return node


def comp(name, transform=None):
    node = {"name": name, "type": "component"}
    if transform:
        node["attributes"] = {"transform": transform}
    return node


LINE = "18"  # tebal garis ala Lorelei di kanvas 980
HEAD = dict(cx="540", cy="560", rx="330", ry="285")


def ear(points, inner):
    return [
        el("path", d=points, fill=color("earLeft" if "M210" in points or "M215" in points else "earRight"),
           stroke=color("outline"), stroke_width=LINE, stroke_linejoin="round"),
        el("path", d=inner, fill=color("nose"), opacity=".5"),
    ]


ears = {
    "pointy": {"elements": [
        el("path", d="M215 470 245 95 470 300Z", fill=color("earLeft"), stroke=color("outline"), stroke_width=LINE, stroke_linejoin="round"),
        el("path", d="M275 400 290 200 410 310Z", fill=color("nose"), opacity=".5"),
        el("path", d="M865 470 835 95 610 300Z", fill=color("earRight"), stroke=color("outline"), stroke_width=LINE, stroke_linejoin="round"),
        el("path", d="M805 400 790 200 670 310Z", fill=color("nose"), opacity=".5"),
    ]},
    "tilted": {"weight": 0.5, "elements": [
        el("path", d="M215 470 190 120 460 290Z", fill=color("earLeft"), stroke=color("outline"), stroke_width=LINE, stroke_linejoin="round"),
        el("path", d="M260 400 245 220 400 300Z", fill=color("nose"), opacity=".5"),
        el("path", d="M865 470 860 85 620 300Z", fill=color("earRight"), stroke=color("outline"), stroke_width=LINE, stroke_linejoin="round"),
        el("path", d="M810 400 805 190 680 310Z", fill=color("nose"), opacity=".5"),
    ]},
}


def blob(cx, cy, rx, ry, name, rot=0):
    return el("ellipse", cx=str(cx), cy=str(cy), rx=str(rx), ry=str(ry), fill=color(name), transform=f"rotate({rot} {cx} {cy})")


patches = {
    "classic": {"elements": [blob(330, 420, 190, 150, "patchA", -20), blob(800, 280, 170, 120, "patchB", 25), blob(640, 820, 120, 70, "patchA")]},
    "mask": {"elements": [blob(540, 290, 300, 100, "patchB"), blob(800, 600, 130, 170, "patchA", 10), blob(280, 740, 100, 80, "patchB", -15)]},
    "splash": {"elements": [blob(760, 480, 180, 160, "patchA", 15), blob(320, 290, 160, 95, "patchB", -25), blob(260, 660, 90, 70, "patchA")]},
}

nose = {"cat": {"elements": [
    el("path", d="M505 540h70l-35 40z", fill=color("nose"), stroke=color("outline"), stroke_width="12", stroke_linejoin="round"),
]}}

wl = [((330, 600), (120, 560)), ((325, 640), (100, 650)), ((335, 680), (130, 740))]
whisker_paths = []
for (x1, y1), (x2, y2) in wl:
    for a, b in (((x1, y1), (x2, y2)), ((1080 - x1, y1), (1080 - x2, y2))):
        whisker_paths.append(el("path", d=f"M{a[0]} {a[1]}L{b[0]} {b[1]}", stroke=color("outline"), stroke_width="12", stroke_linecap="round"))
whiskers = {"long": {"elements": whisker_paths}}

keep = ["eyes", "eyebrows", "mouth", "freckles"]
components = {k: lorelei["components"][k] for k in keep}
components["mouth"] = {**components["mouth"], "variants": {k: v for k, v in components["mouth"]["variants"].items() if k.startswith("happy")}}
components.update({
    "ears": {"width": 980, "height": 980, "variants": ears},
    "patches": {"width": 980, "height": 980, "variants": patches},
    "nose": {"width": 980, "height": 980, "variants": nose},
    "whiskers": {"width": 980, "height": 980, "variants": whiskers},
})

# Posisi wajah Lorelei (kanvas 980): eyes (366,403), eyebrows (371,297), mouth (430,573), freckles (348,514).
# Digeser sedikit agar wajah 3/4 Lorelei jatuh di tengah kepala kucing.
canvas = [
    el("defs", children=[el("clipPath", id="whisker-cat-head", children=[el("ellipse", **HEAD)])]),
    comp("ears"),
    el("ellipse", **HEAD, fill=color("fur")),
    el("g", clip_path="url(#whisker-cat-head)", children=[comp("patches")]),
    el("ellipse", **HEAD, fill="none", stroke=color("outline"), stroke_width=LINE),
    comp("eyebrows", "translate(338 300) scale(1.15)"),
    comp("eyes", "translate(333 410) scale(1.15)"),
    comp("freckles", "translate(330 550) scale(1.15)"),
    comp("nose"),
    comp("mouth", "translate(390 585) scale(1.15)"),
    comp("whiskers"),
]

palette = {
    "background": ["#FEEFE7", "#ECE4DA", "#E0FBE5", "#FEDBDF", "#FEDECB"],
    "fur": ["#FEF9F4"],
    "patchA": ["#F47806", "#CD6505", "#FEA065"],
    "patchB": ["#221E1A", "#3C3731", "#57514B"],
    "earLeft": ["#F47806", "#CD6505"],
    "earRight": ["#221E1A", "#3C3731"],
    "nose": ["#FA6786", "#FF98A8"],
    "outline": ["#221E1A"],
    "eyes": ["#221E1A"],
    "eyebrows": ["#221E1A"],
    "mouth": ["#221E1A"],
    "freckles": ["#CD6505"],
}

style = {
    "$schema": lorelei["$schema"],
    "$comment": "Dibangun oleh design/tools/build-lorelei-cat.py — jangan edit manual.",
    "meta": {
        "license": lorelei["meta"]["license"],
        "creator": {"name": "Whisker (remix Lorelei oleh Lisa Wischofsky)", "url": "https://github.com/yusufabdillahputra/whisker"},
        "source": {"name": "Whisker Lorelei Cat", "url": "https://github.com/yusufabdillahputra/whisker"},
    },
    "canvas": {"width": 980, "height": 980, "elements": canvas},
    "attributes": lorelei.get("attributes", {}),
    "components": components,
    "colors": {k: {"values": v} for k, v in palette.items()},
}
out = HERE.parent / "dicebear" / "whisker-lorelei-cat.json"
out.write_text(json.dumps(style, indent=2, ensure_ascii=False) + "\n")
print("tulis", out)
