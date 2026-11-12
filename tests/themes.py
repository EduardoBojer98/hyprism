#!/usr/bin/env python3
"""Checks every shipped theme folder (themes/<id>/theme.json), both halves:

  - all the colours are there, and text is readable (WCAG): body text 7:1, secondary 4.5:1, captions 3:1
    against the panel and the desktop; text on the accent 4.5:1
  - things you must be able to see but not read (WCAG 3:1 for interface parts): the accent, the second accent
    and the ok / warn / error colours against the panel
  - the bar's text against the bar's own fill
  - the terminal palette is complete; its text is 7:1 on its background and the six colours 3:1
  - the wallpaper exists (a picture in the folder, or a recipe in wallpaper.sh)
  - the first-login defaults in Hyprland's look.lua match the default theme

Run by tests/lint.sh (CI) or by hand: python3 tests/themes.py
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
THEMES = ROOT / "config/themes/.local/share/hyprism/themes"
LOOK = ROOT / "config/hypr/.config/hypr/modules/look.lua"
CONFIG = ROOT / "config/quickshell/.config/quickshell/ConfigData.qml"

KEYS = ["ground", "surface", "raised", "line", "text", "muted", "faint", "accent", "onAccent", "accent2", "ok", "warn", "err"]
TEXT = {"text": 7.0, "muted": 4.5, "faint": 3.0}      # must be readable
SEEN = ["accent", "accent2", "ok", "warn", "err"]       # must be visible (3:1)
TERM_KEYS = ["background", "foreground", "cursor", "cursorText", "selection", "selectionText"]
HEX = re.compile(r"^#[0-9a-fA-F]{6}$")


def luminance(hexc):
    c = [int(hexc[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    f = [v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
    return 0.2126 * f[0] + 0.7152 * f[1] + 0.0722 * f[2]


def contrast(a, b):
    x, y = luminance(a), luminance(b)
    return (max(x, y) + 0.05) / (min(x, y) + 0.05)


def on_accent(c):
    """What the shell shows on an accent fill: the theme's choice, or the better of dark/white below 4.5."""
    if contrast(c["onAccent"], c["accent"]) >= 4.5:
        return c["onAccent"]
    dark = c["ground"] if luminance(c["ground"]) < 0.1 else "#141414"
    return dark if contrast(dark, c["accent"]) >= contrast("#ffffff", c["accent"]) else "#ffffff"


def bar_pair(c, fill):
    """The bar's text colour and what it sits on, for the theme's bar fill (Theme.qml barInk / barGround)."""
    if fill == "ink":
        return c["ground"] if luminance(c["text"]) > 0.5 else c["surface"], c["text"]
    if fill == "ground":
        return c["text"], c["ground"]
    return c["text"], c["surface"]          # surface, glass (the panel colour behind the blur), none


def check_half(name, c, term, wall, folder, bar_fill, problems):
    missing = [k for k in KEYS if not HEX.match(str(c.get(k, "")))]
    if missing:
        problems.append(f"{name}: missing or bad colours {missing}")
        return
    # text sits on the desktop too, unless the desktop is the other kind of tone than the panels (Poster: a dark
    # desktop under paper panels and a paper bar), where it only ever sits on the panel
    grounds = ("surface", "ground") if contrast(c["ground"], c["surface"]) < 3 else ("surface",)
    for key, floor in TEXT.items():
        for bg in grounds:
            r = contrast(c[key], c[bg])
            if r < floor:
                problems.append(f"{name}: {key} on {bg} is {r:.2f}:1 (needs {floor})")
    r = contrast(on_accent(c), c["accent"])
    if r < 4.5:
        problems.append(f"{name}: text on the accent is {r:.2f}:1 (needs 4.5)")
    for key in SEEN:
        r = contrast(c[key], c["surface"])
        if r < 3:
            problems.append(f"{name}: {key} on surface is {r:.2f}:1 (needs 3 to be seen)")
    ink, ground = bar_pair(c, bar_fill)
    r = contrast(ink, ground)
    if r < 4.5:
        problems.append(f"{name}: bar text on the bar ({bar_fill}) is {r:.2f}:1 (needs 4.5)")

    bad = [k for k in TERM_KEYS if not HEX.match(str(term.get(k, "")))]
    pal = term.get("palette", [])
    if bad or len(pal) != 16 or not all(HEX.match(str(p)) for p in pal):
        problems.append(f"{name}: terminal palette incomplete ({bad or 'needs 16 colours'})")
    else:
        r = contrast(term["foreground"], term["background"])
        if r < 7:
            problems.append(f"{name}: terminal text is {r:.2f}:1 on its background (needs 7)")
        for i in range(1, 7):
            r = contrast(pal[i], term["background"])
            if r < 3:
                problems.append(f"{name}: terminal colour {i} ({pal[i]}) is {r:.2f}:1 on its background (needs 3)")

    recipe = folder / "wallpaper.sh"
    has_picture = any((folder / f"{wall}.{ext}").is_file() for ext in ("png", "jpg", "jpeg", "webp"))
    has_recipe = recipe.is_file() and re.search(rf"^\s+{re.escape(wall)}\)", recipe.read_text(), re.M)
    if not (has_picture or has_recipe):
        problems.append(f"{name}: no wallpaper '{wall}' (a picture {wall}.png in the folder, or a recipe in wallpaper.sh)")


def main():
    problems, count, themes = [], 0, {}
    for folder in sorted(THEMES.iterdir()):
        if not (folder / "theme.json").is_file():
            continue
        try:
            t = json.loads((folder / "theme.json").read_text())
        except ValueError as e:
            problems.append(f"{folder.name}: theme.json doesn't parse: {e}")
            continue
        if folder.name.startswith("_"):
            continue                       # the template must parse; it isn't a theme
        themes[folder.name] = t
        if not re.match(r"^[a-z0-9]+(-[a-z0-9]+)*$", folder.name):
            problems.append(f"{folder.name}: folder names are lower-case letters, digits and dashes")
        for part in ("name", "about", "colour", "alt", "font", "shape", "bar", "dock", "popup", "motion", "launcher", "notify", "hypr", "lock", "term", "wall"):
            if part not in t:
                problems.append(f"{folder.name}: theme.json has no \"{part}\"")
        if any(p.startswith(folder.name + ":") for p in problems):
            continue
        fill = t["bar"].get("fill", "surface")
        check_half(folder.name, t["colour"], t["term"], t["wall"], folder, fill, problems)
        alt = t["alt"]
        check_half(folder.name + " (other half)", dict(t["colour"], **alt.get("colour", {})), alt.get("term", {}), alt.get("wall", ""), folder, fill, problems)
        count += 2

    # look.lua's defaults (used before the shell first writes settings/theme.lua) must be the default theme's
    default = re.search(r'property string theme: "([\w-]+)"', CONFIG.read_text()).group(1)
    if default not in themes:
        problems.append(f"the default theme '{default}' (ConfigData.qml) has no folder")
    else:
        hypr, look = themes[default]["hypr"], LOOK.read_text()
        for key, lua in (("gapsIn", "gaps_in"), ("gapsOut", "gaps_out"), ("border", "border_size"), ("rounding", "rounding")):
            got = re.search(lua + r" = (\d+)", look)
            if not got or int(got.group(1)) != hypr[key]:
                problems.append(f"look.lua default {lua} is {got.group(1) if got else 'missing'}, {default} has {hypr[key]}")
        active = re.findall(r'"([0-9a-fA-F]{8})"', re.search(r"active = \{([^}]*)\}", look).group(1))
        if active != hypr["active"]:
            problems.append(f"look.lua default active border colours differ from {default}'s")

    for p in problems:
        print("xx theme", p)
    if count < 2:
        print(f"xx theme: no theme folders found in {THEMES.relative_to(ROOT)}")
        return 1
    if not problems:
        print(f"ok: {count} theme halves")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
