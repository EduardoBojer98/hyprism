#!/usr/bin/env python3
"""Checks every built-in theme (and its light/dark half) in Quickshell's Themes.qml, without running the shell:
every colour token is there, text is readable (WCAG 2 contrast), and the terminal palette and wallpaper design
it names exist. Run by tests/lint.sh (CI). Exit 1 on any problem."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
THEMES = ROOT / "config/quickshell/.config/quickshell/Themes.qml"
GHOSTTY = ROOT / "config/ghostty/.config/ghostty/themes"
WALLPAPER = ROOT / "config/scripts/.local/bin/theme-wallpaper"
LOOK = ROOT / "config/hypr/.config/hypr/modules/look.lua"   # Hyprland's first-login defaults: the default theme's
KEYS = ["ground", "surface", "raised", "line", "text", "muted", "faint", "accent", "onAccent", "accent2", "ok", "warn", "err"]
# minimum contrast against the panel surface and the desktop ground: body text, secondary, faint (captions)
FLOOR = {"text": 7.0, "muted": 4.5, "faint": 3.0}


def luminance(hexc):
    c = [int(hexc[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    f = [v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
    return 0.2126 * f[0] + 0.7152 * f[1] + 0.0722 * f[2]


def contrast(a, b):
    x, y = luminance(a), luminance(b)
    return (max(x, y) + 0.05) / (min(x, y) + 0.05)


def on_accent(c):
    """What Themes.resolve() shows on an accent fill: the theme's choice, or the better of dark/white below 4.5."""
    if contrast(c["onAccent"], c["accent"]) >= 4.5:
        return c["onAccent"]
    dark = c["ground"] if luminance(c["ground"]) < 0.1 else "#141414"
    return dark if contrast(dark, c["accent"]) >= contrast("#ffffff", c["accent"]) else "#ffffff"


def colours(block):
    return dict(re.findall(r'(\w+): "(#[0-9a-fA-F]{6})"', block))


def main():
    src = THEMES.read_text()
    body = src[src.index("readonly property var builtIn"):src.index("readonly property var ids")]
    walls = set(re.findall(r"^\s+([a-z-]+)\)\s", WALLPAPER.read_text(), re.M))
    problems, count = [], 0
    for chunk in re.split(r'\n\s+\{\n\s+id: "', body)[1:]:
        tid = chunk.split('"', 1)[0]
        main_c = colours(re.search(r"\n\s+colour: \{(.*?)\}", chunk, re.S).group(1))
        alt = re.search(r"alt: \{(.*?)hypr:", chunk, re.S).group(1)
        halves = [(tid, main_c, re.search(r'term: "([^"]+)", wall: "([^"]+)"\s*$', chunk.strip(), re.M)),
                  (tid + " (other half)", dict(main_c, **colours(alt)), re.search(r'term: "([^"]+)", wall: "([^"]+)"', alt))]
        for name, c, tw in halves:
            count += 1
            missing = [k for k in KEYS if k not in c]
            if missing:
                problems.append(f"{name}: missing colours {missing}")
                continue
            # text sits on the ground too, unless the ground is the other kind of tone than the panels (Poster:
            # a dark desktop under paper panels and a paper bar), where it only ever sits on the surface
            grounds = ("surface", "ground") if contrast(c["ground"], c["surface"]) < 3 else ("surface",)
            for key, floor in FLOOR.items():
                for bg in grounds:
                    r = contrast(c[key], c[bg])
                    if r < floor:
                        problems.append(f"{name}: {key} on {bg} is {r:.2f}:1 (needs {floor})")
            r = contrast(on_accent(c), c["accent"])
            if r < 4.5:
                problems.append(f"{name}: text on the accent is {r:.2f}:1 (needs 4.5)")
            if not tw:
                problems.append(f"{name}: no term/wall")
                continue
            term, wall = tw.groups()
            if not (GHOSTTY / term).is_file():
                problems.append(f"{name}: terminal palette '{term}' missing in {GHOSTTY.relative_to(ROOT)}")
            if wall not in walls:
                problems.append(f"{name}: wallpaper design '{wall}' missing in theme-wallpaper")
    # look.lua's defaults (used before the shell first writes settings/theme.lua) must be the default theme's
    default = re.search(r'property string theme: "(\w+)"', (ROOT / "config/quickshell/.config/quickshell/ConfigData.qml").read_text()).group(1)
    block = body[body.index(f'id: "{default}"'):]
    hypr = re.search(r"\n\s+hypr: \{ (gapsIn.*?)\}", block, re.S).group(1)   # the theme's own, not alt's
    look = LOOK.read_text()
    for key, lua in (("gapsIn", "gaps_in"), ("gapsOut", "gaps_out"), ("border", "border_size"), ("rounding", "rounding")):
        want, got = re.search(key + r": (\d+)", hypr).group(1), re.search(lua + r" = (\d+)", look)
        if not got or got.group(1) != want:
            problems.append(f"look.lua default {lua} is {got.group(1) if got else 'missing'}, {default} has {want}")
    if re.search(r'active: \[([^\]]*)\]', hypr).group(1).replace(" ", "") != (re.search(r"active = \{([^}]*)\}", look).group(1).replace(" ", "")):
        problems.append(f"look.lua default active border colours differ from {default}'s")
    for p in problems:
        print("xx theme", p)
    if count < 2:
        print("xx theme: no themes found in Themes.qml (parser out of date?)")
        return 1
    if not problems:
        print(f"ok: {count} theme halves")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
