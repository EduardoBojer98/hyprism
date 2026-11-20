import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

// Sound: the output (volume, balance, a left/right test, the device to play through), the input (volume, the
// device, which apps are listening), each app's volume, and where the alert sounds are set.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioOutStream)
    readonly property var listeners: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioInStream)
    readonly property var out: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var mic: Pipewire.defaultAudioSource?.audio ?? null

    function name(n) { return n?.description || n?.nickname || n?.name || "" }
    function app(n) { return n.properties["application.name"] || name(n) }
    // what kind of device, from its PipeWire name and description
    function kind(n, input) {
        const s = ((n?.name ?? "") + " " + (n?.description ?? "")).toLowerCase()
        return s.includes("bluez") ? "Bluetooth" : /hdmi|displayport/.test(s) ? "On a screen (HDMI or DisplayPort)"
            : /headphone|headset/.test(s) ? "Headphones" : s.includes("usb") ? "USB" : input ? "Built-in microphone" : "Speakers"
    }
    // the loudest channel is the volume; moving it keeps the balance between the channels
    function level(a) { return a ? (a.volumes.length ? Math.max(...a.volumes) : a.volume) : 0 }
    function setLevel(a, v) {
        if (!a) return
        a.muted = false
        const m = level(a)
        if (a.volumes.length > 1 && m > 0.001) a.volumes = a.volumes.map(x => x * v / m); else a.volume = v
    }
    // balance -1 (left) .. 1 (right), for two channels
    readonly property bool stereo: (out?.volumes.length ?? 0) === 2
    readonly property real balance: stereo && level(out) > 0.001 ? (out.volumes[1] - out.volumes[0]) / level(out) : 0
    function setBalance(b) {
        if (!stereo) return
        if (Math.abs(b) < 0.06) b = 0   // snaps to the middle
        const m = level(out)
        out.volumes = [m * (b > 0 ? 1 - b : 1), m * (b < 0 ? 1 + b : 1)]
    }
    function test(sound) {
        Quickshell.execDetached(["sh", "-c", "canberra-gtk-play -i \"$1\" -d Hyprism 2>/dev/null || pw-play \"/usr/share/sounds/freedesktop/stereo/$1.oga\"", "sh", sound])
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource, ...page.streams, ...page.listeners] }

    SettingGroup {
        title: "Output"
        SettingRow {
            label: "Volume"
            hint: page.out ? page.name(Pipewire.defaultAudioSink) : "No sound output found"
            Slider {
                width: 300
                accessibleName: "Output volume"
                value: page.out?.muted ? 0 : page.level(page.out)
                onMoved: v => page.setLevel(page.out, v)
            }
            Readout { audio: page.out }
        }
        SettingRow {
            visible: page.stereo
            label: "Balance"
            hint: "Click the readout to centre it"
            Slider {
                width: 300
                accessibleName: "Balance"
                value: (page.balance + 1) / 2
                onMoved: v => page.setBalance(v * 2 - 1)
            }
            Text {
                width: 60   // as wide as a Readout, so the sliders line up
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: Math.abs(page.balance) < 0.01 ? "Centre" : (page.balance < 0 ? "L " : "R ") + Math.round(Math.abs(page.balance) * 100) + "%"
                color: Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontLabel; features: { "tnum": 1 } }
                MouseArea { anchors { fill: parent; margins: -4 } cursorShape: Qt.PointingHandCursor; onClicked: page.setBalance(0); Accessible.role: Accessible.Button; Accessible.name: "Centre the balance" }
            }
        }
        SettingRow {
            visible: page.out !== null
            label: "Test"
            hint: page.stereo ? "A voice from each side, to check the balance and the cables" : "A short test sound"
            Row {
                spacing: Theme.spaceS
                PillButton { visible: page.stereo; text: "Left"; onClicked: page.test("audio-channel-front-left") }
                PillButton { visible: page.stereo; text: "Right"; onClicked: page.test("audio-channel-front-right") }
                PillButton { visible: !page.stereo; text: "Play"; onClicked: page.test("audio-test-signal") }
            }
        }
    }

    SettingGroup {
        title: "Play sound through"
        visible: page.sinks.length > 0
        Repeater {
            model: page.sinks
            SettingRow {
                required property var modelData
                label: page.name(modelData)
                hint: page.kind(modelData, false)
                // pick one: the one in use is marked, the others offer to switch
                InUse { current: modelData === Pipewire.defaultAudioSink; onPicked: Pipewire.preferredDefaultAudioSink = modelData }
            }
        }
    }

    SettingGroup {
        title: "Input"
        SettingRow {
            visible: page.sources.length === 0
            label: "No microphone found"
            hint: "The built-in mic needs the sound card on its duplex profile (home/wireplumber sets this)"
        }
        SettingRow {
            visible: page.sources.length > 0
            label: "Microphone volume"
            hint: page.mic?.muted ? "Muted: apps hear silence" : ""
            Slider {
                width: 300
                accessibleName: "Microphone volume"
                value: page.mic?.muted ? 0 : page.level(page.mic)
                onMoved: v => page.setLevel(page.mic, v)
            }
            Readout { audio: page.mic }
        }
        Repeater {
            model: page.sources.length > 1 ? page.sources : []
            SettingRow {
                required property var modelData
                label: page.name(modelData)
                hint: page.kind(modelData, true)
                InUse { current: modelData === Pipewire.defaultAudioSource; onPicked: Pipewire.preferredDefaultAudioSource = modelData }
            }
        }
        SettingRow {
            visible: page.sources.length > 0
            label: page.listeners.length ? "Listening now" : "No app is listening"
            hint: page.listeners.length ? Array.from(new Set(page.listeners.map(n => page.app(n)))).join(", ") : "Apps that record from the microphone show here while they do"
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
                label: page.app(modelData)
                hint: modelData.properties["media.name"] ?? ""
                Slider {
                    width: 260
                    accessibleName: page.app(modelData) + " volume"
                    value: modelData.audio?.muted ? 0 : page.level(modelData.audio)
                    onMoved: v => page.setLevel(modelData.audio, v)
                }
                Readout { audio: modelData.audio }
            }
        }
    }

    SettingGroup {
        title: "Alert sounds"
        SettingRow {
            label: "Notification sounds"
            hint: "One sound for each priority, and Do Not Disturb, are set with the notifications"
            PillButton { text: "Open Notifications"; onClicked: SettingsApp.show("notifications") }
        }
    }

    // the volume beside a slider, with a speaker to click to mute or unmute
    component Readout: Row {
        id: ro
        property var audio
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter
        Accessible.role: Accessible.CheckBox
        Accessible.name: "Mute"
        Accessible.checked: ro.audio?.muted ?? false
        Accessible.onPressAction: if (ro.audio) ro.audio.muted = !ro.audio.muted
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ro.audio?.muted ? "\u{F075F}" : "\u{F057E}"
            color: ro.audio?.muted ? Theme.warning : roArea.containsMouse ? Theme.text : Theme.subtext
            font { family: Theme.iconFont; pixelSize: Theme.iconSmall }
            MouseArea { id: roArea; anchors { fill: parent; margins: -6 } hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (ro.audio) ro.audio.muted = !ro.audio.muted }
            ToolTipText { shown: roArea.containsMouse; text: ro.audio?.muted ? "Unmute" : "Mute" }
        }
        Text {
            width: 44
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: ro.audio?.muted ? "Muted" : Math.round(page.level(ro.audio) * 100) + "%"
            color: ro.audio?.muted ? Theme.warning : Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontLabel; features: { "tnum": 1 } }
        }
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
