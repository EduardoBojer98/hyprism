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

// Control Center part: the one tile with the Display, Sound and Microphone sliders and their device lists.
// In the Control Center all three; a flyout shows only its `parts`, always unfolded.
ColumnLayout {
    id: mod
    Layout.fillWidth: true
    property var host: null   // the panel it sits in (PanelState): ControlCenter.view or a Flyout's
    property var parts: ["display", "sound", "mic"]
    readonly property bool whole: parts.length === 3   // the Control Center's tile: folds to one line
    readonly property bool hasDisplay: parts.includes("display") && Sys.brightness >= 0
    readonly property bool hasSound: parts.includes("sound")
    readonly property bool hasMic: parts.includes("mic")
    spacing: ControlCenter.gap

    // ---- display and sound: one tile, three sliders ---------------------------------------
    ControlCenterTile {
        Layout.fillWidth: true
        Layout.preferredHeight: sliders.implicitHeight + Theme.ccInset * 2
        ColumnLayout {
            id: sliders
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.ccInset }
            spacing: Theme.spaceS
            // the section's title; click it to fold the section down to this one line
            ControlCenterSliderHead {
                visible: mod.whole
                title: mod.hasDisplay ? "Display & sound" : "Sound"
                detail: Config.controlCenter.slidersOpen ? "Hide"
                    : (mod.hasDisplay ? `${Sys.brightness}% · ` : "") + (Sys.sink?.audio?.muted ? "muted" : Math.round((Sys.sink?.audio?.volume ?? 0) * 100) + "%")
                isExpanded: Config.controlCenter.slidersOpen
                onClicked: Config.set("controlCenter", "slidersOpen", !Config.controlCenter.slidersOpen)
            }
            ControlCenterReveal {
                open: !mod.whole || Config.controlCenter.slidersOpen
                spacing: Theme.spaceXs

                // a flyout names each slider (and its device); the Control Center's rows carry a chevron instead
                ControlCenterSliderHead { visible: mod.hasDisplay && !mod.whole; title: "Display" }
                Text { // names only once there's more than one screen to tell apart
                    visible: mod.hasDisplay && externals.count > 0
                    Layout.bottomMargin: -6
                    text: "Built-in"
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontCaption }
                }
                ControlCenterBar {
                    visible: mod.hasDisplay
                    host: mod.host
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
                        visible: value >= 0
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: ext.modelData.lastIpcObject?.model || ext.modelData.name
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontCaption }
                        }
                        ControlCenterBar {
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
                                font { family: Theme.font; pixelSize: Theme.fontCaption }
                            }
                            ControlCenterBar {
                                host: mod.host
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

                ControlCenterSliderHead {
                    visible: mod.hasMic && !mod.whole
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
}
