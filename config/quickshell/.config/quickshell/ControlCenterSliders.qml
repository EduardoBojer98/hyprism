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
// Used by ControlCenter.qml; reads the panel's state from the ControlCenter singleton.
ColumnLayout {
    Layout.fillWidth: true
    Layout.row: Math.max(0, ControlCenter.shownSections.indexOf("sliders"))
    visible: ControlCenter.shownSections.includes("sliders")
    spacing: ControlCenter.gap

    // ---- display and sound: one tile, three sliders ---------------------------------------
    ControlCenterTile {
        Layout.fillWidth: true
        Layout.preferredHeight: sliders.implicitHeight + 22
        ColumnLayout {
            id: sliders
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 11; leftMargin: 12; rightMargin: 12 }
            spacing: 10
            // the section's title; click it to fold the section down to this one line
            ControlCenterSliderHead {
                title: "Screen · Sound"   // short, so the folded values fit beside it in every face
                detail: Config.controlCenter.slidersOpen ? "Hide"
                    : `${Math.round(ControlCenter.brightness * 100)}% · ${ControlCenter.sink?.audio?.muted ? "muted" : Math.round((ControlCenter.sink?.audio?.volume ?? 0) * 100) + "%"}`
                isExpanded: Config.controlCenter.slidersOpen
                onClicked: Config.set("controlCenter", "slidersOpen", !Config.controlCenter.slidersOpen)
            }
            ControlCenterReveal {
                open: Config.controlCenter.slidersOpen
                spacing: 10

                ControlCenterSliderHead { title: "Display" }
                Text { // names only once there's more than one screen to tell apart
                    visible: externals.count > 0
                    Layout.bottomMargin: -6
                    text: "Built-in"
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontCaption }
                }
                ControlCenterBar {
                    icon: "\u{F00DF}"
                    value: ControlCenter.brightness
                    onMoved: v => {
                        ControlCenter.brightness = Math.max(0.05, v)
                        Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(ControlCenter.brightness * 100) + "%"])
                    }
                }
                // external monitors over DDC/CI (VCP 0x10); read each time the panel opens, hidden when
                // a monitor doesn't answer (DDC/CI off in its menu)
                Repeater {
                    id: externals
                    model: ControlCenter.open ? Hyprland.monitors.values.filter(m => !m.name.startsWith("eDP") && Machine.realScreen(m.name)) : []
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
                    title: "Sound"
                    detail: ControlCenter.nodeName(ControlCenter.sink) || "No output"
                    isExpanded: ControlCenter.expanded === "out"
                    onClicked: ControlCenter.toggleExpanded("out")
                }
                ControlCenterBar {
                    icon: ControlCenter.sink?.audio?.muted ? "\u{F075F}" : "\u{F057E}"
                    hint: ControlCenter.sink?.audio?.muted ? "Unmute" : "Mute"
                    value: ControlCenter.sink?.audio?.muted ? 0 : (ControlCenter.sink?.audio?.volume ?? 0)
                    onMoved: v => { if (ControlCenter.sink?.audio) { ControlCenter.sink.audio.muted = false; ControlCenter.sink.audio.volume = v } }
                    onIconClicked: if (ControlCenter.sink?.audio) ControlCenter.sink.audio.muted = !ControlCenter.sink.audio.muted
                }
                ControlCenterReveal {
                    open: ControlCenter.expanded === "out"
                    ControlCenterSectionLabel { text: "Play sound through" }
                    Repeater {
                        model: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink)
                        ControlCenterDeviceRow {
                            required property var modelData
                            glyph: ControlCenter.audioGlyph(modelData)
                            title: ControlCenter.nodeName(modelData)
                            subtitle: ControlCenter.audioKind(modelData)
                            selected: modelData === ControlCenter.sink
                            onClicked: Pipewire.preferredDefaultAudioSink = modelData
                        }
                    }
                    ControlCenterSectionLabel { visible: ControlCenter.streams.length > 0; text: "Apps" }
                    Repeater {
                        model: ControlCenter.streams
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
                    title: "Microphone"
                    detail: ControlCenter.nodeName(ControlCenter.source) || "No input"
                    isExpanded: ControlCenter.expanded === "in"
                    onClicked: ControlCenter.toggleExpanded("in")
                }
                ControlCenterBar {
                    icon: ControlCenter.source?.audio?.muted ? "\u{F036D}" : "\u{F036C}"
                    hint: ControlCenter.source?.audio?.muted ? "Unmute" : "Mute"
                    value: ControlCenter.source?.audio?.muted ? 0 : (ControlCenter.source?.audio?.volume ?? 0)
                    onMoved: v => { if (ControlCenter.source?.audio) { ControlCenter.source.audio.muted = false; ControlCenter.source.audio.volume = v } }
                    onIconClicked: if (ControlCenter.source?.audio) ControlCenter.source.audio.muted = !ControlCenter.source.audio.muted
                }
                ControlCenterReveal {
                    open: ControlCenter.expanded === "in"
                    ControlCenterSectionLabel { text: "Record from" }
                    Repeater {
                        model: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)
                        ControlCenterDeviceRow {
                            required property var modelData
                            glyph: modelData.name.startsWith("bluez") ? "\u{F02CE}" : "\u{F036C}"
                            title: ControlCenter.nodeName(modelData)
                            subtitle: ControlCenter.audioKind(modelData)
                            selected: modelData === ControlCenter.source
                            onClicked: Pipewire.preferredDefaultAudioSource = modelData
                        }
                    }
                    ControlCenterSettingsLink { label: "Sound Settings…"; page: "sound" }
                }
            }
        }
    }
}
