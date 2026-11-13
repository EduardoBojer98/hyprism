import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import qs

// The dock inside the bar: pinned apps, then other running ones; a mark under each open app,
// the accent under the focused one. Click: bring it up (again: its next window) or start it;
// middle-click: a new window.
Item {
    id: apps
    required property var bar
    readonly property int count: DesktopEntries.applications.values.length   // lookups re-run once apps have loaded
    function entryFor(appId) { return count ? DesktopEntries.heuristicLookup(appId) : null }
    readonly property var running: Hyprland.toplevels.values.filter(t => t.wayland && t.workspace?.monitor === bar.monitor)
    // like the floating dock: launchers, then (unless Settings > Dock > Combine) each open window after a rule
    readonly property bool combine: Config.dock.combine
    readonly property var pinned: count ? Array.from(Config.dock.pinned).map(id => DesktopEntries.byId(id)).filter(e => e) : []
    readonly property var cells: {
        const out = pinned.map(e => ({ entry: e, win: null }))
        if (combine) {
            for (const t of running) { const e = entryFor(t.wayland.appId); if (e && !out.some(x => x.entry.id === e.id)) out.push({ entry: e, win: null }) }
        } else if (Config.dock.showRunning && running.length) {
            out.push({ rule: true })
            for (const t of running) out.push({ entry: entryFor(t.wayland.appId), win: t })
        }
        return out
    }
    // a window minimised from the dock (parked on special:minimized) comes back to this screen's workspace first
    function bring(t) {
        if (t.workspace?.name !== "special:minimized") { t.wayland.activate(); return }
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.window.move({ workspace = "${bar.monitor?.activeWorkspace?.id ?? 1}", window = "address:0x${String(t.address).replace(/^0x/, "")}" })`])
    }
    readonly property int icon: Math.max(16, Math.min(Math.round(bar.thickness * 0.62), 30))
    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight
    Grid {
        id: grid
        columns: bar.vertical ? 1 : Math.max(1, visibleChildren.filter(c => c.width > 0).length)
        spacing: 2
        Repeater {
            model: apps.cells
            BarItem {
                id: app
                required property var modelData
                required property int index
                readonly property bool rule: modelData.rule === true
                readonly property var entry: modelData.entry ?? null
                readonly property var win: modelData.win ?? null
                // a launcher's own windows (it focuses them); a window cell is just its window
                readonly property var wins: win ? [win] : apps.running.filter(t => entry && apps.entryFor(t.wayland.appId)?.id === entry.id)
                readonly property bool marked: win !== null || (apps.combine && wins.length > 0)
                vertical: apps.bar.vertical
                pad: rule ? 3 : 4
                interactive: !rule
                active: marked && wins.some(t => t.activated)
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onPressed: button => {
                    if (win) { if (button === Qt.MiddleButton) win.wayland.close(); else apps.bring(win); return }
                    if (button === Qt.MiddleButton || wins.length === 0) { entry?.execute(); return }
                    const i = wins.findIndex(t => t.activated)
                    apps.bring(wins[(i + 1) % wins.length])
                }
                // words voices (terminal themes) name the apps instead, like tmux's window list
                readonly property bool asText: apps.bar.words && !apps.bar.vertical
                color: asText && active ? Theme.accent : active ? pressedColor : hovered ? hover : "transparent"
                radius: asText ? 0 : Theme.radiusSmall
                Rectangle {   // the rule between launchers and open windows
                    visible: app.rule
                    width: apps.bar.vertical ? apps.icon * 0.6 : 1
                    height: apps.bar.vertical ? 1 : apps.icon * 0.6
                    color: Qt.alpha(apps.bar.tone, 0.3)
                }
                IconImage { visible: !app.rule && !app.asText; implicitSize: apps.icon; source: Quickshell.iconPath(app.entry?.icon ?? "", "application-x-executable") }
                // an open window can say what it is (Settings > Dock > Open windows in the bar): its app or its title
                readonly property string label: !win || apps.bar.vertical ? "" : Config.dock.barLabels === "name" ? (entry?.name ?? win.wayland?.appId ?? "")
                                              : Config.dock.barLabels === "title" ? (win.title || entry?.name || "") : ""
                Text {
                    visible: !app.rule && !app.asText && app.label !== ""
                    width: Math.min(implicitWidth, 160)
                    elide: Text.ElideRight
                    text: app.label
                    color: app.active ? apps.bar.tone : apps.bar.dim
                    font { family: apps.bar.family; pixelSize: Theme.fontLabel; weight: app.active ? Font.DemiBold : Font.Normal }
                }
                Text {
                    visible: !app.rule && app.asText
                    text: apps.bar.say((app.win ? "" : (app.index + 1) + " ") + (app.label !== "" ? app.label.slice(0, 28) : (app.entry?.name ?? app.win?.wayland?.appId ?? "").toLowerCase().split(/[ .]/)[0])
                                + (apps.combine && app.wins.length > 1 ? "·" + app.wins.length : ""))
                    color: app.active ? Theme.accentText : app.marked ? apps.bar.tone : apps.bar.dim
                    font { family: apps.bar.family; pixelSize: Theme.fontLabel; weight: app.active ? Font.Bold : Font.Normal }
                }
                DockMark {   // open / focused mark, on the screen-edge side (icons only; same look as the floating dock)
                    parent: app
                    visible: app.marked && !app.asText
                    vertical: apps.bar.vertical
                    sign: Theme.barEdge === "bottom" || Theme.barEdge === "right" ? 1 : -1
                    ink: Qt.alpha(apps.bar.tone, 0.6)
                    style: Theme.dockStyle.mark
                    on: app.active
                }
            }
        }
    }
}
