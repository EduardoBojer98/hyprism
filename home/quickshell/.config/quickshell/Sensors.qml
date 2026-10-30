pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// CPU (k10temp) and GPU (amdgpu) temperatures for the bar, every 3 seconds. Clicking them opens
// the system dropdown: load, memory, every temperature and fan, the top processes, and a button for
// the task manager (Settings > Default Applications, Ctrl+Shift+Esc). The extra readings run only
// while the dropdown is open. The NVIDIA GPU is read only when it is already awake: asking a
// sleeping one would wake it and cost battery.
Singleton {
    id: root

    property real cpu: NaN
    property real gpu: NaN
    readonly property bool open: popup.open

    // dropdown readings
    property real cpuLoad: 0          // 0..1
    property real cpuGhz: 0
    property real gpuLoad: 0          // amdgpu busy, 0..1
    property real vramUsed: 0         // GiB
    property real vramTotal: 0
    property real memUsed: 0          // GiB
    property real memTotal: 0
    property real swapUsed: 0
    property real swapTotal: 0
    property var fans: []             // rpm
    property real ssd: NaN
    property real wifi: NaN
    property real watts: NaN          // battery charge / discharge
    property string nvState: ""       // "active", "suspended", "" (none)
    property var nv: null             // { temp, load, mem, power } while awake
    property var procs: []            // [{ name, cpu, mem }]
    property var lastStat: null

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

    Process {
        id: read
        // hwmon numbers change between boots, so find the sensors by name each time
        command: ["sh", "-c", "for n in k10temp amdgpu; do h=$(grep -lx $n /sys/class/hwmon/*/name | head -1); "
                            + "cat ${h%name}temp1_input 2>/dev/null || echo nan; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim().split("\n").map(x => parseInt(x) / 1000)
                root.cpu = v[0]
                root.gpu = v[1]
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: read.running = true }

    // Everything else, as "key value…" lines
    Process {
        id: detail
        command: ["sh", "-c", `
            hw() { grep -lx "$1" /sys/class/hwmon/*/name 2>/dev/null | head -1 | sed 's/name$//'; }
            head -1 /proc/stat
            awk '/MemTotal|MemAvailable|SwapTotal|SwapFree/ {print $1, $2}' /proc/meminfo
            echo freq $(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | awk '{s+=$1; n++} END {if (n) print s/n}')
            for c in /sys/class/drm/card*/device; do
                [ -f $c/gpu_busy_percent ] && echo gpubusy $(cat $c/gpu_busy_percent) $(cat $c/mem_info_vram_used 2>/dev/null) $(cat $c/mem_info_vram_total 2>/dev/null) && break
            done
            a=$(hw asus); [ -n "$a" ] && echo fans $(cat $a/fan*_input 2>/dev/null)
            n=$(hw nvme); [ -n "$n" ] && echo ssd $(cat $n/temp1_input)
            w=$(hw iwlwifi_1); [ -n "$w" ] && echo wifi $(cat $w/temp1_input)
            b=$(hw BAT0); [ -n "$b" ] && echo watts $(cat $b/power1_input 2>/dev/null)
            for d in /sys/bus/pci/devices/*; do
                if [ "$(cat $d/vendor)" = 0x10de ] && [ "$(cat $d/class)" != 0x040300 ]; then
                    s=$(cat $d/power/runtime_status); echo nvstate $s
                    [ "$s" = active ] && command -v nvidia-smi >/dev/null && echo nv $(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,memory.used,power.draw --format=csv,noheader,nounits | tr -d ' ' | tr ',' ' ')
                    break
                fi
            done
            # current use (top's second sample), as a share of the whole CPU like Windows shows it
            n=$(nproc)
            top -b -n 2 -d 0.4 -o %CPU -w 512 | awk -v n=$n '/^ *PID /{h++; next} h==2 && NF>=12 && c<6 {printf "proc %s %.1f %s\\n", $12, $9/n, $10; c++}'
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const procs = []
                let nvState = "", nv = null
                for (const line of text.trim().split("\n")) {
                    const p = line.trim().split(/\s+/)
                    const k = p[0]
                    if (k === "cpu") {
                        const t = p.slice(1).map(Number), idle = t[3] + t[4], all = t.reduce((a, b) => a + b, 0)
                        if (root.lastStat) root.cpuLoad = Math.max(0, Math.min(1, 1 - (idle - root.lastStat.idle) / Math.max(1, all - root.lastStat.all)))
                        root.lastStat = { idle, all }
                    }
                    else if (k === "MemTotal:") root.memTotal = p[1] / 1048576
                    else if (k === "MemAvailable:") root.memUsed = root.memTotal - p[1] / 1048576
                    else if (k === "SwapTotal:") root.swapTotal = p[1] / 1048576
                    else if (k === "SwapFree:") root.swapUsed = root.swapTotal - p[1] / 1048576
                    else if (k === "freq") root.cpuGhz = Number(p[1] ?? 0) / 1e6
                    else if (k === "gpubusy") { root.gpuLoad = Number(p[1]) / 100; root.vramUsed = Number(p[2] ?? 0) / 1073741824; root.vramTotal = Number(p[3] ?? 0) / 1073741824 }
                    else if (k === "fans") root.fans = p.slice(1).map(Number)
                    else if (k === "ssd") root.ssd = Number(p[1]) / 1000
                    else if (k === "wifi") root.wifi = Number(p[1]) / 1000
                    else if (k === "watts") root.watts = Number(p[1]) / 1e6
                    else if (k === "nvstate") nvState = p[1]
                    else if (k === "nv") nv = { temp: Number(p[1]), load: Number(p[2]) / 100, mem: Number(p[3]), power: Number(p[4]) }
                    else if (k === "proc") procs.push({ name: p[1], cpu: Number(p[2]), mem: Number(p[3]) })
                }
                // top lists itself; drop our own helpers
                root.procs = procs.filter(x => !["top", "sh", "awk"].includes(x.name)).slice(0, 5)
                root.nvState = nvState
                root.nv = nv
            }
        }
    }
    Timer { interval: 2000; running: popup.open; repeat: true; triggeredOnStart: true; onTriggered: detail.running = true }

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
        boxHeight: Math.min(body.implicitHeight + 20, (popup.targetScreen?.height ?? 1000) - popup.topReserve - popup.edge * 2)
        onOpened: root.lastStat = null

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusLarge + 4

            Flickable {
                anchors { fill: parent; margins: 10 }
                contentHeight: body.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: body
                    width: parent.width
                    spacing: 8

                    // CPU and GPU side by side: temperature, load, then clock or video memory
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Chip_ { title: "CPU"; temp: root.cpu; load: root.cpuLoad; detail: root.cpuGhz > 0 ? root.cpuGhz.toFixed(1) + " GHz" : "" }
                        Chip_ {
                            title: "GPU"
                            temp: root.gpu
                            load: root.gpuLoad
                            detail: root.vramTotal > 0 ? `${root.vramUsed.toFixed(1)} / ${root.vramTotal.toFixed(1)} GB` : ""
                        }
                    }

                    // memory
                    Tile_ {
                        Layout.fillWidth: true
                        implicitHeight: mem.implicitHeight + 22
                        ColumnLayout {
                            id: mem
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 11; leftMargin: 12; rightMargin: 12 }
                            spacing: 6
                            Meter { label: "Memory"; used: root.memUsed; total: root.memTotal }
                            Meter { visible: root.swapTotal > 0; label: "Swap"; used: root.swapUsed; total: root.swapTotal }
                        }
                    }

                    // the other sensors
                    Tile_ {
                        Layout.fillWidth: true
                        implicitHeight: sensorList.implicitHeight + 12
                        Column {
                            id: sensorList
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6; leftMargin: 12; rightMargin: 12 }
                            Line {
                                visible: root.nvState !== ""
                                glyph: "\u{F08AE}"; label: "NVIDIA GPU"
                                value: root.nv ? `${root.nv.temp}°  ·  ${Math.round(root.nv.load * 100)}%  ·  ${root.nv.power.toFixed(0)} W` : root.nvState === "active" ? "On" : "Sleeping"
                                tone: root.nv && root.nv.temp >= 85 ? Theme.warning : Theme.text
                            }
                            Repeater {
                                model: root.fans
                                Line { required property int index; required property var modelData; glyph: "\u{F0210}"; label: ["CPU fan", "GPU fan"][index] ?? `Fan ${index + 1}`; value: modelData > 0 ? modelData + " rpm" : "Off" }
                            }
                            Line { visible: !isNaN(root.ssd); glyph: "\u{F02CA}"; label: "SSD"; value: Math.round(root.ssd) + "°"; tone: root.ssd >= 70 ? Theme.warning : Theme.text }
                            Line { visible: !isNaN(root.wifi); glyph: "\u{F05A9}"; label: "Wi-Fi card"; value: Math.round(root.wifi) + "°" }
                            Line {
                                visible: !isNaN(root.watts) && root.watts > 0
                                glyph: "\u{F140B}"; label: UPower.displayDevice?.state === UPowerDeviceState.Charging ? "Charging at" : "Battery draw"
                                value: root.watts.toFixed(1) + " W"
                            }
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
                                Text { anchors { right: parent.right; rightMargin: 48; verticalCenter: parent.verticalCenter } text: "CPU"; color: Theme.muted; font { family: Theme.font; pixelSize: 10; weight: Font.DemiBold } }
                                Text { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: "Memory"; color: Theme.muted; font { family: Theme.font; pixelSize: 10; weight: Font.DemiBold } }
                            }
                            Repeater {
                                model: root.procs
                                Item {
                                    required property var modelData
                                    width: procList.width; height: 22
                                    Text { anchors { left: parent.left; right: parent.right; rightMargin: 100; verticalCenter: parent.verticalCenter } text: modelData.name; elide: Text.ElideRight; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                                    Text { anchors { right: parent.right; rightMargin: 48; verticalCenter: parent.verticalCenter } text: modelData.cpu.toFixed(1) + "%"; color: modelData.cpu >= 50 ? Theme.warning : Theme.text; font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } } }
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

    // CPU / GPU tile: name and temperature, load bar, detail
    component Chip_: Rectangle {
        id: chip
        property string title
        property real temp: NaN
        property real load: 0
        property string detail
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 86
        radius: Theme.radius
        color: Theme.fill
        Column {
            anchors { fill: parent; margins: 12 }
            spacing: 4
            Text { text: chip.title; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold } }
            Text {
                text: isNaN(chip.temp) ? "–" : Math.round(chip.temp) + "°"
                color: chip.temp >= 90 ? Theme.error : chip.temp >= 80 ? Theme.warning : Theme.text
                font { family: Theme.font; pixelSize: 24; weight: Font.DemiBold; features: { "tnum": 1 } }
            }
            Rectangle {
                width: parent.width; height: 4; radius: 2
                color: Theme.fill
                Rectangle { width: Math.max(4, parent.width * chip.load); height: parent.height; radius: 2; color: chip.load >= 0.85 ? Theme.warning : Theme.selected; Behavior on width { NumberAnimation { duration: Theme.anim } } }
            }
            Text {
                width: parent.width
                text: Math.round(chip.load * 100) + "% load" + (chip.detail ? "  ·  " + chip.detail : "")
                elide: Text.ElideRight
                color: Theme.subtext
                font { family: Theme.font; pixelSize: 10; features: { "tnum": 1 } }
            }
        }
    }

    // a usage bar with "used / total GB"
    component Meter: ColumnLayout {
        id: meter
        property string label
        property real used: 0
        property real total: 1
        Layout.fillWidth: true
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: meter.label; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
            Text { text: `${meter.used.toFixed(1)} / ${meter.total.toFixed(1)} GB`; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } } }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6; radius: 3
            color: Theme.fill
            Rectangle {
                readonly property real f: meter.total > 0 ? Math.min(1, meter.used / meter.total) : 0
                width: Math.max(6, parent.width * f); height: parent.height; radius: 3
                color: f >= 0.9 ? Theme.warning : Theme.selected
                Behavior on width { NumberAnimation { duration: Theme.anim } }
            }
        }
    }

    // one sensor: icon, name, value
    component Line: Item {
        id: line
        property string glyph
        property string label
        property string value
        property color tone: Theme.text
        width: parent ? parent.width : 0
        height: 26
        Text { id: lg; anchors { left: parent.left; verticalCenter: parent.verticalCenter } width: 22; text: line.glyph; color: Theme.subtext; font { family: Theme.iconFont; pixelSize: 13 } }
        Text { anchors { left: lg.right; verticalCenter: parent.verticalCenter } text: line.label; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel } }
        Text { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: line.value; color: line.tone; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium; features: { "tnum": 1 } } }
    }
}
