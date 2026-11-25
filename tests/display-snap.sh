#!/usr/bin/env bash
# Screen snapping in Settings > Displays (DisplaySnap.js): edge to edge, never overlapping. Needs node; skips without it.
set -euo pipefail
f=$(dirname "$0")/../config/quickshell/.config/quickshell/DisplaySnap.js
command -v node >/dev/null || {
    echo "skipped: display snap (no node)"
    exit 0
}
node -e '
const src = require("fs").readFileSync(process.argv[1], "utf8").replace(".pragma library", "")
const S = new Function(src + "; return { snapPosition, settle }")()
const eq = (got, want, what) => { if (JSON.stringify(got) !== JSON.stringify(want)) { console.error("xx " + what + ": " + JSON.stringify(got) + " != " + JSON.stringify(want)); process.exitCode = 1 } }
// the owner'"'"'s desk: a 2560x1440 monitor, the laptop (1600x1000 at scale 1.2) below it
const mon = { x: 0, y: 0, w: 2560, h: 1440 }, lap = { w: 1600, h: 1000 }
eq(S.snapPosition(lap, 470, 1500, [mon], 0), { x: 470, y: 1440 }, "dropped below with a gap: clings to the bottom edge")
eq(S.snapPosition(lap, 470, 1300, [mon], 0), { x: 470, y: 1440 }, "dropped overlapping: pushed out to the nearest edge")
eq(S.snapPosition(lap, 490, 1440, [mon], 30), { x: 480, y: 1440 }, "near the centre: lines up with it")
eq(S.snapPosition(lap, 20, 1440, [mon], 30), { x: 0, y: 1440 }, "near the left end: lines up with it")
eq(S.snapPosition(lap, 3000, 200, [mon], 0), { x: 2560, y: 200 }, "off to the right: against the right edge")
eq(S.snapPosition(lap, 5000, 5000, [mon], 0), { x: 2460, y: 1440 }, "far corner: keeps a stretch of shared edge")
eq(S.snapPosition(lap, 70, 80, [], 30), { x: 70, y: 80 }, "alone: stays where dropped")
// three in a row: the free side is taken, never an overlap
const a = { x: 0, y: 0, w: 1000, h: 800 }, b = { x: 1000, y: 0, w: 1000, h: 800 }
const p = S.snapPosition({ w: 1000, h: 800 }, 900, 0, [a, b], 0)
eq([a, b].some(q => p.x < q.x + q.w && q.x < p.x + 1000 && p.y < q.y + q.h && q.y < p.y + 800), false, "never overlaps either screen")
// settle: the laptop grew (scale 1 now, 1920x1200): the monitor above stays touching, no overlap
eq(S.settle({ lap: { x: 480, y: 1440, w: 1920, h: 1200 }, mon: { x: 0, y: 0, w: 2560, h: 1440 } }, "lap"),
   { lap: { x: 480, y: 1440 }, mon: { x: 0, y: 0 } }, "settle keeps screens that already touch")
eq(S.settle({ lap: { x: 0, y: 0, w: 1600, h: 1000 }, mon: { x: 0, y: 0, w: 2560, h: 1440 } }, "lap"),
   { lap: { x: 0, y: 0 }, mon: { x: 0, y: 1000 } }, "settle moves an overlapping screen to the nearest side of the anchor")
eq(S.settle({ a: { x: 0, y: 0, w: 1000, h: 800 }, c: { x: 2000, y: 0, w: 1000, h: 800 } }, "a"),
   { a: { x: 0, y: 0 }, c: { x: 1000, y: 0 } }, "settle closes a gap")
if (!process.exitCode) console.log("ok: display snap")
' "$f"
