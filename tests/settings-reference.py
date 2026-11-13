#!/usr/bin/env python3
"""Writes docs/settings-reference.md from the defaults in QS/ConfigData.qml.

    python3 tests/settings-reference.py           write the file
    python3 tests/settings-reference.py --check   exit 1 when the committed file is out of date (CI)

Each `property <type> <name>: <default>   // comment` line becomes a table row; a comment is the text after
// on that line (nothing is invented for a setting without one). Defaults that span lines are shortened.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "config/quickshell/.config/quickshell/ConfigData.qml"
OUT = ROOT / "docs/settings-reference.md"

INTRO = """# Settings reference

Every setting, with its type, default and meaning. This file is generated from `ConfigData.qml` by
`tests/settings-reference.py`; do not edit it by hand (`tests/lint.sh` fails when it is out of date).

- The settings live in `~/.config/quickshell/settings.json`, one object per section below.
- The Settings app writes the file. The shell reloads it when you edit it by hand, and a missing key takes the
  default shown here.
- From a terminal: `qs ipc call config set <section> <key> '<json>'`, for example
  `qs ipc call config set appearance motion '"reduced"'`. Read one back with `qs ipc call config get <section> <key>`.
"""

PROP = re.compile(r"^(\s*)property\s+(\S+(?:<[^>]*>)?)\s+(\w+):\s*(.*)$")


def split_comment(text):
    """(code, comment) of one line: the // outside of quotes starts the comment."""
    quote = None
    for i, ch in enumerate(text):
        if quote:
            if ch == quote and text[i - 1] != "\\":
                quote = None
        elif ch in "\"'":
            quote = ch
        elif text.startswith("//", i):
            return text[:i].rstrip(), text[i + 2:].strip()
    return text.rstrip(), ""


def depth(code):
    return sum(code.count(c) for c in "([{") - sum(code.count(c) for c in ")]}")


def short(default):
    d = re.sub(r"\s+", " ", default).strip()
    if d.startswith("(") and d.endswith(")"):
        d = d[1:-1]
    return d if len(d) <= 60 else d[:57] + "..."


def parse(lines):
    sections = {}  # name -> [(name, type, default, comment)]
    current = "(top level)"
    i = 0
    while i < len(lines):
        line = lines[i]
        i += 1
        m = PROP.match(line)
        if not m:
            continue
        indent, typ, name, rest = len(m.group(1)), m.group(2), m.group(3), m.group(4)
        if typ == "JsonObject":
            current = name
            sections.setdefault(current, [])
            continue
        code, comment = split_comment(rest)
        while depth(code) > 0 and i < len(lines):  # a default over several lines: up to the matching bracket
            more, c2 = split_comment(lines[i])
            i += 1
            code += " " + more.strip()
            comment = comment or c2
        sections.setdefault(current if indent > 4 else "(top level)", []).append((name, typ, code, comment))
    return sections


def cell(text):
    return text.replace("|", "\\|")


def render(sections):
    out = [INTRO.rstrip("\n")]
    for name, rows in sections.items():
        if not rows:
            continue
        out.append(f"\n## {name}\n\n| Setting | Type | Default | What it does |\n| --- | --- | --- | --- |")
        for n, t, d, c in rows:
            out.append(f"| `{n}` | `{cell(t)}` | `{cell(short(d))}` | {cell(c)} |")
    return "\n".join(out) + "\n"


def main():
    text = render(parse(SRC.read_text().splitlines()))
    if "--check" in sys.argv:
        if not OUT.exists() or OUT.read_text() != text:
            print("xx docs/settings-reference.md is out of date: run python3 tests/settings-reference.py")
            return 1
        print("ok: settings reference is up to date")
        return 0
    OUT.write_text(text)
    print(f"wrote {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
