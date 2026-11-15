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
    readonly property var panelIds: ["cpu", "cpu_core_max", "cpu_temp", "cpu_freq", "gpu", "gpu_temp", "gpu_vram", "gpu_power",
        "dgpu", "dgpu_temp", "dgpu_vram", "dgpu_power", "ram", "swap", "disk", "disk_io", "disk_temp", "net", "net_down", "net_up",
        "battery", "battery_power", "battery_time", "fans", "profile", "uptime", "load"]
    // the Control Center's temperature line needs only the CPU temperature
    readonly property var wantIds: popup.open ? panelIds : ControlCenter.open ? ["cpu_temp"] : []
    property var asked: []
    onWantIdsChanged: { Metrics.unwant(asked); asked = wantIds; Metrics.want(asked, 2, true) }   // true: the System panel is the one reader allowed to ask the sleeping-capable card for numbers

    // "!" at the warn level, "!!" at the critical level (Metrics.registry), so colour is never the only signal
    function flagAt(id, v) {
        const r = Metrics.registry[id]
        return !r || typeof v !== "number" ? "" : r.critical !== undefined && v >= r.critical ? "!!" : r.warn !== undefined && v >= r.warn ? "!" : ""
    }
    function flag(id) { return flagAt(id, Metrics.value(id)) }
    function flagTone(f) { return f === "!!" ? Theme.error : f === "!" ? Theme.warning : Theme.text }
    readonly property var d: Metrics.data

    // Task manager: the chosen desktop id, or the first installed of these
    readonly property var taskManagers: ["net.nokyan.Resources", "io.missioncenter.MissionCenter", "org.kde.plasma-systemmonitor", "btop", "htop"]
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

    // ---- panel, under the bar at the right. The popup frame owns scrolling; this is only its content ----------
    CursorPopup {
        id: popup
        name: "system"
        placement: "topRight"
        boxWidth: Theme.panelWidth
        boxHeight: body.implicitHeight + Theme.spaceM * 2

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusPanel

            ColumnLayout {
                id: body
                anchors { fill: parent; margins: Theme.spaceM }
                spacing: Theme.spaceS + 2

                // CPU: total, one bar per core, then temperature / frequency / load
                Section_ {
                    visible: Metrics.has("cpu") || Metrics.has("cpu_temp")
                    title: "CPU"
                    value: Metrics.has("cpu") ? Metrics.text("cpu") + root.flag("cpu") : ""
                    tone: root.flagTone(root.flag("cpu"))
                    Row {
                        visible: cores.length > 0
                        readonly property var cores: root.d.cpu?.cores ?? []
                        Layout.fillWidth: true
                        height: 20
                        spacing: 2
                        Repeater {
                            model: parent.cores
                            Item {
                                required property real modelData
                                width: Math.max(2, (body.width - (parent.cores.length - 1) * 2) / parent.cores.length); height: 20
                                Rectangle { anchors.fill: parent; radius: 1; color: Theme.fill }
                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: Math.max(2, parent.height * Math.min(1, parent.modelData / 100)); radius: 1; color: root.levelColour(parent.modelData / 100) }
                            }
                        }
                    }
                    Facts_ {
                        items: [
                            Metrics.has("cpu_temp") ? { k: "Temp", v: Metrics.text("cpu_temp") + root.flag("cpu_temp") } : null,
                            Metrics.has("cpu_freq") ? { k: "Clock", v: Metrics.text("cpu_freq") } : null,
                            Metrics.has("load") ? { k: "Load", v: (root.d.load ?? []).map(l => l.toFixed(2)).join(" ") } : null
                        ]
                    }
                }

                Section_ {
                    visible: Metrics.has("ram") || Metrics.has("swap")
                    title: "Memory"
                    value: Metrics.has("ram") ? ((root.d.ram?.used ?? 0) / 1024).toFixed(1) + " GB" : ""
                    Meter_ { visible: Metrics.has("ram"); label: "RAM"; rid: "ram"; used: (root.d.ram?.used ?? 0) / 1024; total: (root.d.ram?.total ?? 0) / 1024 }
                    Meter_ { visible: Metrics.has("swap") && (root.d.swap?.total ?? 0) > 0; label: "Swap"; rid: "swap"; used: (root.d.swap?.used ?? 0) / 1024; total: (root.d.swap?.total ?? 0) / 1024 }
                }

                Section_ {
                    visible: Metrics.has("gpu") || Metrics.has("gpu_temp") || Metrics.has("dgpu")
                    title: "Graphics"
                    // one row per card in fixed columns (the label column, then tabular values); shared memory is a use, never a percentage
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 5
                        columnSpacing: Theme.spaceS
                        rowSpacing: 4
                        Item { Layout.preferredWidth: 72 }
                        Repeater {
                            model: ["Load", "Temp", "Power", "Shared"]
                            Text { required property string modelData; Layout.fillWidth: true; Layout.preferredWidth: 1; horizontalAlignment: Text.AlignRight; text: modelData; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                        }
                        Text { visible: Metrics.has("gpu") || Metrics.has("gpu_temp"); Layout.preferredWidth: 72; text: "Built-in"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium } }
                        Repeater {
                            model: [Metrics.has("gpu") ? Metrics.text("gpu") + root.flag("gpu") : "–", Metrics.has("gpu_temp") ? Metrics.text("gpu_temp") + root.flag("gpu_temp") : "–",
                                    Metrics.has("gpu_power") ? Metrics.text("gpu_power") : "–", Metrics.has("gpu_vram") ? Metrics.text("gpu_vram") : "–"]
                            Text { required property string modelData; visible: Metrics.has("gpu") || Metrics.has("gpu_temp"); Layout.fillWidth: true; Layout.preferredWidth: 1; horizontalAlignment: Text.AlignRight; text: modelData; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium; features: { "tnum": 1 } } }
                        }
                        // second card: "Sleeping" while powered down; numbers only while it is awake (and the panel is open)
                        Text { visible: Metrics.has("dgpu"); Layout.preferredWidth: 72; text: "Discrete"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium } }
                        Text {
                            visible: Metrics.has("dgpu") && !root.d.dgpu_live
                            Layout.columnSpan: 4; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight
                            text: ({ suspended: "Sleeping", suspending: "Sleeping", resuming: "Waking", active: "Awake" })[root.d.dgpu?.state] ?? (root.d.dgpu?.state ?? "")
                            color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontLabel }
                        }
                        Repeater {
                            model: !root.d.dgpu_live ? [] : [Metrics.text("dgpu") + root.flag("dgpu"), Metrics.has("dgpu_temp") ? Metrics.text("dgpu_temp") + root.flag("dgpu_temp") : "–",
                                    Metrics.has("dgpu_power") ? Metrics.text("dgpu_power") : "–", "–"]
                            Text { required property string modelData; visible: Metrics.has("dgpu"); Layout.fillWidth: true; Layout.preferredWidth: 1; horizontalAlignment: Text.AlignRight; text: modelData; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium; features: { "tnum": 1 } } }
                        }
                    }
                    Meter_ { visible: Metrics.has("dgpu_vram") && (root.d.dgpu_live?.vram_total ?? 0) > 0; label: "Video memory"; rid: "dgpu_vram"; used: (root.d.dgpu_live?.vram_used ?? 0) / 1024; total: (root.d.dgpu_live?.vram_total ?? 0) / 1024 }
                }

                Section_ {
                    visible: Metrics.has("disk") || Metrics.has("disk_io")
                    title: "Storage"
                    value: Metrics.has("disk_temp") ? "Disk " + Metrics.text("disk_temp") + root.flag("disk_temp") : ""
                    Repeater {
                        model: Metrics.has("disk") ? root.d.disk : []
                        Meter_ { required property var modelData; label: modelData.mount; rid: "disk"; used: modelData.used; total: modelData.total }
                    }
                    Facts_ {
                        visible: Metrics.has("disk_io")
                        items: [
                            { k: "Read", v: Metrics.bytes(root.d.diskio?.read ?? 0) + "/s" },
                            { k: "Write", v: Metrics.bytes(root.d.diskio?.write ?? 0) + "/s" }
                        ]
                    }
                }

                Section_ {
                    visible: Metrics.has("net")
                    title: "Network"
                    value: root.d.net?.iface ?? ""
                    Facts_ {
                        items: [
                            { k: "Down", v: Metrics.bytes(root.d.net?.down ?? 0) + "/s" },
                            { k: "Up", v: Metrics.bytes(root.d.net?.up ?? 0) + "/s" }
                        ]
                    }
                    Row {   // the last readings of the download rate, scaled to the busiest of them
                        readonly property var h: Metrics.history["net_down"] ?? []
                        visible: h.length >= 20
                        Layout.fillWidth: true
                        height: 14
                        spacing: 2
                        Repeater {
                            model: parent.h
                            Item {
                                required property real modelData
                                width: Math.max(2, (body.width - (Metrics.keep - 1) * 2) / Metrics.keep); height: 14
                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: Math.max(2, parent.height * parent.modelData / Math.max(1, ...Metrics.history["net_down"])); radius: 1; color: Theme.subtext }
                            }
                        }
                    }
                }

                Section_ {
                    visible: Metrics.has("battery") || Metrics.has("profile") || Metrics.has("fans") || Metrics.has("uptime")
                    title: "System"
                    Facts_ {
                        items: [
                            Metrics.has("battery") ? { k: "Battery", v: Metrics.text("battery") + " " + (root.d.battery?.state ?? "") } : null,
                            Metrics.has("battery_power") && Metrics.value("battery_power") >= 1 ? { k: root.d.battery?.state === "charging" ? "In" : "Draw", v: Metrics.text("battery_power") } : null,
                            Metrics.has("battery_time") ? { k: root.d.battery?.state === "charging" ? "To full" : "Left", v: Metrics.text("battery_time") } : null,
                            Metrics.has("profile") ? { k: "Mode", v: ({ "low-power": "Silent", quiet: "Silent", balanced: "Balanced", performance: "Performance" })[Metrics.text("profile")] ?? Metrics.text("profile") } : null,
                            Metrics.has("fans") ? { k: "Fans", v: (root.d.fans ?? []).map(f => f > 0 ? f : "off").join(" / ") } : null,
                            Metrics.has("uptime") ? { k: "Up", v: Metrics.text("uptime") } : null
                        ]
                    }
                }

                Section_ {
                    title: "Top processes"
                    value: root.taskManager ? "Open " + root.taskManager.name : ""
                    tone: Theme.accent
                    linkValue: true
                    onValueClicked: root.openTaskManager()
                    visible: root.procs.length > 0
                    Repeater {
                        model: root.procs
                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: Theme.spaceS
                            Text { Layout.fillWidth: true; text: modelData.name; elide: Text.ElideRight; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                            Text { Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight; text: modelData.cpu.toFixed(1) + "%"; color: modelData.cpu >= 50 ? Theme.warning : Theme.text; font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } } }
                            Text { Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight; text: modelData.mem.toFixed(1) + "%"; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } } }
                        }
                    }
                }
            }
        }
    }

    // ---- building blocks -------------------------------------------------------------------------
    // a usage level: quiet ink while there is room, full ink when it is getting full, the warning near the top
    // (no accent: it marks state, and in the red themes it would read as an alarm)
    function levelColour(f) { return f >= 0.9 ? Theme.warning : f >= 0.75 ? Theme.text : Theme.subtext }

    // a titled block: caption on the left, its headline figure on the right, then its content
    component Section_: ColumnLayout {
        id: sec
        property string title
        property string value
        property color tone: Theme.text
        signal valueClicked()
        property bool linkValue: false
        default property alias content: inner.data
        Layout.fillWidth: true
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: sec.title; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold; capitalization: Font.AllUppercase; letterSpacing: 0.6 } }
            Text {
                visible: sec.value !== ""; text: sec.value; color: sec.tone; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold; features: { "tnum": 1 } }
                MouseArea { Accessible.role: Accessible.Button; Accessible.name: sec.value; Accessible.onPressAction: sec.valueClicked(); anchors.fill: parent; enabled: sec.linkValue; cursorShape: Qt.PointingHandCursor; onClicked: sec.valueClicked() }
            }
        }
        ColumnLayout { id: inner; Layout.fillWidth: true; spacing: 6 }
    }

    // "Label  value" pairs on one wrapping line; null entries (readings this computer lacks) are skipped.
    // With `state` set and nothing else to show it reads "lead  state" (a card that is asleep).
    component Facts_: Flow {
        id: facts
        property var items: []
        property string lead
        property string status
        property bool sleeping: false
        Layout.fillWidth: true
        spacing: Theme.spaceM
        Text { visible: facts.lead !== ""; text: facts.lead; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium } }
        Text { visible: facts.status !== ""; text: facts.status; color: facts.sleeping ? Theme.subtext : Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; features: { "tnum": 1 } } }
        Repeater {
            model: facts.items.filter(x => x)
            Row {
                required property var modelData
                spacing: 4
                Text { text: modelData.k; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontLabel } }
                Text { text: modelData.v; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium; features: { "tnum": 1 } } }
            }
        }
    }

    // a usage bar with "used / total GB"; rid is the Metrics id whose warn / critical levels it follows
    component Meter_: ColumnLayout {
        id: meter
        property string label
        property string rid
        property real used: 0
        property real total: 1
        readonly property real f: total > 0 ? Math.min(1, used / total) : 0
        Layout.fillWidth: true
        spacing: 3
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; elide: Text.ElideRight; text: meter.label; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel } }
            Text { text: `${meter.used.toFixed(1)} / ${meter.total.toFixed(1)} GB` + root.flagAt(meter.rid, meter.f * 100); color: root.flagTone(root.flagAt(meter.rid, meter.f * 100)); font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } } }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 4; radius: 2
            color: Theme.fill
            Rectangle { width: Math.max(4, parent.width * meter.f); height: parent.height; radius: 2; color: root.levelColour(meter.f); Behavior on width { NumberAnimation { duration: Theme.anim } } }
        }
    }
}
