import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Displays: drag screens to arrange them, pick resolution, scale, rotation and adaptive sync.
// Apply changes Hyprland live (hyprctl eval) and saves hypr/settings/displays.lua.
ColumnLayout {
    id: page
    spacing: 20

    property var monitors: []      // from hyprctl -j monitors all
    property var edits: ({})       // name -> { mode, x, y, scale, transform, vrr }
    property string selected: ""
    property bool dirty: false

    readonly property var sel: monitors.find(m => m.name === selected) ?? null
    readonly property var selEdit: edits[selected] ?? null

    function load() { read.running = true }
    Component.onCompleted: load()

    Process {
        id: read
        command: ["hyprctl", "-j", "monitors", "all"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = JSON.parse(text)
                const e = {}
                for (const m of list)
                    e[m.name] = { mode: m.width + "x" + m.height + "@" + Math.round(m.refreshRate), x: m.x, y: m.y,
                                  scale: m.scale, transform: m.transform, vrr: m.name === "HDMI-A-1" ? 2 : 0 }
                page.monitors = list
                page.edits = e
                if (!page.selected && list.length) page.selected = list[0].name
                page.dirty = false
            }
        }
    }

    function logicalSize(name) {
        const e = edits[name]
        if (!e) return { w: 0, h: 0 }
        const [w, h] = e.mode.split("@")[0].split("x").map(Number)
        const rotated = e.transform % 2 === 1
        return { w: Math.round((rotated ? h : w) / e.scale), h: Math.round((rotated ? w : h) / e.scale) }
    }

    function set(field, value) {
        const e = Object.assign({}, edits)
        e[selected] = Object.assign({}, e[selected], { [field]: value })
        edits = e
        dirty = true
    }

    function apply() {
        // Normalise so the top-left screen sits at 0,0
        const names = Object.keys(edits)
        const minX = Math.min(...names.map(n => edits[n].x)), minY = Math.min(...names.map(n => edits[n].y))
        const out = {}
        for (const n of names) {
            const e = edits[n]
            out[n] = { mode: e.mode, position: (e.x - minX) + "x" + (e.y - minY), scale: e.scale, transform: e.transform }
            if (e.vrr) out[n].vrr = e.vrr
        }
        const table = SettingsApp.lua(out)
        Quickshell.execDetached(["hyprctl", "eval", "DISPLAYS = " + table.replace(/\n/g, " ") + "; apply_displays()"])
        SettingsApp.writeHyprFile("settings/displays.lua",
            "-- Written by the Settings app (Displays). Safe to edit by hand; positions are in logical pixels.\nreturn " + table)
        reloadTimer.restart()
    }
    Timer { id: reloadTimer; interval: 800; onTriggered: page.load() }

    // ---- arrangement canvas -----------------------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 260
        radius: 14
        color: Qt.rgba(0, 0, 0, 0.22)
        border { color: Theme.stroke; width: 1 }

        Item {
            id: stage
            anchors { fill: parent; margins: 24 }
            readonly property var bounds: {
                const names = Object.keys(page.edits)
                if (!names.length) return { x: 0, y: 0, w: 1, h: 1 }
                let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
                for (const n of names) {
                    const s = page.logicalSize(n), e = page.edits[n]
                    x0 = Math.min(x0, e.x); y0 = Math.min(y0, e.y); x1 = Math.max(x1, e.x + s.w); y1 = Math.max(y1, e.y + s.h)
                }
                return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 }
            }
            readonly property real k: Math.min(width / (bounds.w * 1.15), height / (bounds.h * 1.1))

            Repeater {
                model: Object.keys(page.edits)
                Rectangle {
                    id: screenRect
                    required property string modelData
                    readonly property var size: page.logicalSize(modelData)
                    readonly property var e: page.edits[modelData]
                    x: (e.x - stage.bounds.x) * stage.k + (stage.width - stage.bounds.w * stage.k) / 2
                    y: (e.y - stage.bounds.y) * stage.k + (stage.height - stage.bounds.h * stage.k) / 2
                    width: size.w * stage.k
                    height: size.h * stage.k
                    radius: 8
                    color: page.selected === modelData ? Qt.rgba(0.54, 0.68, 0.96, 0.28) : Theme.fillHover
                    border { color: page.selected === modelData ? Theme.accent : Theme.stroke; width: page.selected === modelData ? 2 : 1 }

                    Column {
                        anchors.centerIn: parent
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: screenRect.modelData === "eDP-1" ? "Laptop" : screenRect.modelData === "HDMI-A-1" ? "Acer" : screenRect.modelData; color: Theme.text; font { family: Theme.font; pixelSize: 13; weight: Font.DemiBold } }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: screenRect.e.mode.split("@")[0]; color: Theme.subtext; font { family: Theme.font; pixelSize: 11 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeAllCursor
                        drag.target: parent
                        onPressed: page.selected = screenRect.modelData
                        onReleased: {
                            // back to logical pixels, snapped to the other screen's edges
                            let nx = Math.round((parent.x - (stage.width - stage.bounds.w * stage.k) / 2) / stage.k + stage.bounds.x)
                            let ny = Math.round((parent.y - (stage.height - stage.bounds.h * stage.k) / 2) / stage.k + stage.bounds.y)
                            for (const o of Object.keys(page.edits)) {
                                if (o === screenRect.modelData) continue
                                const oe = page.edits[o], os = page.logicalSize(o), me = screenRect.size, snap = 80
                                for (const [a, b] of [[nx, oe.x + os.w], [nx + me.w, oe.x], [nx, oe.x], [nx + me.w, oe.x + os.w], [nx + (me.w - os.w) / 2, oe.x]])
                                    if (Math.abs(a - b) < snap) { nx += b - a; break }
                                for (const [a, b] of [[ny, oe.y + os.h], [ny + me.h, oe.y], [ny, oe.y], [ny + me.h, oe.y + os.h]])
                                    if (Math.abs(a - b) < snap) { ny += b - a; break }
                            }
                            page.set("x", Math.round(nx)); page.set("y", Math.round(ny))
                        }
                    }
                }
            }
        }

        Text {
            anchors { left: parent.left; bottom: parent.bottom; margins: 10 }
            text: "Drag the screens to match how they sit on your desk"
            color: Theme.muted
            font { family: Theme.font; pixelSize: 11 }
        }
    }

    // ---- selected screen ---------------------------------------------------------------------
    SettingGroup {
        title: page.sel ? (page.sel.name === "eDP-1" ? "Laptop" : page.sel.name === "HDMI-A-1" ? "Acer" : page.sel.name) + " — " + page.sel.description : ""
        visible: page.sel !== null

        SettingRow {
            label: "Resolution & refresh rate"
            Dropdown {
                width: 240
                current: page.selEdit?.mode ?? ""
                options: page.sel ? [...new Set(page.sel.availableModes.map(m => { const [r, hz] = m.split("@"); return r + "@" + Math.round(parseFloat(hz)) }))] : []
                onPicked: v => page.set("mode", v)
            }
        }
        SettingRow {
            label: "Scale"
            hint: "Bigger text and controls; 1.2–1.25 suits the 13\" laptop panel"
            Choice {
                readonly property var values: [1, 1.2, 1.25, 1.5, 1.6, 2]
                options: values.map(v => v + "×")
                index: values.indexOf(page.selEdit?.scale ?? 1)
                onPicked: i => page.set("scale", values[i])
            }
        }
        SettingRow {
            label: "Rotation"
            Choice {
                options: ["Normal", "90°", "180°", "270°"]
                index: (page.selEdit?.transform ?? 0) % 4
                onPicked: i => page.set("transform", i)
            }
        }
        SettingRow {
            label: "Adaptive sync (VRR)"
            hint: "Smoother games and video; \"Fullscreen\" avoids flicker on the desktop"
            Choice {
                options: ["Off", "On", "Fullscreen"]
                index: page.selEdit?.vrr ?? 0
                onPicked: i => page.set("vrr", i)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: page.dirty ? "Unsaved changes" : "Saved to hypr/settings/displays.lua"
            color: page.dirty ? Theme.yellow : Theme.muted
            font { family: Theme.font; pixelSize: 12 }
        }
        PillButton { text: "Revert"; enabled: page.dirty; onClicked: page.load() }
        PillButton { text: "Apply"; primary: true; enabled: page.dirty; onClicked: page.apply() }
    }
}
