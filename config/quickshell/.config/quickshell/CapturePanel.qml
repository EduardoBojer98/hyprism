pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// The capture bar (Print, or `qs ipc call capture toggle`): Area / Window / Screen to take a screenshot, a countdown,
// and Record with the audio to record. What happens after a capture (edit / copy / save) and the folders are
// Settings > Screenshots (Config.capture); the delay and the audio chosen here are those same settings.
// The panel closes before the capture so it is not in the picture.
Singleton {
    id: root

    readonly property bool open: popup.open
    readonly property var delays: [0, 3, 5, 10]
    readonly property var audios: [{ id: "none", label: "No sound" }, { id: "desktop", label: "Desktop sound" }, { id: "mic", label: "Microphone" }]
    readonly property int delay: Config.capture.delay
    readonly property string audio: Config.capture.audio === "both" ? "desktop" : Config.capture.audio   // "both" was dropped

    function toggle() { popup.toggle() }
    function cycleDelay() { Config.set("capture", "delay", delays[(delays.indexOf(delay) + 1) % delays.length]) }
    function cycleAudio() { Config.set("capture", "audio", audios[(audios.findIndex(a => a.id === audio) + 1) % audios.length].id) }

    // close first, then run, so the panel is gone from the picture
    property var pending: []
    function run(cmd) { pending = cmd; popup.hide(); go.restart() }
    Timer { id: go; interval: 280; onTriggered: Quickshell.execDetached(root.pending) }

    IpcHandler {
        target: "capture"
        function toggle(): void { root.toggle() }
    }

    CursorPopup {
        id: popup
        name: "capture"
        placement: "cursor"
        boxWidth: 340
        boxHeight: col.implicitHeight + Theme.spaceM * 2

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusPanel

            ColumnLayout {
                id: col
                anchors { fill: parent; margins: Theme.spaceM }
                spacing: Theme.spaceS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceS
                    Btn_ { label: "Area"; hint: "Drag"; onClicked: root.run(["screenshot", "area"]) }
                    Btn_ { label: "Window"; hint: "Click"; onClicked: root.run(["screenshot", "window"]) }
                    Btn_ { label: "Screen"; hint: "This one"; onClicked: root.run(["screenshot", "screen"]) }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceS
                    Btn_ {
                        label: Sys.recording ? "Stop recording" : "Record area"
                        hint: Sys.recording ? "" : "Drag or click"
                        accent: true
                        onClicked: root.run(Sys.recording ? ["record", "stop"] : ["record", "area", "--audio=" + root.audio, "--delay", String(root.delay)])
                    }
                    Btn_ { visible: !Sys.recording; label: "Record screen"; hint: "This one"; onClicked: root.run(["record", "screen", "--audio=" + root.audio, "--delay", String(root.delay)]) }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceS
                    Opt_ { label: "Delay"; value: root.delay > 0 ? root.delay + " s" : "None"; onClicked: root.cycleDelay() }
                    Opt_ { label: "Sound"; value: root.audios.find(a => a.id === root.audio)?.label ?? ""; onClicked: root.cycleAudio() }
                }
            }
        }
    }

    // a big action: name, and what picking does
    component Btn_: Rectangle {
        id: b
        property string label
        property string hint
        property bool accent: false
        signal clicked()
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 44
        radius: Theme.radius
        color: accent ? (m.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent) : m.containsMouse ? Theme.fillHover : Theme.fill
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Accessible.role: Accessible.Button
        Accessible.name: b.label + (b.hint ? ", " + b.hint : "")
        Accessible.onPressAction: b.clicked()
        activeFocusOnTab: true
        Keys.onReturnPressed: b.clicked()
        Keys.onSpacePressed: b.clicked()
        FocusRing {}
        Column {
            anchors.centerIn: parent
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: b.label; color: b.accent ? Theme.accentText : Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
            Text { visible: b.hint !== ""; anchors.horizontalCenter: parent.horizontalCenter; text: b.hint; color: b.accent ? Theme.accentText : Theme.subtext; opacity: 0.85; font { family: Theme.font; pixelSize: Theme.fontCaption } }
        }
        MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
    }

    // a setting that cycles when clicked
    component Opt_: Rectangle {
        id: o
        property string label
        property string value
        signal clicked()
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 30
        radius: height / 2
        color: m2.containsMouse ? Theme.fillHover : Theme.fill
        Accessible.role: Accessible.Button
        Accessible.name: o.label + ": " + o.value
        Accessible.onPressAction: o.clicked()
        activeFocusOnTab: true
        Keys.onReturnPressed: o.clicked()
        Keys.onSpacePressed: o.clicked()
        FocusRing {}
        Row {
            anchors.centerIn: parent
            spacing: 6
            Text { text: o.label; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
            Text { text: o.value; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold } }
        }
        MouseArea { id: m2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: o.clicked() }
    }
}
