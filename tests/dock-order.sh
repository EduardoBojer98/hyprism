#!/usr/bin/env bash
# The dock's item order (DockOrder.arrange, Settings > Dock > Order): saved places kept, new items at their usual
# place, apps refilled in pinned order after a drag on the dock. Needs node; skips without it.
set -euo pipefail
f=$(dirname "$0")/../config/quickshell/.config/quickshell/DockOrder.qml
command -v node >/dev/null || {
    echo "skipped: dock order (no node)"
    exit 0
}
node -e '
const src = require("fs").readFileSync(process.argv[1], "utf8")
const arrange = new Function(src.match(/function arrange\([\s\S]*?\n    \}\n/)[0] + "; return arrange")()
const eq = (got, want, what) => { if (JSON.stringify(got) !== JSON.stringify(want)) { console.error("xx " + what + ": " + JSON.stringify(got) + " != " + JSON.stringify(want)); process.exitCode = 1 } }
eq(arrange([], true, ["a", "b"], ["clock"]), ["launcher", "app:a", "app:b", "running", "widget:clock"], "nothing saved: the usual order")
eq(arrange(["widget:clock", "app:a", "launcher", "running", "app:b"], true, ["a", "b"], ["clock"]), ["widget:clock", "app:a", "launcher", "running", "app:b"], "a saved order is kept")
eq(arrange(["widget:clock", "app:a", "launcher", "running", "app:b"], true, ["b", "a"], ["clock"]), ["widget:clock", "app:b", "launcher", "running", "app:a"], "a drag on the dock swaps the apps in their places")
eq(arrange(["running", "app:a", "launcher"], false, ["a", "c"], []), ["running", "app:a", "app:c"], "launcher off; a new app after the last app")
eq(arrange(["app:x", "running"], true, ["a"], ["date"]), ["launcher", "app:a", "running", "widget:date"], "unpinned dropped, new ones placed")
eq(arrange(["widget:w", "app:a", "running", "launcher"], true, ["a", "b"], ["w"]), ["widget:w", "app:a", "app:b", "running", "launcher"], "a new app joins the last app, not the launcher")
eq(arrange(["widget:w", "launcher"], true, ["a"], ["w"]), ["widget:w", "launcher", "app:a", "running"], "no apps yet: after the launcher")
if (!process.exitCode) console.log("ok: dock order")
' "$f"
