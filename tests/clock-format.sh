#!/usr/bin/env bash
# The bar clock's patterns (bar/items/clock/format.js) for a few settings. Needs node; skips without it.
set -euo pipefail
f=$(dirname "$0")/../config/quickshell/.config/quickshell/bar/items/clock/format.js
command -v node >/dev/null || {
    echo "skipped: clock format (no node)"
    exit 0
}
node -e '
const src = require("fs").readFileSync(process.argv[1], "utf8").replace(".pragma library", "")
const F = new Function(src + "; return { patterns, ticksSeconds }")()
const d = { h24: true, seconds: false, date: true }
const eq = (got, want, what) => { if (got !== want) { console.error("xx " + what + ": " + JSON.stringify(got) + " != " + JSON.stringify(want)); process.exitCode = 1 } }
eq(F.patterns({}, d).all, "ddd d MMM'"'"'  '"'"'HH:mm", "defaults")
eq(F.patterns({ h24: false, seconds: true, date: false }, d).all, "h:mm:ss AP", "12-hour, seconds, no date")
eq(F.patterns({ time: false, weekday: "none", month: "number", year: true }, d).all, "d/M/yyyy", "numeric date")
eq(F.patterns({ first: "time", separator: "it'"'"'s " }, d).all, "HH:mm'"'"'it'"'"''"'"'s '"'"'ddd d MMM", "order and a quote in the separator")
eq(F.patterns({ custom: "ddd HH:mm", time: false }, d).all, "ddd HH:mm", "own pattern wins")
eq(F.patterns({ time: false, date: false }, d).all, "", "nothing")
eq(F.ticksSeconds("'"'"'secs'"'"' HH:mm"), false, "quoted s is text")
eq(F.ticksSeconds("HH:mm:ss"), true, "seconds tick")
if (!process.exitCode) console.log("ok: clock format")
' "$f"
