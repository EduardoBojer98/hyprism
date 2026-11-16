pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Updates waiting: Hyprism's (the channel this copy follows and the new changes on it) and the system's (packages,
// AUR, Flatpak), for Settings > About and the bar's Updates item. It only looks; `./install.sh update` installs.
// Hyprism: git fetch every 6 hours and when About opens. System: every hour (checkupdates on Arch, which never
// touches the real package database; dnf check-update on Fedora).
//   channel: "stable" (branch main), "dev" (branch develop) or "" (another branch, a tag, not a git copy)
//   qs ipc call updates refresh      look again now (the update terminal calls it when it is done)
Singleton {
    id: root

    property var packages: []      // "name old -> new" (Arch) or "name.arch version repo" (Fedora)
    property var aur: []
    property var flatpaks: []
    property string systemError: ""
    readonly property int system: packages.length + aur.length + flatpaks.length
    readonly property int total: system + count
    readonly property bool checkingSystem: sysLook.running
    // one line for a tooltip: "12 packages · 1 AUR · 2 Flatpak · 3 Hyprism changes"
    readonly property string summary: [[packages.length, "package"], [aur.length, "AUR"], [flatpaks.length, "Flatpak"], [count, "Hyprism change"]]
        .filter(p => p[0] > 0).map(p => p[0] + " " + p[1] + (p[0] > 1 && p[1].endsWith("e") ? "s" : "")).join(" · ")

    function refreshSystem() { if (!sysLook.running) sysLook.running = true }
    function refreshAll() { refresh(true); refreshSystem() }
    // the whole update (system, Flatpak, Hyprism) in a terminal, then a fresh look
    function install() {
        Quickshell.execDetached(["ghostty", "+new-window", "-e", "sh", "-c",
            'cd "$(dirname "$(readlink -f "$HOME/.config/quickshell/shell.qml")")" && cd "$(git rev-parse --show-toplevel)" && ./install.sh update; '
            + 'qs ipc call updates refresh >/dev/null 2>&1; echo; read -p "Press Enter to close" _'])
    }

    IpcHandler {
        target: "updates"
        function refresh(): void { root.refreshAll() }
    }

    Process {
        id: sysLook
        // one line per update, "pkg=", "aur=" or "flatpak=", or "error=" when a source couldn't be asked
        command: ["sh", "-c", 'if command -v checkupdates >/dev/null; then u=$(checkupdates 2>/dev/null); [ $? = 1 ] && echo "error=checkupdates failed (offline?)"; '
            + 'elif command -v dnf >/dev/null; then u=$(dnf check-update -q 2>/dev/null | awk \'NF == 3 && $1 ~ /\\./\'); fi\n'
            + '[ -n "$u" ] && printf "%s\\n" "$u" | sed "s/^/pkg=/"\n'
            + 'h=$(command -v paru || command -v yay) && "$h" -Qua 2>/dev/null | sed "s/^/aur=/"\n'
            + 'command -v flatpak >/dev/null && flatpak remote-ls --updates --columns=application 2>/dev/null | sed "s/^/flatpak=/"\n'
            + 'true']
        stdout: StdioCollector {
            onStreamFinished: {
                const o = { pkg: [], aur: [], flatpak: [], error: [] }
                for (const l of text.split("\n")) {
                    const i = l.indexOf("=")
                    if (i > 0 && o[l.slice(0, i)]) o[l.slice(0, i)].push(l.slice(i + 1))
                }
                root.packages = o.pkg
                root.aur = o.aur
                root.flatpaks = o.flatpak
                root.systemError = o.error.join(". ")
            }
        }
    }
    Timer { interval: 3600 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refreshSystem() }

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
