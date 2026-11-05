import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

// Sound: output and input device, their volumes, and per-app volume.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioOutStream)

    function name(n) { return n?.description || n?.nickname || n?.name || "" }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource, ...page.streams] }

    SettingGroup {
        title: "Output"
        Repeater {
            model: page.sinks
            SettingRow {
                required property var modelData
                label: page.name(modelData)
                // pick one: the one in use is marked, the others offer to switch
                InUse { current: modelData === Pipewire.defaultAudioSink; onPicked: Pipewire.preferredDefaultAudioSink = modelData }
            }
        }
        SettingRow {
            label: "Output volume"
            Slider {
                width: 300
                value: Pipewire.defaultAudioSink?.audio?.muted ? 0 : (Pipewire.defaultAudioSink?.audio?.volume ?? 0)
                onMoved: v => { const a = Pipewire.defaultAudioSink?.audio; if (a) { a.muted = false; a.volume = v } }
            }
            Readout { audio: Pipewire.defaultAudioSink?.audio }
        }
    }

    SettingGroup {
        title: "Input"
        SettingRow {
            visible: page.sources.length === 0
            label: "No microphone found"
            hint: "The built-in mic needs the sound card on its duplex profile (home/wireplumber sets this)"
        }
        Repeater {
            model: page.sources
            SettingRow {
                required property var modelData
                label: page.name(modelData)
                // pick one: the one in use is marked, the others offer to switch
                InUse { current: modelData === Pipewire.defaultAudioSource; onPicked: Pipewire.preferredDefaultAudioSource = modelData }
            }
        }
        SettingRow {
            visible: page.sources.length > 0
            label: "Input volume"
            Slider {
                width: 300
                value: Pipewire.defaultAudioSource?.audio?.muted ? 0 : (Pipewire.defaultAudioSource?.audio?.volume ?? 0)
                onMoved: v => { const a = Pipewire.defaultAudioSource?.audio; if (a) { a.muted = false; a.volume = v } }
            }
            Readout { audio: Pipewire.defaultAudioSource?.audio }
        }
    }

    SettingGroup {
        title: "Applications"
        SettingRow {
            visible: page.streams.length === 0
            label: "No app is playing sound right now"
        }
        Repeater {
            model: page.streams
            SettingRow {
                required property var modelData
                label: modelData.properties["application.name"] || page.name(modelData)
                hint: modelData.properties["media.name"] ?? ""
                Slider {
                    width: 260
                    value: modelData.audio?.muted ? 0 : (modelData.audio?.volume ?? 0)
                    onMoved: v => { if (modelData.audio) { modelData.audio.muted = false; modelData.audio.volume = v } }
                }
                Readout { audio: modelData.audio }
            }
        }
    }

    // the volume beside a slider, as ConfigSlider writes its value
    // click it to mute or unmute
    component Readout: Text {
        property var audio
        width: 52
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: audio?.muted ? "Muted" : Math.round((audio?.volume ?? 0) * 100) + "%"
        color: audio?.muted ? Theme.warning : Theme.subtext
        font { family: Theme.font; pixelSize: Theme.fontLabel; features: { "tnum": 1 } }
        MouseArea { anchors { fill: parent; margins: -4 } cursorShape: Qt.PointingHandCursor; onClicked: if (parent.audio) parent.audio.muted = !parent.audio.muted }
    }
    // a device row's control: "In use" with a check, or a button to switch to it
    component InUse: Item {
        id: iu
        property bool current
        signal picked()
        implicitWidth: current ? used.implicitWidth : use.implicitWidth
        implicitHeight: use.implicitHeight
        Row {
            id: used
            visible: iu.current
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Text { text: "\u{F012C}"; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter; font { family: Theme.iconFont; pixelSize: Theme.iconSmall } }
            Text { text: "In use"; color: Theme.text; anchors.verticalCenter: parent.verticalCenter; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium } }
        }
        PillButton { id: use; visible: !iu.current; text: "Use"; onClicked: iu.picked() }
    }
}
