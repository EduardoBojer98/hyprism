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
                Toggle {
                    checked: modelData === Pipewire.defaultAudioSink
                    onToggled: Pipewire.preferredDefaultAudioSink = modelData
                }
            }
        }
        SettingRow {
            label: "Output volume"
            Slider {
                width: 300
                icon: Pipewire.defaultAudioSink?.audio?.muted ? "\u{F075F}" : "\u{F057E}"
                value: Pipewire.defaultAudioSink?.audio?.muted ? 0 : (Pipewire.defaultAudioSink?.audio?.volume ?? 0)
                onMoved: v => { const a = Pipewire.defaultAudioSink?.audio; if (a) { a.muted = false; a.volume = v } }
                onIconClicked: { const a = Pipewire.defaultAudioSink?.audio; if (a) a.muted = !a.muted }
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
        Repeater {
            model: page.sources
            SettingRow {
                required property var modelData
                label: page.name(modelData)
                Toggle {
                    checked: modelData === Pipewire.defaultAudioSource
                    onToggled: Pipewire.preferredDefaultAudioSource = modelData
                }
            }
        }
        SettingRow {
            visible: page.sources.length > 0
            label: "Input volume"
            Slider {
                width: 300
                icon: Pipewire.defaultAudioSource?.audio?.muted ? "\u{F036D}" : "\u{F036C}"
                value: Pipewire.defaultAudioSource?.audio?.muted ? 0 : (Pipewire.defaultAudioSource?.audio?.volume ?? 0)
                onMoved: v => { const a = Pipewire.defaultAudioSource?.audio; if (a) { a.muted = false; a.volume = v } }
                onIconClicked: { const a = Pipewire.defaultAudioSource?.audio; if (a) a.muted = !a.muted }
            }
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
                    icon: modelData.audio?.muted ? "\u{F075F}" : "\u{F057E}"
                    value: modelData.audio?.muted ? 0 : (modelData.audio?.volume ?? 0)
                    onMoved: v => { if (modelData.audio) { modelData.audio.muted = false; modelData.audio.volume = v } }
                    onIconClicked: if (modelData.audio) modelData.audio.muted = !modelData.audio.muted
                }
            }
        }
    }
}
