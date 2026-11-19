import Quickshell
import QtQuick
import QtQuick.Layouts

// Displays: extend, mirror or one screen only; drag screens to arrange them; per screen: on/off, mirror, resolution, refresh rate, scale,
// rotation, adaptive sync and 10-bit colour. Apply saves the layout in settings.json (displays); SettingsSync.qml
// writes hypr/settings/displays.lua and applies it live. Unless you keep it, the old layout comes back after 15 s.
ColumnLayout {
    id: page
    spacing: 20

    // the logic lives in Displays.qml (also used by the display switcher and presets); this page only shows and edits it
    readonly property var monitors: Displays.monitors
    readonly property var edits: Displays.edits
    readonly property bool dirty: Displays.dirty
    property string selected: ""
    onMonitorsChanged: if (!monitors.some(m => m.key === selected)) selected = monitors[0]?.key ?? ""

    readonly property var sel: monitors.find(m => m.key === selected) ?? null
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

    function set(field, value) { Displays.set(selected, field, value) }

    // ---- several screens: extend, mirror or one only ----------------------------------------
    SettingGroup {
        title: "Multiple displays"
        visible: page.monitors.length > 1
        SettingRow {
            label: "Show the desktop"
            hint: "Extend: one desktop across the screens. Mirror: the same picture on all. Only: the others go dark"
            Choice {
                accessibleName: "Show the desktop"
                readonly property var keys: ["extend", "mirror"].concat(page.monitors.map(m => "only:" + m.key))
                options: ["Extend", "Mirror"].concat(page.monitors.map(m => "Only " + Displays.label(m)))
                index: Math.max(0, keys.indexOf(Displays.arrangement))
                onPicked: i => Displays.arrange(keys[i])
            }
        }
        SettingRow {
            label: "Main screen"
            hint: Config.displays.main && !Displays.mainScreen ? "Not connected now: notifications follow the screen you work on until it's back"
                : "Notifications and volume or brightness messages show here; workspace 1 and the pointer start here at login"
            Dropdown {
                width: 200
                readonly property var keys: [""].concat(page.monitors.map(m => m.key))
                readonly property var names: ["Where I'm working"].concat(page.monitors.map(m => Displays.numberOf(m.name) + " \u00b7 " + Displays.label(m)))
                options: names
                accessibleName: "Main screen"
                current: keys.includes(Config.displays.main) ? names[keys.indexOf(Config.displays.main)] : "A screen not connected"
                onPicked: v => Config.set("displays", "main", keys[names.indexOf(v)])
            }
        }
        SettingRow {
            visible: Config.displays.main !== ""
            label: "Menu bar only on the main screen"
            hint: "The other screens get the whole height"
            ConfigToggle { section: "displays"; key: "barOnMainOnly" }
        }
    }

    SettingsPageDisplaysPresets {}

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
                    const s = Displays.logicalSize(n), e = page.edits[n]
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
                    readonly property var size: Displays.logicalSize(modelData)
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
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Displays.numberOf(page.monitors.find(m => m.key === screenRect.modelData)?.name) + " \u00b7 " + Displays.label(page.monitors.find(m => m.key === screenRect.modelData) ?? { name: screenRect.modelData }); color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold } }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: screenRect.e.mode.replace("@", " · ") + " Hz"; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
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
                                const oe = page.edits[o], os = Displays.logicalSize(o), me = screenRect.size, snap = 80
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
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
    }

    // a gap between screens is a warning, not a refusal (Apply still works): say it under the drawing, offer to close it
    RowLayout {
        readonly property string gap: { page.edits; return Displays.gap() }
        visible: gap !== ""
        Layout.fillWidth: true
        Layout.topMargin: -8
        spacing: Theme.spaceS
        Text { text: "\u{F0026}"; color: Theme.yellow; font { family: Theme.iconFont; pixelSize: Theme.fontSize } }
        Text {
            Layout.fillWidth: true
            text: parent.gap
            wrapMode: Text.Wrap
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        PillButton { text: "Snap together"; onClicked: Displays.snapTogether() }
    }

    // ---- selected screen ---------------------------------------------------------------------
    SettingGroup {
        title: page.sel ? Displays.label(page.sel) + " screen" : ""   // the vendor model code says little; the canvas above shows which one
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
                options: ["Don't mirror"].concat(others.map(n => Displays.label(page.monitors.find(m => m.key === n))))
                current: page.selEdit?.mirror ? Displays.label(page.monitors.find(m => m.key === page.selEdit.mirror)) : "Don't mirror"
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
            hint: "Bigger text and controls; small sharp screens (a laptop's) usually want 1.25–1.5"
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
            text: Displays.notice || (page.dirty ? "Unsaved changes" : "Saved")
            color: Displays.notice || page.dirty ? Theme.yellow : Theme.muted
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        PillButton { text: "Revert"; enabled: page.dirty; onClicked: Displays.discard() }
        PillButton { text: "Apply"; primary: true; enabled: page.dirty; onClicked: Displays.apply(true) }
    }

    // after Apply: keep the new settings, or they go back on their own (a mode the screen can't show)
    Rectangle {
        visible: Displays.counting
        Layout.fillWidth: true
        implicitHeight: 52
        radius: Theme.radius
        color: Theme.accentWash
        border { color: Theme.accent; width: 1 }
        RowLayout {
            anchors { fill: parent; leftMargin: 16; rightMargin: 12 }
            Text {
                Layout.fillWidth: true
                text: `Keep these display settings? Going back in ${Displays.left} s`
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.Medium }
            }
            PillButton { text: "Go back"; onClicked: Displays.revert() }
            PillButton { text: "Keep"; primary: true; onClicked: Displays.keep() }
        }
    }

    SettingGroup {
        title: "Advanced"
        SettingRow {
            label: "Adaptive sync (all screens)"
            hint: "Smoother motion in games on screens that support it; \"Fullscreen\" only while an app is fullscreen"
            ConfigChoice { section: "displays"; key: "vrr"; values: ["off", "on", "fullscreen"]; labels: ["Off", "On", "Fullscreen"] }
        }
        SettingRow {
            label: "New screens"
            hint: "Where a screen goes the first time it is plugged in (after that, its saved place)"
            ConfigChoice { section: "displays"; key: "newScreen"; values: ["right", "left", "above", "below", "mirror"]; labels: ["Right", "Left", "Above", "Below", "Mirror"] }
        }
        SettingRow {
            label: "Prefer the highest refresh rate"
            hint: "A screen you plug in for the first time starts at its fastest mode instead of its default"
            ConfigToggle { section: "displays"; key: "preferHighRefresh" }
        }
        SettingRow {
            label: "Sharp old apps"
            hint: "Old X11 apps draw at the screen's real pixels: crisp, but smaller on a scaled screen"
            ConfigToggle { section: "displays"; key: "xwaylandNativeScale" }
        }
        SettingRow {
            label: "Automatic HDR colour"
            hint: "Switches the screen's colour mode for HDR video; leave off if a screen blanks during fullscreen video"
            ConfigToggle { section: "displays"; key: "autoHdr" }
        }
        SettingRow {
            label: "Tell the screen what is playing"
            hint: "Lets a TV pick its game or movie mode; leave off if a screen blanks when you go fullscreen"
            ConfigToggle { section: "displays"; key: "sendContentType" }
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
                width: 220
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
                        // typing breaks the text binding: show the saved value again after any change
                        Connections {
                            target: Config
                            function onNightLightChanged() { parent.text = Config.nightLight[parent.modelData] }
                        }
                    }
                }
            }
        }
    }
}
