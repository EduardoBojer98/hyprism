import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center part: one card of sliders, in the order of `parts`: the screen (brightness, external monitors over
// DDC/CI), sound and microphone (each with its device list). The Control Center uses two cards, Screen (["display"])
// and Sound (["sound", "mic"]), each under its short `title`; a chevron opens a device list. A flyout shows only its
// `parts`, each headed by its device name.
ControlCenterTile {
    id: mod
    Layout.fillWidth: true
    Layout.preferredHeight: rows.implicitHeight + Theme.ccInset * 2
    property var host: null   // the panel it sits in (PanelState): ControlCenter.view or a Flyout's
    property var parts: ["display", "sound", "mic"]
    property bool inPanel: false
    property string title: ""   // the card's label in the Control Center
    readonly property bool whole: inPanel   // older name
    readonly property bool hasDisplay: parts.includes("display") && Sys.brightness >= 0
    readonly property bool hasSound: parts.includes("sound")
    readonly property bool hasMic: parts.includes("mic")
    property int ddcShown: 0   // external monitors that answered DDC/CI (each shows a slider)
    // anything to show: counts the DDC monitors that answered, never `visible` (false while this card is hidden)
    // more than one screen, or a saved preset: a row that opens the display switcher (Super+P)
    readonly property bool hasArrange: parts.includes("display") && (Hyprland.monitors.values.length > 1 || Displays.presets.length > 0)
    readonly property bool hasAny: hasDisplay || ddcShown > 0 || hasArrange || hasSound || hasMic
    // in the Control Center a card folds to its title and a one-line summary (Config.controlCenter.folded)
    readonly property string foldKey: title.toLowerCase()
    readonly property bool folded: inPanel && title !== "" && Array.from(Config.controlCenter.folded ?? []).includes(foldKey)
    function toggleFold() {
        const l = Array.from(Config.controlCenter.folded ?? []).filter(k => k !== foldKey)
        Config.set("controlCenter", "folded", folded ? l : l.concat([foldKey]))
    }
    readonly property string summary: {
        const vol = n => n?.audio?.muted ? "muted" : Math.round((n?.audio?.volume ?? 0) * 100) + "%"
        const p = []
        if (hasDisplay) p.push(Sys.brightness + "%")
        else if (ddcShown > 0) p.push(ddcShown + (ddcShown === 1 ? " screen" : " screens"))
        else if (hasArrange) p.push(Hyprland.monitors.values.length + (Hyprland.monitors.values.length === 1 ? " screen" : " screens"))
        if (hasSound) p.push(vol(Sys.sink))
        if (hasMic) p.push("mic " + vol(Sys.source))
        return p.join(" · ")
    }
    readonly property int first: inPanel && title !== "" ? 1 : 0   // rows below the card's label
    visible: hasAny

    GridLayout {
        id: rows
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.ccInset; leftMargin: ControlCenter.inset; rightMargin: ControlCenter.inset }
        columns: 1
        rowSpacing: Theme.spaceS

        ControlCenterSliderHead {   // the card's title: click it to fold or open the card
            visible: mod.first === 1
            Layout.row: 0
            title: mod.title
            detail: mod.folded ? mod.summary : "Hide"
            isExpanded: !mod.folded
            onClicked: mod.toggleFold()
            Accessible.name: (mod.folded ? "Open " : "Fold ") + mod.title
        }

    // ---- screen ------------------------------------------------------------------------------
        ColumnLayout {
            visible: (mod.hasDisplay || mod.ddcShown > 0 || mod.hasArrange) && !mod.folded
            Layout.row: mod.first + Math.max(0, mod.parts.indexOf("display"))
            Layout.fillWidth: true
            spacing: Theme.spaceS
            ControlCenterSliderHead { visible: !mod.inPanel; title: "Screen" }
            Text { // names only once there's more than one screen to tell apart
                visible: mod.hasDisplay && externals.count > 0
                Layout.bottomMargin: -6
                text: "Built-in"
                color: Theme.subtext
                font { family: ControlCenter.textFont; pixelSize: Theme.fontCaption }
            }
            ControlCenterBar {
                visible: mod.hasDisplay
                host: mod.host
                tag: "bri"
                icon: "\u{F00DF}"
                value: Sys.brightness / 100
                onMoved: v => Sys.setBrightness(v * 100)
            }
            // external monitors over DDC/CI (VCP 0x10); read each time the panel opens, hidden when
            // a monitor doesn't answer (DDC/CI off in its menu)
            Repeater {
                id: externals
                model: mod.host.open && mod.parts.includes("display") ? Hyprland.monitors.values.filter(m => !m.name.startsWith("eDP") && Machine.realScreen(m.name)) : []
                ColumnLayout {
                    id: ext
                    required property var modelData
                    property string bus: ""
                    property int max: 100
                    property real value: -1
                    readonly property bool answered: value >= 0   // not `visible`: that is false while the tile is hidden
                visible: answered
                onAnsweredChanged: mod.ddcShown += answered ? 1 : -1
                Component.onDestruction: if (answered) mod.ddcShown--
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        text: ext.modelData.lastIpcObject?.model || ext.modelData.name
                        color: Theme.subtext
                        font { family: ControlCenter.textFont; pixelSize: Theme.fontCaption }
                    }
                    ControlCenterBar {
                        tag: "ext"
                        icon: "\u{F0379}"
                        value: Math.max(0, ext.value)
                        onMoved: v => { ext.value = Math.max(0.01, v); ddcSet.restart() }
                    }
                    Process {
                        running: true
                        command: ["sh", "-c", "b=$(readlink -f /sys/class/drm/card*-\"$1\"/ddc | sed 's/.*i2c-//'); [ -n \"$b\" ] || exit 1; echo \"$b\"; ddcutil --bus \"$b\" getvcp 10 --terse", "sh", ext.modelData.name]
                        stdout: StdioCollector {
                            onStreamFinished: {
                                const l = text.trim().split("\n")   // "6", "VCP 10 C 80 100"
                                const v = (l[1] ?? "").split(" ")
                                if (v[0] !== "VCP" || !(parseInt(v[4]) > 0)) return
                                ext.bus = l[0]; ext.max = parseInt(v[4]); ext.value = parseInt(v[3]) / ext.max
                            }
                        }
                    }
                    Timer {   // DDC is slow: send once dragging pauses
                        id: ddcSet
                        interval: 150
                        onTriggered: Quickshell.execDetached(["ddcutil", "--bus", ext.bus, "--noverify", "setvcp", "10", String(Math.round(ext.value * ext.max))])
                    }
                }
            }
            Rectangle {   // "Displays  Extended ›": opens the switcher (extend, mirror, one screen, presets, settings)
                visible: mod.hasArrange
                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.radiusSmall
                color: arrangeArea.containsMouse ? Theme.fillHover : "transparent"
                readonly property string how: {
                    const a = Displays.arrangement
                    return a === "mirror" ? "Mirrored" : a.startsWith("only:") ? "Only " + Displays.label(Displays.monitorOf(a.slice(5)) ?? { name: a.slice(5) }) : "Extended"
                }
                Row {
                    anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                    spacing: Theme.spaceS
                    Text { text: "\u{F0379}"; color: Theme.text; font { family: ControlCenter.textFont; pixelSize: Theme.fontLabel } }
                    Text { text: "Displays"; color: Theme.text; font { family: ControlCenter.textFont; pixelSize: Theme.fontLabel } }
                }
                Text {
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    text: parent.how + "  \u{F0142}"
                    color: Theme.subtext
                    font { family: ControlCenter.textFont; pixelSize: Theme.fontLabel }
                }
                MouseArea {
                    id: arrangeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: "Displays: " + parent.how + ". Choose how the screens are used"
                    onClicked: { Flyouts.hideAll(); ControlCenter.hide(); Displays.switcherOpen = true }
                }
            }
        }

    // ---- sound -------------------------------------------------------------------------------
        ColumnLayout {
            visible: mod.hasSound && !mod.folded
            Layout.row: mod.first + Math.max(0, mod.parts.indexOf("sound"))
            Layout.fillWidth: true
            spacing: Theme.spaceS
            ControlCenterSliderHead {
                visible: mod.hasSound && !mod.whole
                title: "Sound"
                detail: Sys.nodeName(Sys.sink) || "No output"
                isExpanded: mod.host.expanded === "out"
                onClicked: mod.host.toggleExpanded("out")
            }
            ControlCenterBar {
                visible: mod.hasSound
                host: mod.host
                expandable: mod.whole
                isExpanded: mod.host.expanded === "out"
                expandHint: Sys.nodeName(Sys.sink) || "No output"
                onExpand: mod.host.toggleExpanded("out")
                tag: "vol"
                icon: Sys.sink?.audio?.muted ? "\u{F075F}" : "\u{F057E}"
                hint: Sys.sink?.audio?.muted ? "Unmute" : "Mute"
                value: Sys.sink?.audio?.muted ? 0 : (Sys.sink?.audio?.volume ?? 0)
                onMoved: v => { if (Sys.sink?.audio) { Sys.sink.audio.muted = false; Sys.sink.audio.volume = v } }
                onIconClicked: if (Sys.sink?.audio) Sys.sink.audio.muted = !Sys.sink.audio.muted
            }
            ControlCenterReveal {
                open: mod.hasSound && mod.host.expanded === "out"
                ControlCenterSectionLabel { text: "Play sound through" }
                Repeater {
                    model: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink)
                    ControlCenterDeviceRow {
                        required property var modelData
                        glyph: Sys.audioGlyph(modelData)
                        title: Sys.nodeName(modelData)
                        subtitle: Sys.audioKind(modelData)
                        selected: modelData === Sys.sink
                        onClicked: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }
                ControlCenterSectionLabel { visible: Sys.streams.length > 0; text: "Apps" }
                Repeater {
                    model: Sys.streams
                    ColumnLayout {
                        id: app
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        Layout.rightMargin: 6
                        Layout.bottomMargin: 4
                        spacing: 4
                        Text {
                            Layout.fillWidth: true
                            text: app.modelData.properties["application.name"] || app.modelData.description || app.modelData.name
                            elide: Text.ElideRight
                            color: Theme.subtext
                            font { family: ControlCenter.textFont; pixelSize: Theme.fontCaption }
                        }
                        ControlCenterBar {
                            host: mod.host
                            tag: "app"
                            icon: app.modelData.audio?.muted ? "\u{F075F}" : "\u{F057E}"
                            hint: app.modelData.audio?.muted ? "Unmute" : "Mute"
                            value: app.modelData.audio?.muted ? 0 : (app.modelData.audio?.volume ?? 0)
                            onMoved: v => { if (app.modelData.audio) { app.modelData.audio.muted = false; app.modelData.audio.volume = v } }
                            onIconClicked: if (app.modelData.audio) app.modelData.audio.muted = !app.modelData.audio.muted
                        }
                    }
                }
                ControlCenterSettingsLink { label: "Sound Settings…"; page: "sound" }
            }
        }

    // ---- microphone --------------------------------------------------------------------------
        ColumnLayout {
            visible: mod.hasMic && !mod.folded
            Layout.row: mod.first + Math.max(0, mod.parts.indexOf("mic"))
            Layout.fillWidth: true
            spacing: Theme.spaceS
            ControlCenterSliderHead {
                visible: !mod.whole
                title: "Microphone"
                detail: Sys.nodeName(Sys.source) || "No input"
                isExpanded: mod.host.expanded === "in"
                onClicked: mod.host.toggleExpanded("in")
            }
            ControlCenterBar {
                visible: mod.hasMic
                host: mod.host
                expandable: mod.whole
                isExpanded: mod.host.expanded === "in"
                expandHint: Sys.nodeName(Sys.source) || "No input"
                onExpand: mod.host.toggleExpanded("in")
                tag: "mic"
                icon: Sys.source?.audio?.muted ? "\u{F036D}" : "\u{F036C}"
                hint: Sys.source?.audio?.muted ? "Unmute" : "Mute"
                value: Sys.source?.audio?.muted ? 0 : (Sys.source?.audio?.volume ?? 0)
                onMoved: v => { if (Sys.source?.audio) { Sys.source.audio.muted = false; Sys.source.audio.volume = v } }
                onIconClicked: if (Sys.source?.audio) Sys.source.audio.muted = !Sys.source.audio.muted
            }
            ControlCenterReveal {
                open: mod.hasMic && mod.host.expanded === "in"
                ControlCenterSectionLabel { text: "Record from" }
                Repeater {
                    model: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)
                    ControlCenterDeviceRow {
                        required property var modelData
                        glyph: modelData.name.startsWith("bluez") ? "\u{F02CE}" : "\u{F036C}"
                        title: Sys.nodeName(modelData)
                        subtitle: Sys.audioKind(modelData)
                        selected: modelData === Sys.source
                        onClicked: Pipewire.preferredDefaultAudioSource = modelData
                    }
                }
                ControlCenterSettingsLink { label: "Sound Settings…"; page: "sound" }
            }
        }
    }
}
