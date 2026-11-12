pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// The system dropdown (opened by the cpu / memory / gpu / system-info bar items): every reading this computer
// has, taken from the Metrics service (which measures only while something visible asks), plus the top
// processes and a button for the task manager (Settings > Default Applications, Ctrl+Shift+Esc).
// A reading the computer lacks does not appear. Warn / critical levels come from Metrics.registry and show
// as "!" / "!!" after the value, so a warning never rests on colour alone.
Singleton {
    id: root

    // thin aliases for callers outside this file (the Control Center hardware tile)
    readonly property real cpu: Metrics.has("cpu_temp") ? Metrics.value("cpu_temp") : NaN
    readonly property real gpu: Metrics.has("gpu_temp") ? Metrics.value("gpu_temp") : NaN
    readonly property bool open: popup.open
    property var procs: []            // [{ name, cpu, mem }]

    // what the panel shows: asked for while it is visible, given back with exactly the same list
    readonly property var panelIds: ["cpu", "cpu_temp", "cpu_freq", "gpu", "gpu_temp", "gpu_vram", "gpu_power",
        "dgpu", "dgpu_temp", "dgpu_vram", "dgpu_power", "ram", "swap", "disk", "disk_io", "net", "battery",
        "battery_power", "battery_time", "fans", "profile", "uptime", "load"]
    // the Control Center's temperature line needs only the CPU temperature
    readonly property var wantIds: popup.open ? panelIds : ControlCenter.open ? ["cpu_temp"] : []
    property var asked: []
    onWantIdsChanged: { Metrics.unwant(asked); asked = wantIds; Metrics.want(asked, 2) }

    // "!" at the warn level, "!!" at the critical level (Metrics.registry), so colour is never the only signal
    function flagAt(id, v) {
        const r = Metrics.registry[id]
        return !r || typeof v !== "number" ? "" : r.critical !== undefined && v >= r.critical ? "!!" : r.warn !== undefined && v >= r.warn ? "!" : ""
    }
    function flag(id) { return flagAt(id, Metrics.value(id)) }
    function flagTone(f) { return f === "!!" ? Theme.error : f === "!" ? Theme.warning : Theme.text }
    function cardDetail(pre) {        // power of a graphics card, when it reports it
        return Metrics.has(pre + "_power") ? Metrics.text(pre + "_power") : ""
    }
    readonly property var d: Metrics.data

    // Task manager: the chosen desktop id, or the first installed of these
    readonly property var taskManagers: ["io.missioncenter.MissionCenter", "org.kde.plasma-systemmonitor", "btop", "htop"]
    readonly property var taskManager: {
        DesktopEntries.applications.values.length   // re-check once the app list has loaded
        const pick = Config.system.taskManager
        if (pick !== "auto") return DesktopEntries.byId(pick)
        for (const id of taskManagers) { const e = DesktopEntries.byId(id); if (e) return e }
        return null
    }
    function openTaskManager() { popup.hide(); taskManager?.execute() }
    function toggle() { popup.toggle() }

    // top processes: one cheap read every 5 s while the panel is open (pcpu is the share since the process began)
    Process {
        id: psRead
        command: ["ps", "-eo", "pcpu,pmem,comm", "--sort=-pcpu", "--no-headers"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = Math.max(1, Metrics.data.cpu?.cores?.length ?? 1)   // as a share of the whole CPU
                root.procs = text.trim().split("\n").slice(0, 5).map(l => l.trim().split(/\s+/))
                    .map(p => ({ name: p.slice(2).join(" "), cpu: Number(p[0]) / n, mem: Number(p[1]) }))
            }
        }
    }
    Timer { interval: 5000; running: popup.open; repeat: true; triggeredOnStart: true; onTriggered: psRead.running = true }

    IpcHandler {
        target: "system"
        function toggle(): void { root.toggle() }
        function taskmanager(): void { root.taskManager?.execute() }
    }

    // ---- dropdown, under the bar at the right ------------------------------------------------------
    CursorPopup {
        id: popup
        name: "system"
        placement: "topRight"
        boxWidth: 330
        boxHeight: Math.min(body.implicitHeight + 20, popup.maxHeight)

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusPanel

            Flickable {
                anchors { fill: parent; margins: 10 }
                contentHeight: body.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: body
                    width: parent.width
                    spacing: 8

                    // CPU and the graphics card that draws the desktop side by side, the second card under them
                    RowLayout {
                        Layout.fillWidth: true
                        visible: Metrics.has("cpu") || Metrics.has("cpu_temp") || Metrics.has("gpu") || Metrics.has("gpu_temp")
                        spacing: 8
                        Chip_ {
                            visible: Metrics.has("cpu") || Metrics.has("cpu_temp")
                            title: "CPU"; loadId: "cpu"; tempId: "cpu_temp"
                            detail: Metrics.has("cpu_freq") ? Metrics.text("cpu_freq") : ""
                            cores: root.d.cpu?.cores ?? []
                        }
                        Chip_ {
                            visible: Metrics.has("gpu") || Metrics.has("gpu_temp")
                            title: "Graphics"; loadId: "gpu"; tempId: "gpu_temp"
                            detail: root.cardDetail("gpu")
                        }
                    }
                    Chip_ {
                        visible: Metrics.has("dgpu")
                        title: "Second graphics card"; loadId: "dgpu"; tempId: "dgpu_temp"
                        detail: root.cardDetail("dgpu")
                        note: Metrics.text("dgpu") === "off" ? "Powered off" : ""
                    }

                    // memory and disks
                    Tile_ {
                        Layout.fillWidth: true
                        visible: mem.implicitHeight > 0
                        implicitHeight: mem.implicitHeight + 22
                        ColumnLayout {
                            id: mem
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 11; leftMargin: 12; rightMargin: 12 }
                            spacing: 6
                            Meter { visible: Metrics.has("ram"); label: "Memory"; rid: "ram"; used: (root.d.ram?.used ?? 0) / 1024; total: (root.d.ram?.total ?? 0) / 1024 }
                            Meter { visible: Metrics.has("swap") && (root.d.swap?.total ?? 0) > 0; label: "Swap"; rid: "swap"; used: (root.d.swap?.used ?? 0) / 1024; total: (root.d.swap?.total ?? 0) / 1024 }
                            Meter { visible: Metrics.has("gpu_vram"); label: "Graphics memory"; rid: "gpu_vram"; used: (root.d.gpu?.vram_used ?? 0) / 1024; total: (root.d.gpu?.vram_total ?? 0) / 1024 }
                            Meter { visible: Metrics.has("dgpu_vram"); label: "Second card memory"; rid: "dgpu_vram"; used: (root.d.dgpu?.vram_used ?? 0) / 1024; total: (root.d.dgpu?.vram_total ?? 0) / 1024 }
                            Repeater {
                                model: Metrics.has("disk") ? root.d.disk : []
                                Meter { required property var modelData; label: "Disk " + modelData.mount; rid: "disk"; used: modelData.used; total: modelData.total }
                            }
                        }
                    }

                    // the other readings
                    Tile_ {
                        Layout.fillWidth: true
                        visible: sensorList.implicitHeight > 0
                        implicitHeight: sensorList.implicitHeight + 12
                        Column {
                            id: sensorList
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6; leftMargin: 12; rightMargin: 12 }
                            Line {
                                visible: Metrics.has("profile")
                                glyph: "\u{F04C5}"; label: "Power mode"
                                value: ({ "low-power": "Quiet", quiet: "Quiet", balanced: "Balanced", performance: "Performance" })[Metrics.text("profile")] ?? Metrics.text("profile")
                            }
                            Line {
                                visible: Metrics.has("battery")
                                glyph: "\u{F0079}"; label: "Battery"
                                value: Metrics.text("battery") + "  " + (root.d.battery?.state ?? "")
                            }
                            Line { visible: Metrics.has("battery_power") && Metrics.value("battery_power") > 0; glyph: "\u{F0E0E}"; label: root.d.battery?.state === "charging" ? "Charging at" : "Battery draw"; value: Metrics.text("battery_power") }
                            Line { visible: Metrics.has("battery_time"); glyph: "\u{F0954}"; label: root.d.battery?.state === "charging" ? "Time to full" : "Time left"; value: Metrics.text("battery_time") }
                            Line { visible: Metrics.has("net"); glyph: "\u{F05A9}"; label: root.d.net?.iface || "No network"; value: Metrics.text("net") }
                            Line { visible: Metrics.has("disk_io"); glyph: "\u{F02CA}"; label: "Disk activity"; value: Metrics.text("disk_io") }
                            Repeater {
                                model: Metrics.has("fans") ? root.d.fans : []
                                Line { required property int index; required property var modelData; glyph: "\u{F0210}"; label: `Fan ${index + 1}`; value: modelData > 0 ? modelData + " rpm" : "Off" }
                            }
                            Line { visible: Metrics.has("load"); glyph: "\u{F04C5}"; label: "Load average"; value: (root.d.load ?? []).map(l => l.toFixed(2)).join("  ") }
                            Line { visible: Metrics.has("uptime"); glyph: "\u{F0954}"; label: "Uptime"; value: Metrics.text("uptime") }
                        }
                    }

                    // top processes
                    Tile_ {
                        Layout.fillWidth: true
                        implicitHeight: procList.implicitHeight + 12
                        Column {
                            id: procList
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6; leftMargin: 12; rightMargin: 12 }
                            Item {
                                width: parent.width; height: 26
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Top processes"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
                                Text { anchors { right: parent.right; rightMargin: 64; verticalCenter: parent.verticalCenter } text: "CPU"; color: Theme.muted; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold } }
                                Text { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: "Memory"; color: Theme.muted; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold } }
                            }
                            Repeater {
                                model: root.procs
                                Item {
                                    required property var modelData
                                    width: procList.width; height: 22
                                    Text { anchors { left: parent.left; right: parent.right; rightMargin: 116; verticalCenter: parent.verticalCenter } text: modelData.name; elide: Text.ElideRight; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                                    Text { anchors { right: parent.right; rightMargin: 64; verticalCenter: parent.verticalCenter } text: modelData.cpu.toFixed(1) + "%" + (modelData.cpu >= 50 ? "!" : ""); color: modelData.cpu >= 50 ? Theme.warning : Theme.text; font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } } }
                                    Text { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: modelData.mem.toFixed(1) + "%"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } } }
                                }
                            }
                        }
                    }

                    // task manager
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: Theme.radius
                        color: tmArea.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent
                        opacity: root.taskManager ? 1 : 0.5
                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "\u{F0128}"; color: Theme.accentText; font { family: Theme.iconFont; pixelSize: 15 } }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.taskManager ? "Open " + root.taskManager.name : "No task manager installed"
                                color: Theme.accentText
                                font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
                            }
                        }
                        MouseArea { id: tmArea; anchors.fill: parent; enabled: root.taskManager !== null; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openTaskManager() }
                    }
                }
            }
        }
    }

    // ---- building blocks -------------------------------------------------------------------------
    component Tile_: Rectangle { radius: Theme.radius; color: Theme.fill }
    // a usage level: quiet ink while there is room, full ink when it is getting full, the warning near the top
    // (no accent: it marks state, and in the red themes it would read as an alarm)
    function levelColour(f) { return f >= 0.9 ? Theme.warning : f >= 0.75 ? Theme.text : Theme.subtext }

    // CPU / GPU tile: name and temperature, load bar, detail
    component Chip_: Rectangle {
        id: chip
        property string title
        property string loadId            // Metrics ids of its load and temperature
        property string tempId
        readonly property real load: Metrics.has(loadId) ? Metrics.value(loadId) / 100 : 0
        readonly property string tempMark: root.flag(tempId)
        property string detail
        property var cores: []            // per-core load, 0..100
        property string note              // replaces the load line (a sleeping card)
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: chipCol.implicitHeight + 24
        radius: Theme.radius
        color: Theme.fill
        Column {
            id: chipCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 4
            Text { width: parent.width; elide: Text.ElideRight; text: chip.title; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold } }
            Text {
                visible: Metrics.has(chip.tempId)
                text: Metrics.text(chip.tempId) + chip.tempMark
                color: root.flagTone(chip.tempMark)
                font { family: Theme.displayFont; pixelSize: Theme.fontDisplay; weight: Theme.displayWeight; features: { "tnum": 1 } }
            }
            Rectangle {
                visible: !chip.note && Metrics.has(chip.loadId)
                width: parent.width; height: 4; radius: 2
                color: Theme.fill
                Rectangle { width: Math.max(4, parent.width * chip.load); height: parent.height; radius: 2; color: root.levelColour(chip.load); Behavior on width { NumberAnimation { duration: Theme.anim } } }
            }
            Text {   // load, then the detail on its own line so neither is cut in a narrow tile
                visible: chip.note !== "" || Metrics.has(chip.loadId)
                width: parent.width
                text: chip.note || Math.round(chip.load * 100) + "% load" + root.flag(chip.loadId)
                elide: Text.ElideRight
                color: Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
            }
            Row {   // one bar per core, tall as it is busy
                visible: chip.cores.length > 0 && !chip.note
                width: parent.width; height: 14
                spacing: 2
                Repeater {
                    model: chip.cores
                    Item {
                        required property real modelData
                        width: Math.max(2, (chipCol.width - (chip.cores.length - 1) * 2) / chip.cores.length); height: 14
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: Math.max(2, parent.height * Math.min(1, parent.modelData / 100)); radius: 1; color: root.levelColour(parent.modelData / 100) }
                    }
                }
            }
            Text {
                visible: !chip.note && chip.detail !== ""
                width: parent.width
                text: chip.detail
                elide: Text.ElideRight
                color: Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
            }
        }
    }

    // a usage bar with "used / total GB"; rid is the Metrics id whose warn / critical levels it follows
    component Meter: ColumnLayout {
        id: meter
        property string label
        property string rid
        property real used: 0
        property real total: 1
        readonly property real f: total > 0 ? Math.min(1, used / total) : 0
        Layout.fillWidth: true
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; elide: Text.ElideRight; text: meter.label; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
            Text { Layout.minimumWidth: implicitWidth; text: `${meter.used.toFixed(1)} / ${meter.total.toFixed(1)} GB` + root.flagAt(meter.rid, meter.f * 100); color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } } }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6; radius: 3
            color: Theme.fill
            Rectangle {
                width: Math.max(6, parent.width * meter.f); height: parent.height; radius: 3
                color: root.levelColour(meter.f)
                Behavior on width { NumberAnimation { duration: Theme.anim } }
            }
        }
    }

    // one reading: icon, name, value
    component Line: Item {
        id: line
        property string glyph
        property string label
        property string value
        property string mark              // "!" or "!!"
        width: parent ? parent.width : 0
        height: 26
        Text { id: lg; anchors { left: parent.left; verticalCenter: parent.verticalCenter } width: 22; text: line.glyph; color: Theme.subtext; font { family: Theme.iconFont; pixelSize: 13 } }
        Text { anchors { left: lg.right; verticalCenter: parent.verticalCenter } text: line.label; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel } }
        Text { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: line.value + line.mark; color: root.flagTone(line.mark); font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium; features: { "tnum": 1 } } }
    }
}
