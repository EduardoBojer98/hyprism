pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Hyprism updates: the channel this copy follows and the new changes on it. Fetches in the background every few
// hours and when Settings > About opens; it only looks, `./install.sh update` pulls.
//   channel: "stable" (branch main), "dev" (branch develop) or "" (another branch, a tag, not a git copy)
Singleton {
    id: root

    property string branch: ""
    readonly property string channel: branch === "main" ? "stable" : branch === "develop" ? "dev" : ""
    property int count: 0          // new commits on the channel that this copy doesn't have
    property var changes: []       // their subjects, newest first (at most 8)
    property int ahead: 0          // local commits the channel doesn't have: update can't fast-forward
    property bool dirty: false     // edited tracked files: update won't pull
    property string error: ""      // why the last look failed
    property double checked: 0     // ms since epoch of the last look that reached the remote
    readonly property bool checking: look.running

    // at most every 5 minutes unless forced (the button)
    function refresh(force) { if (!look.running && (force || Date.now() - checked > 5 * 60 * 1000)) look.running = true }

    Process {
        id: look
        // the shell's files are links into the repo, so the repo is wherever shell.qml really lives
        command: ["sh", "-c", 'cd "$(dirname "$(readlink -f "$HOME/.config/quickshell/shell.qml")")" && cd "$(git rev-parse --show-toplevel)" || { echo "error=This copy isn\'t a git clone"; exit 0; }\n'
            + 'echo "branch=$(git rev-parse --abbrev-ref HEAD)"\n'
            + 'echo "dirty=$(git status --porcelain --untracked-files=no | head -1)"\n'
            + 'git rev-parse -q --verify "@{u}" >/dev/null || { echo "error=This branch follows no remote branch: pick a channel to follow one"; exit 0; }\n'
            + 'GIT_TERMINAL_PROMPT=0 timeout 60 git fetch -q 2>/dev/null && echo "fetched=1" || echo "error=Couldn\'t reach GitHub"\n'
            + 'echo "count=$(git rev-list --count HEAD..@{u})"; echo "ahead=$(git rev-list --count @{u}..HEAD)"\n'
            + 'git log -8 --format="change=%s" HEAD..@{u}']
        stdout: StdioCollector {
            onStreamFinished: {
                const o = { change: [] }
                for (const l of text.trim().split("\n")) {
                    const i = l.indexOf("=")
                    if (i < 0) continue
                    const k = l.slice(0, i), v = l.slice(i + 1)
                    if (k === "change") o.change.push(v); else o[k] = v
                }
                root.branch = o.branch ?? ""
                root.dirty = !!o.dirty
                root.count = Number(o.count ?? 0)
                root.ahead = Number(o.ahead ?? 0)
                root.changes = o.change
                root.error = o.error ?? ""
                if (o.fetched) root.checked = Date.now()
            }
        }
    }
    Timer { interval: 6 * 3600 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh(true) }
}
