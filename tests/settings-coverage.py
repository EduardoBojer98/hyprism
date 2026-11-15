#!/usr/bin/env python3
"""Every option in ConfigData.qml has a control in the Settings app and something that uses it.

A control: a Settings page (SettingsPage*.qml, SettingsBar*.qml, BarEditor.qml) names the section and key.
A user: any other shell file reads Config.<section>.<key> (or a short alias of the section), or a script or
Lua file names the key. Saved state that no one sets by hand is listed in STATE. Prints the gaps; exits 1 on any.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
QS = ROOT / "config/quickshell/.config/quickshell"
# kept by the shell itself, never set from a page
STATE = {"launcher.usage", "launcher.recent", "system.welcomed", "caffeine.on", "caffeine.minutes",
         "caffeine.endsAt", "idle.imported", "input.imported", "displays.imported", "monitorShare.imported", "version",
         "startup.apps", "bar.presets", "controlCenter.slidersOpen",
         "language.languages"}   # the Language page writes hypr/settings/language.lua itself


def keys():
    section, out = None, []
    for line in (QS / "ConfigData.qml").read_text().splitlines():
        m = re.match(r"    property JsonObject (\w+): JsonObject", line)
        if m:
            section = m.group(1)
            continue
        m = re.match(r"        property [\w<>]+ (\w+):", line)
        if m and section:
            out.append(f"{section}.{m.group(1)}")
    return out


def main():
    pages = [p for p in QS.rglob("*.qml") if re.match(r"(SettingsPage|SettingsBar|BarEditor|Welcome)", p.name)]
    others = [p for p in QS.rglob("*.qml") if p not in pages and p.name not in ("ConfigData.qml", "Config.qml")]
    others += [p for d in ("config/scripts", "config/hypr") for p in (ROOT / d).rglob("*") if p.is_file()]
    page_texts = [p.read_text(errors="ignore") for p in pages]
    other_text = "\n".join(p.read_text(errors="ignore") for p in others)
    gaps = []
    for k in keys():
        if k in STATE:
            continue
        section, key = k.split(".")
        # a page that works on this section (by name or Config.<section>) and names the key, in any form
        control = any((f'"{section}"' in t or f"Config.{section}" in t) and re.search(rf"\b{key}\b", t) for t in page_texts)
        user = re.search(rf"\b{key}\b", other_text)
        if not control:
            gaps.append(f"{k}: no control in Settings")
        if not user:
            gaps.append(f"{k}: nothing uses it")
    for g in gaps:
        print("xx", g)
    print(f"{len(keys())} options, {len(gaps)} gaps")
    return 1 if gaps else 0


if __name__ == "__main__":
    sys.exit(main())
