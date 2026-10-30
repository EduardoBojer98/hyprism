import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// ASUS Hardware: live temperatures, power and fans; power mode; fan-curve editor (asusctl via
// ~/.local/bin/asusfan, which validates again and backs up the original curves on the first change).
// Power modes only change hardware (power limits, fans, EPP); nothing on the desktop follows them.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var profiles: ["Quiet", "Balanced", "Performance"]
    property var now: ({})            // asusfan sample
    property var curves: ({})         // asusfan get
    property int profileIndex: Math.max(0, profiles.indexOf(now.profile ?? "Quiet"))
    property string fan: "cpu"
    property var temp: []             // the curve being edited
    property var pct: []
    property bool dirty: false
    property string message: ""
    property bool messageIsError: false

    readonly property string profile: profiles[profileIndex]
    readonly property var current: curves[profile]?.[fan] ?? null
    readonly property string problem: check(temp, pct)

    function load() {
        if (!current) return
        temp = current.temp.slice(); pct = current.pct.slice(); dirty = false
    }
    // Same rules as `asusfan validate`, so mistakes show before Apply
    function check(t, p) {
        if (t.length !== 8) return ""
        for (let i = 1; i < 8; i++) {
            if (t[i] < t[i - 1] || (t[i] === t[i - 1] && p[i] !== p[i - 1])) return "Temperatures must rise from left to right"
            if (p[i] < p[i - 1]) return "Fan speed can't drop as it gets hotter"
        }
        for (let i = 0; i < 8; i++) if (t[i] >= 85 && p[i] < 40) return `At ${t[i]} °C the fan needs at least 40 %`
        if (p[7] < 40) return "The last point needs at least 40 % fan"
        return ""
    }
    function curveData() { return temp.map((t, i) => `${t}c:${pct[i]}%`).join(",") }
    function run(args, okText) {
        page.message = "Working…"; page.messageIsError = false
        runner.okText = okText
        runner.command = ["asusfan"].concat(args)
        runner.running = true
    }

    onCurrentChanged: if (!dirty) load()
    onProfileChanged: load()
    onFanChanged: load()

    Process {
        id: sampler
        command: ["asusfan", "sample"]
        stdout: StdioCollector { onStreamFinished: { try { page.now = JSON.parse(text) } catch (e) {} } }
    }
    // Only while this page is on screen
    Timer { interval: 2000; repeat: true; triggeredOnStart: true; running: page.visible && SettingsApp.open; onTriggered: sampler.running = true }

    Process {
        id: reader
        running: true
        command: ["asusfan", "get"]
        stdout: StdioCollector { onStreamFinished: { try { page.curves = JSON.parse(text); page.load() } catch (e) { page.message = "Couldn't read the fan curves (is asusd running?)"; page.messageIsError = true } } }
    }
    Process {
        id: runner
        property string okText
        stdout: StdioCollector { id: out }
        stderr: StdioCollector { id: err }
        onExited: code => {
            page.messageIsError = code !== 0
            page.message = code === 0 ? (runner.okText || out.text.trim()) : err.text.trim().replace(/^asusfan: /, "")
            if (code === 0) { page.dirty = false; reader.running = true }
        }
    }

    // ---- live readout --------------------------------------------------------------------
    SettingGroup {
        title: "Right now"
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spaceM
            columns: 4
            rowSpacing: Theme.spaceM
            columnSpacing: Theme.spaceM
            Repeater {
                model: [
                    ["CPU", page.now.cpu, "°C", page.now.cpu >= 90],
                    ["Graphics", page.now.gpu, "°C", page.now.gpu >= 90],
                    ["Package", page.now.watts, "W", false],
                    ["Load", page.now.load, "%", false],
                    ["CPU clock", page.now.mhz, "MHz", false],
                    ["CPU fan", page.now.fanCpu, "rpm", false],
                    ["GPU fan", page.now.fanGpu, "rpm", false],
                    ["NVIDIA", page.now.nvidia === "suspended" ? "Off" : page.now.nvidia === "active" ? "On" : "–", "", false],
                ]
                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: modelData[0]; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                    Text {
                        text: (modelData[1] ?? "–") + (modelData[2] ? " " + modelData[2] : "")
                        color: modelData[3] ? Theme.error : Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold; features: { "tnum": 1 } }
                    }
                }
            }
        }
    }

    SettingGroup {
        title: "Power mode"
        SettingRow {
            label: "Mode"
            hint: "Changes power limits and fans only. Plugging in switches to Performance, battery to Quiet."
            Choice {
                options: page.profiles
                index: PowerProfiles.profile
                onPicked: i => PowerProfiles.profile = i
            }
        }
    }

    // ---- fan curves ------------------------------------------------------------------------
    SettingGroup {
        title: "Fan curves"
        SettingRow {
            label: "Mode"
            Choice { options: page.profiles; index: page.profileIndex; onPicked: i => { page.dirty = false; page.profileIndex = i } }
        }
        SettingRow {
            label: "Fan"
            Choice { options: ["CPU", "GPU"]; index: page.fan === "cpu" ? 0 : 1; onPicked: i => { page.dirty = false; page.fan = i ? "gpu" : "cpu" } }
        }
        SettingRow {
            label: page.current?.enabled ? "Using your curve" : "Using the built-in curve"
            hint: page.current?.enabled ? "The curve below sets the fan" : "The firmware decides; the curve below is what Apply will use"
            PillButton { visible: page.current?.enabled ?? false; text: "Use built-in"; onClicked: page.run(["enable", page.profile, page.fan, "false"], "Back on the built-in curve") }
        }

        // Drag the points: left/right = temperature, up/down = fan speed
        Item {
            id: chart
            Layout.fillWidth: true
            Layout.preferredHeight: 240
            Layout.margins: Theme.spaceM

            readonly property real plotLeft: 36
            readonly property real plotBottom: height - 22
            readonly property real plotW: width - plotLeft - 8
            readonly property real plotH: plotBottom - 8
            function xOf(t) { return plotLeft + (t - 30) / 70 * plotW }
            function yOf(p) { return plotBottom - p / 100 * plotH }

            Repeater { // grid lines
                model: [0, 25, 50, 75, 100]
                Item {
                    required property int modelData
                    Rectangle { x: chart.plotLeft; y: chart.yOf(parent.modelData); width: chart.plotW; height: 1; color: Theme.stroke }
                    Text { x: 0; y: chart.yOf(parent.modelData) - 7; text: parent.modelData + "%"; color: Theme.muted; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                }
            }
            Repeater {
                model: [30, 40, 50, 60, 70, 80, 90, 100]
                Text {
                    required property int modelData
                    x: chart.xOf(modelData) - width / 2; y: chart.plotBottom + 6
                    text: modelData + "°"; color: Theme.muted
                    font { family: Theme.font; pixelSize: Theme.fontCaption }
                }
            }

            Canvas {
                id: line
                anchors.fill: parent
                property var pts: page.temp.map((t, i) => [chart.xOf(t), chart.yOf(page.pct[i])])
                onPtsChanged: requestPaint()
                onPaint: {
                    const g = getContext("2d")
                    g.reset()
                    if (pts.length < 2) return
                    g.strokeStyle = Theme.accent; g.lineWidth = 2
                    g.beginPath(); g.moveTo(chart.plotLeft, pts[0][1])
                    for (const p of pts) g.lineTo(p[0], p[1])
                    g.lineTo(chart.plotLeft + chart.plotW, pts[pts.length - 1][1])
                    g.stroke()
                }
            }

            // where the CPU is right now
            Rectangle {
                visible: page.fan === "cpu" && page.now.cpu > 30
                x: chart.xOf(Math.min(100, page.now.cpu ?? 30)); y: 8; width: 1; height: chart.plotH
                color: Theme.warning; opacity: 0.6
            }

            Repeater {
                model: page.temp.length
                Rectangle {
                    id: handle
                    required property int index
                    width: 14; height: 14; radius: 7
                    x: chart.xOf(page.temp[index]) - 7
                    y: chart.yOf(page.pct[index]) - 7
                    color: drag.containsMouse || drag.pressed ? Theme.accent : Theme.glassStrong
                    border { color: Theme.accent; width: 2 }

                    Text {
                        visible: drag.pressed || drag.containsMouse
                        anchors { bottom: parent.top; bottomMargin: 4; horizontalCenter: parent.horizontalCenter }
                        text: `${page.temp[handle.index]} °C · ${page.pct[handle.index]} %`
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                    }

                    MouseArea {
                        id: drag
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.SizeAllCursor
                        onPositionChanged: mouse => {
                            if (!pressed) return
                            const p = mapToItem(chart, mouse.x, mouse.y)
                            const i = handle.index
                            const t = page.temp.slice(), f = page.pct.slice()
                            // stay between the neighbours so the curve keeps its shape
                            const tMin = i > 0 ? t[i - 1] + 1 : 30, tMax = i < 7 ? t[i + 1] - 1 : 100
                            const fMin = i > 0 ? f[i - 1] : 0, fMax = i < 7 ? f[i + 1] : 100
                            t[i] = Math.round(Math.max(tMin, Math.min(tMax, 30 + (p.x - chart.plotLeft) / chart.plotW * 70)))
                            f[i] = Math.round(Math.max(fMin, Math.min(fMax, (chart.plotBottom - p.y) / chart.plotH * 100)))
                            page.temp = t; page.pct = f; page.dirty = true
                        }
                    }
                }
            }
        }

        SettingRow {
            label: page.problem || (page.message || (page.dirty ? "Not applied yet" : "Saved in asusd for this mode"))
            hint: "The firmware still speeds the fans up and slows the CPU if it gets too hot."
            RowLayout {
                spacing: Theme.spaceS
                PillButton { text: "Undo changes"; visible: page.dirty; onClicked: page.load() }
                PillButton {
                    text: "Apply"
                    primary: true
                    visible: page.dirty && !page.problem
                    onClicked: page.run(["set", page.profile, page.fan, page.curveData()], `${page.profile} ${page.fan.toUpperCase()} curve applied`)
                }
            }
        }
        SettingRow {
            label: "Original curves"
            hint: "Saved in ~/.local/state/asus-backup before the first change"
            PillButton { text: "Restore"; onClicked: page.run(["restore"], "Original curves restored") }
        }
    }
}
