import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Displays: drag screens to arrange them; per screen: on/off, mirror, resolution, refresh rate, scale,
// rotation, adaptive sync and 10-bit colour. Apply changes Hyprland live (hyprctl eval) and saves
// hypr/settings/displays.lua; unless you keep them, the old settings come back after 15 s.
ColumnLayout {
    id: page
    spacing: 20

    property var monitors: []      // from hyprctl -j monitors all
    property var edits: ({})       // name -> { mode, x, y, scale, transform, vrr, bitdepth, mirror, disabled }
    property var saved: ({})       // edits as last loaded, for Revert and the keep-or-revert countdown
    property var previous: null    // what to go back to while the countdown runs
    property string selected: ""
    property bool dirty: false

    readonly property var sel: monitors.find(m => m.name === selected) ?? null
    readonly property var selEdit: edits[selected] ?? null
    // screens drawn on the canvas: on, and not showing another screen's picture
    readonly property var placed: Object.keys(edits).filter(n => !edits[n].disabled && !edits[n].mirror)
    // "1920x1200" -> [120, 60, ...] for the selected screen
    readonly property var rates: {
        const out = {}
        for (const m of sel?.availableModes ?? []) {
            const [res, hz] = m.split("@")
            const r = Math.round(parseFloat(hz))
            if (!(out[res] ?? []).includes(r)) out[res] = (out[res] ?? []).concat([r])
        }
        for (const k in out) out[k].sort((a, b) => b - a)
        return out
    }
    readonly property var resolutions: Object.keys(rates).sort((a, b) => {
        const [aw, ah] = a.split("x").map(Number), [bw, bh] = b.split("x").map(Number)
        return bw * bh - aw * ah || bw - aw
    })
    readonly property string selRes: selEdit?.mode.split("@")[0] ?? ""
    readonly property int selHz: Number(selEdit?.mode.split("@")[1] ?? 0)

    function label(m) { return m.name.startsWith("eDP") ? "Laptop" : (m.make || m.name).split(" ")[0] }
    function load() { read.running = true }
    Component.onCompleted: load()

    Process {
        id: read
        // Hyprland reports the live state; adaptive sync's mode (on / fullscreen) only lives in the saved file
        command: ["sh", "-c", "hyprctl -j monitors all; echo '@@'; cat \"$HOME/.config/hypr/settings/displays.lua\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [json, lua] = text.split("@@\n")
                const list = JSON.parse(json)
                const e = {}
                for (const m of list) {
                    const block = (lua ?? "").match(new RegExp('\\["' + m.name + '"\\] = \\{([^}]*)\\}'))?.[1] ?? ""
                    // a screen that's off may report 0x0: its first (preferred) mode then
                    const first = (m.availableModes?.[0] ?? "1920x1080@60").split("@")
                    e[m.name] = { mode: m.width ? m.width + "x" + m.height + "@" + Math.round(m.refreshRate) : first[0] + "@" + Math.round(parseFloat(first[1])), x: m.x, y: m.y,
                                  scale: m.scale, transform: m.transform, vrr: Number(block.match(/\["vrr"\] = (\d)/)?.[1] ?? 0),
                                  bitdepth: /2101010/.test(m.currentFormat) ? 10 : 8,
                                  mirror: m.mirrorOf && m.mirrorOf !== "none" ? m.mirrorOf : "", disabled: m.disabled === true }
                }
                page.monitors = list
                page.edits = e
                page.saved = e
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

    function apply(confirm) {
        // Normalise so the top-left screen sits at 0,0
        const names = Object.keys(edits)
        const shown = names.filter(n => !edits[n].disabled && !edits[n].mirror)
        const minX = Math.min(...shown.map(n => edits[n].x)), minY = Math.min(...shown.map(n => edits[n].y))
        const out = {}
        for (const n of names) {
            const e = edits[n]
            if (e.disabled) { out[n] = { disabled: true }; continue }
            out[n] = { mode: e.mode, position: (e.x - minX) + "x" + (e.y - minY), scale: e.scale, transform: e.transform }
            if (e.vrr) out[n].vrr = e.vrr
            if (e.bitdepth === 10) out[n].bitdepth = 10
            if (e.mirror) out[n].mirror = e.mirror
        }
        if (confirm) { previous = saved; countdown.left = 15; countdown.start() }
        const table = SettingsApp.lua(out)
        Quickshell.execDetached(["hyprctl", "eval", "DISPLAYS = " + table.replace(/\n/g, " ") + "; apply_displays()"])
        SettingsApp.writeHyprFile("settings/displays.lua",
            "-- Written by the Settings app (Displays). Safe to edit by hand; positions are in logical pixels.\nreturn " + table)
        reloadTimer.restart()
    }
    Timer { id: reloadTimer; interval: 800; onTriggered: page.load() }
    function keep() { countdown.stop(); previous = null }
    function revert() { countdown.stop(); edits = previous; previous = null; apply(false) }
    Timer {
        id: countdown
        property int left: 15
        interval: 1000; repeat: true
        onTriggered: if (--left <= 0) page.revert()
    }

    // ---- arrangement canvas -----------------------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 260
        radius: Theme.radius
        color: Theme.fill
        border { color: Theme.stroke; width: 1 }

        Item {
            id: stage
            anchors { fill: parent; margins: 24 }
            readonly property var bounds: {
                const names = page.placed
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
                model: page.placed
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
                    color: page.selected === modelData ? Theme.accentWash : Theme.fillHover
                    border { color: page.selected === modelData ? Theme.accent : Theme.stroke; width: page.selected === modelData ? 2 : 1 }

                    Column {
                        anchors.centerIn: parent
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: page.label(page.monitors.find(m => m.name === screenRect.modelData) ?? { name: screenRect.modelData }); color: Theme.text; font { family: Theme.font; pixelSize: 13; weight: Font.DemiBold } }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: screenRect.e.mode.replace("@", " · ") + " Hz"; color: Theme.subtext; font { family: Theme.font; pixelSize: 11 } }
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
                            for (const o of page.placed) {
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
        title: page.sel ? page.label(page.sel) + " — " + page.sel.description : ""
        visible: page.sel !== null

        SettingRow {
            label: "Use this display"
            hint: page.placed.length <= 1 && !page.selEdit?.disabled ? "It's the only screen showing the desktop" : "Off leaves the screen dark and moves its windows"
            Toggle {
                checked: !(page.selEdit?.disabled ?? false)
                // never turn off the last screen that shows the desktop
                onToggled: on => { if (on || page.placed.length > 1 || page.selEdit?.mirror) page.set("disabled", !on) }
            }
        }
        SettingRow {
            visible: !page.selEdit?.disabled && Object.keys(page.edits).length > 1
            label: "Mirror"
            hint: "Show the same picture as another screen"
            Dropdown {
                width: 200
                readonly property var others: Object.keys(page.edits).filter(n => n !== page.selected && !page.edits[n].disabled && !page.edits[n].mirror)
                options: ["Don't mirror"].concat(others.map(n => page.label(page.monitors.find(m => m.name === n))))
                current: page.selEdit?.mirror ? page.label(page.monitors.find(m => m.name === page.selEdit.mirror)) : "Don't mirror"
                onPicked: v => page.set("mirror", v === "Don't mirror" ? "" : others[options.indexOf(v) - 1])
            }
        }
        SettingRow {
            visible: !page.selEdit?.disabled
            label: "Resolution"
            Dropdown {
                width: 200
                current: page.selRes
                options: page.resolutions
                onPicked: v => page.set("mode", v + "@" + (page.rates[v].includes(page.selHz) ? page.selHz : page.rates[v][0]))
            }
        }
        SettingRow {
            visible: !page.selEdit?.disabled
            label: "Refresh rate"
            hint: "Higher is smoother; lower saves battery"
            Dropdown {
                width: 200
                current: page.selHz + " Hz"
                options: (page.rates[page.selRes] ?? []).map(r => r + " Hz")
                onPicked: v => page.set("mode", page.selRes + "@" + parseInt(v))
            }
        }
        SettingRow {
            visible: !page.selEdit?.disabled && !page.selEdit?.mirror
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
            visible: !page.selEdit?.disabled && !page.selEdit?.mirror
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
        SettingRow {
            visible: !page.selEdit?.disabled
            label: "10-bit colour"
            hint: "Smoother gradients on screens that support it; turn off if colours look wrong"
            Toggle { checked: page.selEdit?.bitdepth === 10; onToggled: on => page.set("bitdepth", on ? 10 : 8) }
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
        PillButton { text: "Apply"; primary: true; enabled: page.dirty; onClicked: page.apply(true) }
    }

    // after Apply: keep the new settings, or they go back on their own (a mode the screen can't show)
    Rectangle {
        visible: countdown.running
        Layout.fillWidth: true
        implicitHeight: 52
        radius: Theme.radius
        color: Theme.accentWash
        border { color: Theme.accent; width: 1 }
        RowLayout {
            anchors { fill: parent; leftMargin: 16; rightMargin: 12 }
            Text {
                Layout.fillWidth: true
                text: `Keep these display settings? Going back in ${countdown.left} s`
                color: Theme.text
                font { family: Theme.font; pixelSize: 13; weight: Font.Medium }
            }
            PillButton { text: "Go back"; onClicked: page.revert() }
            PillButton { text: "Keep"; primary: true; onClicked: page.keep() }
        }
    }

    SettingGroup {
        title: "Night Light"
        SettingRow {
            label: "Turn on"
            hint: NightLight.sun ? `Sunset ${NightLight.clock(NightLight.sun.set)}, sunrise ${NightLight.clock(NightLight.sun.rise)} in ${Config.weather.city}` : ""
            ConfigChoice { section: "nightLight"; key: "mode"; values: ["off", "on", "sun", "schedule"]; labels: ["Off", "Always", "Sunset to sunrise", "Custom hours"] }
        }
        SettingRow {
            label: "Warmth"
            hint: `${Config.nightLight.temperature} K` + (NightLight.active ? "" : " (applies when Night Light is on)")
            Slider {
                Layout.preferredWidth: 220
                icon: "\u{F0599}"
                // 6000 K (neutral) at the left, 2500 K (warmest) at the right
                value: (6000 - Config.nightLight.temperature) / 3500
                onMoved: v => Config.set("nightLight", "temperature", Math.round((6000 - v * 3500) / 100) * 100)
            }
        }
        SettingRow {
            visible: Config.nightLight.mode === "schedule"
            label: "From – to"
            hint: "24-hour time, e.g. 21:00 – 07:00"
            RowLayout {
                spacing: Theme.spaceS
                Repeater {
                    model: ["from", "to"]
                    TextField {
                        required property string modelData
                        Layout.preferredWidth: 72
                        text: Config.nightLight[modelData]
                        invalid: !/^([01]?\d|2[0-3]):[0-5]\d$/.test(text)
                        onAccepted: if (!invalid) Config.set("nightLight", modelData, text.length === 4 ? "0" + text : text)
                    }
                }
            }
        }
    }
}
