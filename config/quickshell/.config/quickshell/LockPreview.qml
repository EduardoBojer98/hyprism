import QtQuick
import QtQuick.Effects

// A picture of a lock screen design (hypr/lockscreens/<design>.conf) over a background, for the
// Lock Screen settings page. Each design is the same widgets as its .conf file, in hyprlock's terms
// (position from an edge, y up), drawn on a 1600x1000 screen scaled to this item.
Item {
    id: lp

    property string design: "glass"
    property string source: ""          // background image path
    property int blur: 3                // hyprlock blur passes (0..6)
    property real brightness: 0.72
    property bool live: true            // false: a still clock, for small thumbnails

    readonly property real s: width / 1600
    readonly property color accent: Theme.accent
    readonly property bool h24: Config.bar.clock24
    property date now: new Date()
    Timer { running: lp.live && lp.visible; interval: 1000; repeat: true; onTriggered: lp.now = new Date() }
    readonly property string clock: Qt.formatTime(now, h24 ? "HH:mm" : "h:mm")
    readonly property string hour: Qt.formatTime(now, h24 ? "HH" : "hh")
    readonly property string minute: Qt.formatTime(now, "mm")
    readonly property string date: Qt.formatDate(now, "dddd, d MMMM")

    // type: text | field | box; size in hyprlock points; x, y from the h/v edge (y up)
    readonly property var designs: ({
        glass: [
            { type: "text", text: date, size: 20, weight: Font.DemiBold, opacity: 0.85, x: 0, y: -150, h: "center", v: "top" },
            { type: "text", text: clock, size: 104, weight: Font.DemiBold, x: 0, y: -180, h: "center", v: "top" },
            { type: "text", text: "Your name", size: 13, weight: Font.DemiBold, opacity: 0.9, x: 0, y: 150, h: "center", v: "bottom" },
            { type: "field", w: 240, hgt: 38, pill: true, x: 0, y: 96, h: "center", v: "bottom" },
        ],
        center: [
            { type: "text", text: date, size: 18, weight: Font.Medium, opacity: 0.8, x: 0, y: 150, h: "center", v: "center" },
            { type: "text", text: clock, size: 140, weight: Font.Light, x: 0, y: 40, h: "center", v: "center" },
            { type: "field", w: 300, hgt: 46, outline: true, x: 0, y: -110, h: "center", v: "center" },
        ],
        pebble: [
            { type: "text", text: clock, size: 120, weight: Font.Light, x: 0, y: 90, h: "center", v: "center" },
            { type: "text", text: date, size: 18, opacity: 0.75, x: 0, y: -10, h: "center", v: "center" },
            { type: "field", w: 300, hgt: 52, outline: true, pill: true, x: 0, y: -100, h: "center", v: "center" },
        ],
        console: [
            { type: "text", text: clock, size: 72, weight: Font.Light, accent: true, mono: true, x: 80, y: -80, h: "left", v: "top" },
            { type: "text", text: date.toUpperCase() + "  ·  LOCKED", size: 13, opacity: 0.7, mono: true, x: 84, y: -190, h: "left", v: "top" },
            { type: "field", w: 520, hgt: 44, outline: true, x: 80, y: -240, h: "left", v: "top" },
        ],
        noir: [
            { type: "box", w: 1920, hgt: 120, color: "#000000", x: 0, y: 0, h: "center", v: "top" },
            { type: "box", w: 1920, hgt: 120, color: "#000000", x: 0, y: 0, h: "center", v: "bottom" },
            { type: "text", text: clock, size: 110, weight: Font.Light, x: 0, y: 70, h: "center", v: "center" },
            { type: "text", text: date, size: 20, accent: true, x: 0, y: -30, h: "center", v: "center" },
            { type: "field", w: 320, hgt: 40, outline: true, x: 0, y: 70, h: "center", v: "bottom" },
        ],
        minimal: [
            { type: "text", text: clock, size: 64, weight: Font.Light, x: 64, y: 190, h: "left", v: "bottom" },
            { type: "text", text: date, size: 15, opacity: 0.75, x: 68, y: 160, h: "left", v: "bottom" },
            { type: "field", w: 220, hgt: 34, pill: true, x: 64, y: 90, h: "left", v: "bottom" },
        ],
        sidebar: [
            { type: "box", w: 528, hgt: 1000, color: Qt.rgba(0.05, 0.05, 0.06, 0.65), x: 0, y: 0, h: "left", v: "center" },
            { type: "box", w: 4, hgt: 120, accent: true, radius: 2, x: 70, y: 140, h: "left", v: "center" },
            { type: "text", text: clock, size: 88, weight: Font.Bold, x: 96, y: 160, h: "left", v: "center" },
            { type: "text", text: date, size: 18, weight: Font.Medium, opacity: 0.75, x: 100, y: 70, h: "left", v: "center" },
            { type: "text", text: "Welcome back, Your name", size: 16, weight: Font.DemiBold, opacity: 0.9, x: 100, y: -60, h: "left", v: "center" },
            { type: "field", w: 320, hgt: 44, x: 100, y: -120, h: "left", v: "center" },
        ],
        stacked: [
            { type: "text", text: hour, size: 190, weight: Font.Black, x: 0, y: 210, h: "center", v: "center" },
            { type: "text", text: minute, size: 190, weight: Font.Black, accent: true, x: 0, y: -10, h: "center", v: "center" },
            { type: "text", text: date.toUpperCase().replace(", ", " · "), size: 15, weight: Font.DemiBold, opacity: 0.8, x: 0, y: -160, h: "center", v: "center" },
            { type: "field", w: 260, hgt: 42, pill: true, x: 0, y: 90, h: "center", v: "bottom" },
        ],
        terminal: [
            { type: "box", w: 560, hgt: 260, color: Qt.rgba(0.04, 0.04, 0.05, 0.85), border: true, radius: 8, x: 0, y: 0, h: "center", v: "center" },
            { type: "text", text: "you@computer ~ locked at " + clock, size: 14, mono: true, accent: true, x: -40, y: 80, h: "center", v: "center" },
            { type: "text", text: "# " + Qt.formatDate(now, "dddd d MMMM yyyy"), size: 13, mono: true, opacity: 0.55, x: -40, y: 45, h: "center", v: "center" },
            { type: "text", text: "$ sudo unlock", size: 14, mono: true, opacity: 0.9, x: -170, y: -5, h: "center", v: "center" },
            { type: "field", w: 460, hgt: 38, radius: 4, x: 0, y: -60, h: "center", v: "center" },
        ],
    })

    clip: true

    Rectangle { anchors.fill: parent; color: "#1c1c1e" }
    Image {
        id: bg
        anchors.fill: parent
        source: lp.source ? "file://" + lp.source : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 640
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: bg
        visible: bg.status === Image.Ready
        blurEnabled: lp.blur > 0
        blur: Math.min(1, lp.blur / 6)
        blurMax: 48
        brightness: lp.brightness - 1
    }

    Repeater {
        model: lp.designs[lp.design] ?? []
        Item {
            id: el
            required property var modelData
            readonly property var e: modelData
            width: e.type === "text" ? label.implicitWidth : e.w * lp.s
            height: e.type === "text" ? label.implicitHeight : e.hgt * lp.s
            x: e.h === "left" ? e.x * lp.s : e.h === "right" ? lp.width - width - e.x * lp.s : (lp.width - width) / 2 + e.x * lp.s
            y: e.v === "top" ? -e.y * lp.s : e.v === "bottom" ? lp.height - height - e.y * lp.s : (lp.height - height) / 2 - e.y * lp.s

            Text {
                id: label
                visible: el.e.type === "text"
                text: el.e.text ?? ""
                color: el.e.accent ? lp.accent : el.e.accent2 ? Theme.accent2 : "#f5f5f7"
                opacity: el.e.opacity ?? 1
                font { family: el.e.mono ? Theme.monoFont : el.e.size > 60 ? Theme.displayFont : Theme.font
                       pixelSize: Math.max(4, Math.round((el.e.size ?? 10) * 1.33 * lp.s)); weight: el.e.weight ?? Font.Normal }
            }
            Rectangle {
                visible: el.e.type !== "text"
                anchors.fill: parent
                radius: el.e.pill ? height / 2 : (el.e.radius ?? (el.e.type === "field" ? Theme.radius : 0)) * lp.s
                color: el.e.type === "box" ? (el.e.accent ? lp.accent : el.e.color) : Qt.rgba(1, 1, 1, el.e.outline ? 0 : 0.1)
                border { width: el.e.outline ? Math.max(1, 2 * lp.s) : el.e.border || el.e.type === "field" ? 1 : 0
                         color: el.e.outline || el.e.border ? lp.accent : Qt.rgba(1, 1, 1, 0.15) }
                Row {   // password dots
                    visible: el.e.type === "field"
                    anchors.centerIn: parent
                    spacing: 6 * lp.s
                    Repeater { model: 4; Rectangle { width: 7 * lp.s; height: width; radius: width / 2; color: "#f5f5f7"; opacity: 0.8 } }
                }
            }
        }
    }
}
