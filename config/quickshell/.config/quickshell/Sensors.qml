pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// The system dropdown (opened by the cpu / memory / gpu / system-info bar items): every reading this computer
// has, taken from the Metrics service (which measures only while something visible asks), plus the top
// processes and a button for the task manager (Settings > Default Applications, Ctrl+Shift+Esc).
// Layout: four vitals first (CPU, memory, graphics, battery: big figures with a meter each), then the detail in
// titled sections whose figures sit in one four-column grid, each with its label above it.
// A reading the computer lacks does not appear. Warn / critical levels come from Metrics.registry: a vital says
// it in words ("Hot", "Busy"), a detail figure gets "!" / "!!", so a warning never rests on colour alone.
Singleton {
    id: root

    // thin aliases for callers outside this file (the Control Center hardware tile)
    readonly property real cpu: Metrics.has("cpu_temp") ? Metrics.value("cpu_temp") : NaN
    readonly property real gpu: Metrics.has("gpu_temp") ? Metrics.value("gpu_temp") : NaN
    readonly property bool open: popup.open
    property var procs: []            // [{ name, cpu, mem }]
    property bool procsShown: false   // Top processes starts folded so the panel fits a laptop screen

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
    // a meter's fill: the accent while there is room (ink where the accent is red, so it never reads as an alarm), then the levels
    function fillTone(f) { return f === "!!" ? Theme.error : f === "!" ? Theme.warning : Theme.accentLikeError ? Theme.text : Theme.accent }
    // a vital's word for its worst reading: pairs of [id, word at warn, word at critical]
    function says(pairs) {
        let word = "", worst = 0
        for (const p of pairs) { const f = flag(p[0]); if (f.length > worst) { worst = f.length; word = f === "!!" ? p[2] : p[1] } }
        return { word, tone: flagTone("!!".slice(0, worst)) }
    }
    function temp(id) { return Metrics.has(id) ? Metrics.text(id) + "C" : "" }
    function rate(n) { return Metrics.bytes(n).replace(/([KMG])?B?$/, " $1B/s") }   // 39K -> "39 KB/s"
    function gb(mb) { return (mb / 1024).toFixed(1) }
    readonly property var d: Metrics.data
    // the vitals' graphics card: the second card when it is awake and the busier one, else the built-in one
    readonly property string g: d.dgpu_live && (d.dgpu_live.pct ?? 0) > (d.gpu?.pct ?? 0) ? "dgpu" : "gpu"

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
        boxWidth: Theme.panelWide
        boxHeight: body.implicitHeight + Theme.spaceM * 2

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusPanel

            ColumnLayout {
                id: body
                anchors { fill: parent; margins: Theme.spaceM }
                spacing: Theme.spaceM

                // ---- vitals: the numbers that matter, big and first
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Theme.spaceL
                    rowSpacing: Theme.spaceM

                    Vital_ {
                        visible: Metrics.has("cpu") || Metrics.has("cpu_temp")
                        title: "CPU"
                        state_: root.says([["cpu_temp", "Hot", "Too hot"], ["cpu", "Busy", "Maxed out"]])
                        big: Metrics.text("cpu"); bigTone: root.flagTone(root.flag("cpu"))
                        second: root.temp("cpu_temp"); secondTone: root.flagTone(root.flag("cpu_temp"))
                        fill: Metrics.has("cpu") ? Metrics.value("cpu") / 100 : -1; fillFlag: root.flag("cpu")
                        note: Metrics.has("cpu_freq") ? "Clock " + Metrics.text("cpu_freq").replace("GHz", " GHz") : ""
                    }
                    Vital_ {
                        visible: Metrics.has("ram")
                        title: "Memory"
                        state_: root.says([["ram", "Nearly full", "Full"]])
                        big: root.gb(root.d.ram?.used ?? 0); bigTone: root.flagTone(root.flag("ram"))
                        second: "of " + root.gb(root.d.ram?.total ?? 0) + " GB"; secondTone: Theme.subtext
                        fill: Metrics.value("ram") / 100; fillFlag: root.flag("ram")
                        note: Metrics.has("swap") && (root.d.swap?.total ?? 0) > 0 ? `Swap ${root.gb(root.d.swap.used)} of ${root.gb(root.d.swap.total)} GB` + root.flag("swap") : ""
                        noteTone: root.flag("swap") ? root.flagTone(root.flag("swap")) : Theme.subtext
                    }
                    Vital_ {
                        visible: Metrics.has(root.g)
                        title: "Graphics"
                        state_: root.says([[root.g + "_temp", "Hot", "Too hot"], [root.g, "Busy", "Maxed out"]])
                        big: Metrics.text(root.g); bigTone: root.flagTone(root.flag(root.g))
                        second: root.temp(root.g + "_temp"); secondTone: root.flagTone(root.flag(root.g + "_temp"))
                        fill: Metrics.value(root.g) / 100; fillFlag: root.flag(root.g)
                        note: (root.g === "dgpu" ? root.d.dgpu?.name : root.d.gpu?.name) ?? ""
                    }
                    Vital_ {
                        visible: Metrics.has("battery")
                        readonly property string st: root.d.battery?.state ?? ""
                        title: "Battery"
                        state_: ({ word: st.charAt(0).toUpperCase() + st.slice(1), tone: Theme.subtext })   // its state, not a warning
                        big: Metrics.text("battery")
                        second: Metrics.has("battery_power") && Metrics.value("battery_power") >= 1 ? Metrics.text("battery_power").replace("W", " W") : ""
                        secondTone: Theme.subtext
                        fill: Metrics.value("battery") / 100
                        note: Metrics.has("battery_time") ? Metrics.text("battery_time") + (st === "charging" ? " to full" : " left") : ""
                    }
                }

                // ---- CPU: one bar per core, then the busiest core and the load averages
                Section_ {
                    visible: (root.d.cpu?.cores?.length ?? 0) > 0 || Metrics.has("load")
                    title: "Processor"
                    value: (root.d.cpu?.cores?.length ?? 0) > 0 ? root.d.cpu.cores.length + " threads" : ""
                    Row {
                        visible: cores.length > 0
                        readonly property var cores: root.d.cpu?.cores ?? []
                        Layout.fillWidth: true
                        height: 18
                        spacing: 2
                        Repeater {
                            model: parent.cores
                            Item {
                                required property real modelData
                                width: Math.max(2, (body.width - (parent.cores.length - 1) * 2) / parent.cores.length); height: 18
                                Rectangle { anchors.fill: parent; radius: Math.min(2, Theme.radiusSmall); color: Theme.fill }
                                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: Math.max(2, parent.height * Math.min(1, parent.modelData / 100)); radius: Math.min(2, Theme.radiusSmall); color: root.fillTone(root.flagAt("cpu_core_max", parent.modelData)) }
                            }
                        }
                    }
                    Stats_ {
                        items: [
                            Metrics.has("cpu_core_max") ? { k: "Busiest core", v: Metrics.text("cpu_core_max") + root.flag("cpu_core_max"), f: root.flag("cpu_core_max") } : null,
                            Metrics.has("load") ? { k: "Load, 1 min", v: root.d.load[0].toFixed(2) } : null,
                            Metrics.has("load") ? { k: "5 min", v: (root.d.load[1] ?? 0).toFixed(2) } : null,
                            Metrics.has("load") ? { k: "15 min", v: (root.d.load[2] ?? 0).toFixed(2) } : null
                        ]
                    }
                }

                // ---- graphics: each card by its real name (PCI ids), chip and driver, then its numbers;
                // shared memory is a use, never a percentage. The second card shows only its name while asleep.
                Section_ {
                    visible: Metrics.has("gpu") || Metrics.has("gpu_temp") || Metrics.has("dgpu")
                    title: "Graphics"
                    Card_ {
                        visible: Metrics.has("gpu") || Metrics.has("gpu_temp")
                        info: root.d.gpu ?? ({})
                        fallback: "Built-in graphics"
                        status: root.d.gpu?.mhz ? root.d.gpu.mhz + " MHz" : ""
                        items: [{ k: "Load", v: Metrics.has("gpu") ? Metrics.text("gpu") + root.flag("gpu") : "–", f: root.flag("gpu") },
                                { k: "Temperature", v: Metrics.has("gpu_temp") ? root.temp("gpu_temp") + root.flag("gpu_temp") : "–", f: root.flag("gpu_temp") },
                                { k: "Power", v: Metrics.has("gpu_power") ? Metrics.text("gpu_power").replace("W", " W") : "–" },
                                { k: "Shared mem", v: Metrics.has("gpu_vram") ? Metrics.text("gpu_vram").replace("G", " GB") : "–" }]
                    }
                    Card_ {
                        visible: Metrics.has("dgpu")
                        info: root.d.dgpu ?? ({})
                        fallback: "Second graphics card"
                        status: root.d.dgpu_live?.mhz ? root.d.dgpu_live.mhz + " MHz"
                            : (({ suspended: "Sleeping", suspending: "Sleeping", resuming: "Waking", active: "Awake" })[root.d.dgpu?.state] ?? (root.d.dgpu?.state ?? ""))
                        items: !root.d.dgpu_live ? [] : [{ k: "Load", v: Metrics.text("dgpu") + root.flag("dgpu"), f: root.flag("dgpu") },
                                { k: "Temperature", v: Metrics.has("dgpu_temp") ? root.temp("dgpu_temp") + root.flag("dgpu_temp") : "–", f: root.flag("dgpu_temp") },
                                { k: "Power", v: Metrics.has("dgpu_power") ? Metrics.text("dgpu_power").replace("W", " W") : "–" },
                                { k: "Video mem", v: root.gb(root.d.dgpu_live.vram_used) + " / " + (root.d.dgpu_live.vram_total / 1024).toFixed(0) + " GB" + root.flag("dgpu_vram"), f: root.flag("dgpu_vram") }]
                    }
                }

                // ---- storage: one meter per mount, the drive's temperature in the heading
                Section_ {
                    visible: Metrics.has("disk")
                    title: "Storage"
                    value: Metrics.has("disk_temp") ? "Drive " + root.temp("disk_temp") + root.flag("disk_temp") : ""
                    tone: root.flagTone(root.flag("disk_temp"))
                    Repeater {
                        model: Metrics.has("disk") ? root.d.disk : []
                        Meter_ { required property var modelData; label: modelData.mount; rid: "disk"; used: modelData.used; total: modelData.total }
                    }
                }

                // ---- activity: network and disk transfer side by side, the download history under them
                Section_ {
                    visible: Metrics.has("net") || Metrics.has("disk_io")
                    title: "Activity"
                    value: [root.d.net?.iface ?? "", Sys.netName ?? ""].filter(x => x).join(" · ")
                    Stats_ {
                        items: [
                            Metrics.has("net") ? { k: "Download", v: root.rate(root.d.net?.down ?? 0) } : null,
                            Metrics.has("net") ? { k: "Upload", v: root.rate(root.d.net?.up ?? 0) } : null,
                            Metrics.has("disk_io") ? { k: "Disk read", v: root.rate(root.d.diskio?.read ?? 0) } : null,
                            Metrics.has("disk_io") ? { k: "Disk write", v: root.rate(root.d.diskio?.write ?? 0) } : null
                        ]
                    }
                    RowLayout {   // the last readings of the download rate, scaled to the busiest of them
                        visible: Metrics.has("net") && spark.h.length >= 20
                        Layout.fillWidth: true
                        spacing: Theme.spaceS
                        Text { text: "Download, last " + Metrics.keep * Metrics.interval + " s"; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                        Row {
                            id: spark
                            readonly property var h: Metrics.history["net_down"] ?? []
                            Layout.fillWidth: true
                            height: 14
                            spacing: 2
                            Repeater {
                                model: spark.h
                                Item {
                                    required property real modelData
                                    width: Math.max(2, (spark.width - (Metrics.keep - 1) * 2) / Metrics.keep); height: 14
                                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: Math.max(2, parent.height * parent.modelData / Math.max(1, ...spark.h)); radius: 1; color: Theme.subtext }
                                }
                            }
                        }
                    }
                }

                // ---- the rest of the machine
                Section_ {
                    visible: Metrics.has("profile") || Metrics.has("fans") || Metrics.has("uptime")
                    title: "System"
                    value: Metrics.has("uptime") ? "Uptime " + Metrics.text("uptime") : ""
                    Stats_ {
                        items: [
                            Metrics.has("profile") ? { k: "Power mode", v: ({ "low-power": "Silent", quiet: "Silent", balanced: "Balanced", performance: "Performance" })[Metrics.text("profile")] ?? Metrics.text("profile"), span: 2 } : null,
                            Metrics.has("fans") ? { k: (root.d.fans ?? []).length > 1 ? "Fans, rpm" : "Fan, rpm", v: (root.d.fans ?? []).map(f => f > 0 ? f : "off").join(" · "), span: 2 } : null
                        ]
                    }
                }

                // ---- top processes, folded by default; the task manager link stays in the heading
                Section_ {
                    title: "Top processes"
                    value: root.taskManager ? "Open " + root.taskManager.name : ""
                    tone: Theme.accentLikeError ? Theme.text : Theme.accent
                    linkValue: true
                    onValueClicked: root.openTaskManager()
                    foldable: true
                    unfolded: root.procsShown
                    onFoldClicked: root.procsShown = !root.procsShown
                    visible: root.procs.length > 0
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spaceS
                        Text { Layout.fillWidth: true; text: "Process"; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                        Text { Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight; text: "CPU"; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                        Text { Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight; text: "Memory"; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                    }
                    Repeater {
                        model: root.procs
                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: Theme.spaceS
                            Text { Layout.fillWidth: true; text: modelData.name; elide: Text.ElideRight; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel } }
                            Text { Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight; text: modelData.cpu.toFixed(1) + "%"; color: modelData.cpu >= 50 ? Theme.warning : Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; features: { "tnum": 1 } } }
                            Text { Layout.preferredWidth: 52; horizontalAlignment: Text.AlignRight; text: modelData.mem.toFixed(1) + "%"; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontLabel; features: { "tnum": 1 } } }
                        }
                    }
                }
            }
        }
    }

    // ---- building blocks -------------------------------------------------------------------------
    component Caption_: Text { color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold; capitalization: Font.AllUppercase; letterSpacing: 0.6 } }

    // one vital: its name and, at a warning, the word for it; the big figure and a second one; a meter; one line of context
    component Vital_: ColumnLayout {
        id: vit
        property string title
        property var state_: ({ word: "", tone: Theme.text })
        property string big
        property color bigTone: Theme.text
        property string second
        property color secondTone: Theme.subtext
        property real fill: -1                 // 0..1; below 0 there is no meter
        property string fillFlag
        property string note
        property color noteTone: Theme.subtext
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.alignment: Qt.AlignTop
        spacing: Theme.spaceXs
        RowLayout {
            Layout.fillWidth: true
            Caption_ { Layout.fillWidth: true; text: vit.title }
            Text { visible: text !== ""; text: vit.state_.word; color: vit.state_.tone; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold } }
        }
        Row {
            spacing: Theme.spaceS
            Text {
                id: bigText
                text: vit.big || "–"; color: vit.bigTone
                font { family: Theme.displayFont; pixelSize: Theme.fontDisplay; weight: Theme.displayWeight; features: { "tnum": 1 } }
            }
            Text {
                visible: vit.second !== ""
                anchors.baseline: bigText.baseline
                text: vit.second; color: vit.secondTone
                font { family: Theme.displayFont; pixelSize: Theme.fontTitle; weight: Theme.displayWeight; features: { "tnum": 1 } }
            }
        }
        Bar_ { visible: vit.fill >= 0; f: vit.fill; tone: root.fillTone(vit.fillFlag) }
        Text {
            visible: text !== ""; Layout.fillWidth: true; elide: Text.ElideRight
            text: vit.note; color: vit.noteTone
            font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
        }
    }

    // a meter's track and fill
    component Bar_: Rectangle {
        property real f: 0
        property color tone: Theme.accent
        Layout.fillWidth: true
        implicitHeight: 5; radius: Math.min(height / 2, Theme.radiusSmall)
        color: Theme.fill
        Rectangle { width: Math.max(height, parent.width * Math.min(1, Math.max(0, parent.f))); height: parent.height; radius: parent.radius; color: parent.tone; Behavior on width { NumberAnimation { duration: Theme.anim } } }
    }

    // a titled block: caption on the left, its headline figure (or link) on the right, then its content.
    // foldable: the caption toggles the content and carries a chevron
    component Section_: ColumnLayout {
        id: sec
        property string title
        property string value
        property color tone: Theme.text
        signal valueClicked()
        signal foldClicked()
        property bool linkValue: false
        property bool foldable: false
        property bool unfolded: true
        default property alias content: inner.data
        Layout.fillWidth: true
        spacing: Theme.spaceS
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.stroke }   // the rule that opens every detail section
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceXs
            Caption_ {
                text: sec.title
                color: foldArea.containsMouse ? Theme.text : Theme.subtext
                MouseArea {
                    id: foldArea
                    anchors.fill: parent; anchors.margins: -4
                    enabled: sec.foldable; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button; Accessible.name: (sec.unfolded ? "Hide " : "Show ") + sec.title; Accessible.onPressAction: sec.foldClicked()
                    onClicked: sec.foldClicked()
                }
            }
            Chevron { visible: sec.foldable; open: sec.unfolded; size: Theme.fontLabel }
            Item { Layout.fillWidth: true }
            Text {
                visible: sec.value !== ""; text: sec.value; color: sec.tone
                font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold; features: { "tnum": 1 } }
                MouseArea { Accessible.role: Accessible.Button; Accessible.name: sec.value; Accessible.onPressAction: sec.valueClicked(); anchors.fill: parent; enabled: sec.linkValue; cursorShape: Qt.PointingHandCursor; onClicked: sec.valueClicked() }
            }
        }
        ColumnLayout { id: inner; visible: sec.unfolded; Layout.fillWidth: true; spacing: Theme.spaceS }
    }

    // figures in the panel's one four-column grid: a label over each value; null entries (readings this computer
    // lacks) are skipped, `span` widens a cell, `f` (a flag) colours the value
    component Stats_: GridLayout {
        id: st
        property var items: []
        readonly property real cell: (body.width - 3 * columnSpacing) / 4
        Layout.fillWidth: true
        columns: 4
        columnSpacing: Theme.spaceS
        rowSpacing: Theme.spaceS
        Repeater {
            model: st.items.filter(x => x)
            ColumnLayout {
                required property var modelData
                readonly property int span: modelData.span ?? 1
                Layout.columnSpan: span
                Layout.preferredWidth: st.cell * span + (span - 1) * st.columnSpacing
                Layout.maximumWidth: Layout.preferredWidth
                spacing: 1
                Text { Layout.fillWidth: true; elide: Text.ElideRight; text: modelData.k; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                Text { Layout.fillWidth: true; elide: Text.ElideRight; text: modelData.v; color: root.flagTone(modelData.f ?? ""); font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium; features: { "tnum": 1 } } }
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
        readonly property string level: root.flagAt(rid, f * 100)
        Layout.fillWidth: true
        spacing: Theme.spaceXs
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; elide: Text.ElideRight; text: meter.label; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel } }
            Text { text: `${meter.used.toFixed(1)} of ${meter.total.toFixed(1)} GB` + meter.level; color: meter.level ? root.flagTone(meter.level) : Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } } }
        }
        Bar_ { f: meter.f; tone: root.fillTone(meter.level) }
    }

    // one graphics card: real name and its state on one line, chip and driver under it, then its numbers (id: not `gc`, a JavaScript global)
    component Card_: ColumnLayout {
        id: gcard
        property var info: ({})
        property string fallback
        property string status
        property var items: []
        Layout.fillWidth: true
        spacing: 2
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceS
            Text { Layout.fillWidth: true; text: gcard.info.name ?? gcard.fallback; elide: Text.ElideRight; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium } }
            Text { text: gcard.status; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } } }
        }
        Text {
            visible: text !== ""
            text: [gcard.info.chip, gcard.info.driver].filter(x => x).join(" · ")
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
        Stats_ { visible: gcard.items.length > 0; Layout.topMargin: Theme.spaceXs; items: gcard.items }
    }
}
