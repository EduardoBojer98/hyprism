import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Shared Monitor: one monitor used by this computer and another one (a work PC, a console),
// switched over DDC/CI from the Control Center or the monitor's own buttons. Edits settings.json
// (monitorShare) on Save; SettingsSync.qml writes ~/.config/monswitch.conf for ~/.local/bin/monswitch
// (monswitch.conf.off while it's switched off, so the values are kept).
ColumnLayout {
    id: page
    spacing: 20

    Text {
        visible: page.scanned && page.found.length === 0
        Layout.fillWidth: true
        text: "Could not read the monitor's inputs; these are the usual codes."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    // VCP 0x60 values most monitors use (MCCS); a value outside this list shows as "Other"
    readonly property var presets: [["0x11", "HDMI 1"], ["0x12", "HDMI 2"], ["0x13", "HDMI 3"],
                                    ["0x0f", "DisplayPort 1"], ["0x10", "DisplayPort 2"], ["0x1b", "USB-C"]]
    property bool enabled: false
    property string out: ""
    property string mine: "0x11"
    property string other: "0x12"
    property string mirror: ""
    property string mirrorMode: ""
    property string status: ""
    readonly property string snapshot: JSON.stringify([enabled, out, mine, other, mirror, mirrorMode.trim()])
    property string savedState: snapshot   // page state as last loaded or saved
    readonly property bool dirty: snapshot !== savedState
    property var found: []        // from `monswitch inputs`: [{ output, model, current, inputs: [{ code, name }] }]
    property bool scanned: false
    readonly property var monitor: found.find(m => m.output === out) ?? null
    // [code, text] rows for the two input dropdowns: the monitor's own list when it gave one, else the usual codes
    readonly property var table: monitor && monitor.inputs.length
        ? monitor.inputs.map(i => [i.code, i.name + (i.code === monitor.current ? " (now)" : "")])
        : presets.map(p => [p[0], `${p[1]} (${p[0]})`])
    readonly property var outputs: {
        const names = found.length ? found.map(m => m.output) : Hyprland.monitors.values.map(m => m.name).filter(n => Machine.realScreen(n))
        if (out && !names.includes(out)) names.push(out)
        return names
    }

    function label(v) { const p = table.find(x => x[0] === v.toLowerCase()); return p ? p[1] : `Other (${v})` }
    function options(v) { const l = table.map(p => p[1]); return table.some(p => p[0] === v.toLowerCase()) ? l : l.concat([label(v)]) }
    function valueOf(option) { return table.find(x => x[1] === option)?.[0] ?? option.match(/\((0x[0-9a-fA-F]+)\)/)?.[1] ?? "" }

    function save() {
        if (enabled && (!out || !mine || !other)) { status = "Pick the monitor and both inputs first"; return }
        if (enabled && mine === other) { status = "The two inputs must differ"; return }
        // Config.set checks each value (plain names, input codes, a mode like 1920x1080@60) and says why not
        const c = { enabled: enabled, output: out, thisInput: mine, otherInput: other, mirror: mirror, mirrorMode: mirrorMode.trim() }
        for (const k of Object.keys(c)) { const err = Config.set("monitorShare", k, c[k]); if (err) { status = "Couldn't save: " + err; return } }
        status = "Saved"
        savedState = snapshot
    }

    function load() {
        const c = Config.monitorShare
        enabled = c.enabled; out = c.output || (Hyprland.monitors.values.find(x => !x.name.startsWith("eDP") && Machine.realScreen(x.name))?.name ?? "")
        mine = c.thisInput; other = c.otherInput; mirror = c.mirror; mirrorMode = c.mirrorMode
        savedState = snapshot
    }
    Component.onCompleted: load()

    Process {   // which monitors answer DDC/CI and what inputs each one offers; run once when the page opens
        running: true
        command: ["monswitch", "inputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.found = JSON.parse(text) } catch (e) { page.found = [] }
                page.scanned = true
            }
        }
    }

    Process {   // the input the monitor shows right now
        id: detect
        command: ["sh", "-c", "b=$(readlink -f /sys/class/drm/card*-\"$1\"/ddc | sed 's/.*i2c-//'); ddcutil --bus \"$b\" getvcp 60 --terse 2>/dev/null | awk '$1 == \"VCP\" {sub(/^x/, \"0x\", $4); print $4}'", "sh", page.out]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim()
                if (v) { page.mine = v; page.status = "This computer is on " + page.label(v) }
                else page.status = "The monitor didn't answer (DDC/CI off in its menu, or not connected)"
            }
        }
    }

    SettingGroup {
        SettingRow {
            label: "Share a monitor with another computer"
            hint: "Adds a monitor button to the Control Center and follows switches you make with the monitor's own buttons"
            Toggle { checked: page.enabled; onToggled: c => page.enabled = c }
        }
    }

    SettingGroup {
        title: "Monitor and inputs"
        opacity: page.enabled ? 1 : 0.5
        enabled: page.enabled
        SettingRow {
            label: "Monitor"
            Dropdown { width: 200; options: page.outputs; current: page.out; onPicked: v => page.out = v }
        }
        SettingRow {
            label: "This computer's input"
            hint: "Detect while the monitor shows this computer"
            Dropdown { width: 200; options: page.options(page.mine); current: page.label(page.mine); onPicked: v => page.mine = page.valueOf(v) }
            PillButton { text: "Detect"; onClicked: { page.status = "Asking the monitor…"; detect.running = true } }
        }
        SettingRow {
            label: "Other computer's input"
            Dropdown { width: 200; options: page.options(page.other); current: page.label(page.other); onPicked: v => page.other = page.valueOf(v) }
        }
        SettingRow {
            label: "While it's away, mirror"
            hint: "Some monitors drop the other input without a signal from this computer, so it mirrors this screen instead of turning off"
            Dropdown { width: 200; options: Hyprland.monitors.values.map(m => m.name).filter(n => n !== page.out && Machine.realScreen(n)); current: page.mirror; onPicked: v => page.mirror = v }
        }
        SettingRow {
            label: "Mirror mode"
            hint: "Resolution@refresh both computers' screens support"
            TextField { width: 160; text: page.mirrorMode; invalid: !/^(\d{3,5}x\d{3,5}(@\d{2,3}(\.\d+)?)?)?$/.test(text.trim()); onTextChanged: page.mirrorMode = text }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: page.status
            color: Theme.subtext
            wrapMode: Text.Wrap
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
        Text {
            visible: page.dirty
            text: "Unsaved changes"
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
        PillButton { text: "Save"; primary: true; onClicked: page.save() }
    }

    Text {
        Layout.fillWidth: true
        text: "Needs DDC/CI turned on in the monitor's menu. Input numbers are the monitor's own (VCP 60); the usual ones are listed, and Detect reads the current one."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
}
