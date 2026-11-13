import Quickshell
import Quickshell.Io
import QtQuick

// Dock part: one small widget (Config.dock.widgets): clock, load, media, trash or downloads. A tile the size of
// an icon; what it reads only runs while it is on the dock. Used by Dock.qml, which passes itself in as `dock`.
Item {
    id: w
    required property var dock
    required property string modelData            // the widget's id
    readonly property var kind: ({ clock: clockBody, load: loadBody, media: mediaBody, trash: trashBody, downloads: downloadsBody })[modelData]
    readonly property Item body: loader.item
    readonly property real mid: (dock.vertical ? height : width) / 2
    // an empty widget (nothing playing) leaves no gap: Dock's grid skips items without width
    visible: body?.shown ?? false
    width: visible ? (dock.vertical ? dock.cellCross : dock.slot) : 0
    height: visible ? (dock.vertical ? dock.slot : dock.cellCross) : 0

    Rectangle {
        id: tile
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: dock.vertical ? -3 * dock.sign : 0
        anchors.verticalCenterOffset: dock.vertical ? 0 : -3 * dock.sign
        width: dock.iconSize; height: dock.iconSize
        radius: dock.shape === "block" ? 0 : Math.round(dock.iconSize * 0.27)
        color: Qt.alpha(dock.ink, area.containsMouse ? 0.17 : 0.07)
        border { color: Qt.alpha(dock.ink, area.containsMouse ? 0.3 : 0.15); width: 1 }
        scale: area.pressed ? Theme.pressScale : 1
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.anim } }
        Loader { id: loader; anchors.fill: parent; sourceComponent: w.kind }
    }
    MouseArea {
        id: area
        Accessible.role: Accessible.Button
        Accessible.name: w.body?.tip ?? "Widget"
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onContainsMouseChanged: dock.hovering(w, w.body?.tip ?? "", containsMouse)
        onClicked: mouse => { if (mouse.button === Qt.RightButton) w.body?.secondary(); else w.body?.primary(w) }
        onWheel: wheel => w.body?.scrolled(wheel.angleDelta.y)
    }

    // each body: `shown`, `tip`, primary(widget) on click, secondary() on right-click, scrolled(delta)
    component Glyph: Text {
        anchors.centerIn: parent
        color: dock.ink
        font { family: Theme.iconFont; pixelSize: Math.round(dock.iconSize * 0.5) }
    }
    component Badge: Rectangle {
        property int n: 0
        anchors { right: parent.right; top: parent.top; margins: -3 }
        width: Math.max(height, badgeText.implicitWidth + 8); height: 16; radius: 8
        color: Theme.accent
        Text { id: badgeText; anchors.centerIn: parent; text: parent.n > 99 ? "99+" : parent.n; color: Theme.accentText; font { family: Theme.font; pixelSize: Theme.fontCaption - 1; weight: Font.Bold } }
    }
    component Body: Item {
        property bool shown: true
        property string tip: ""
        function primary(widget) {}
        function secondary() {}
        function scrolled(delta) {}
    }

    Component {
        id: clockBody
        Body {
            tip: "Clock: " + Sys.clockText
            function primary(widget) { Anchor.take(widget, dock.edge, dock.origin()); Calendar.toggle() }
            Column {
                anchors.centerIn: parent
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Sys.time(); color: dock.ink; font { family: Theme.font; pixelSize: Math.round(dock.iconSize * 0.3); weight: Font.DemiBold; features: { "tnum": 1 } } }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(Sys.now, "ddd d"); color: Qt.alpha(dock.ink, 0.7); font { family: Theme.font; pixelSize: Math.round(dock.iconSize * 0.2) } }
            }
        }
    }

    Component {
        id: loadBody
        Body {
            readonly property real pct: Math.max(0, Metrics.value("cpu"))
            tip: Metrics.detail("cpu") || "CPU load"
            function primary(widget) { Sensors.toggle() }
            Component.onCompleted: Metrics.want(["cpu"], 2)
            Component.onDestruction: Metrics.unwant(["cpu"])
            Rectangle {   // a fill rising with the load: accent, then warning, then error
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 1 }
                height: Math.max(0, (parent.height - 2) * parent.pct / 100)
                radius: tile.radius - 1
                color: Qt.alpha(parent.pct >= 95 ? Theme.error : parent.pct >= 85 ? Theme.warning : Theme.accent, 0.55)
                Behavior on height { NumberAnimation { duration: Theme.anim } }
            }
            Text { anchors.centerIn: parent; text: Math.round(parent.pct); color: dock.ink; font { family: Theme.font; pixelSize: Math.round(dock.iconSize * 0.34); weight: Font.DemiBold; features: { "tnum": 1 } } }
        }
    }

    Component {
        id: mediaBody
        Body {
            shown: Sys.player !== null && Sys.track !== ""
            tip: (Sys.player?.isPlaying ? "Playing: " : "Paused: ") + Sys.track
            function primary(widget) { Sys.player?.togglePlaying() }
            function secondary() { Sys.player?.next() }
            function scrolled(delta) { if (delta > 0) Sys.player?.previous(); else Sys.player?.next() }
            Glyph { text: Sys.player?.isPlaying ? "\u{F03E4}" : "\u{F040A}"; color: Sys.player?.isPlaying ? Theme.accent : dock.ink }
        }
    }

    // trash and downloads read a folder every few seconds, only while they are on the dock
    component Folder: Body {
        id: folder
        property string script: ""
        property var lines: []
        function refresh() { reader.running = true }
        Timer { running: true; interval: 5000; repeat: true; triggeredOnStart: true; onTriggered: folder.refresh() }
        Process {
            id: reader
            command: ["sh", "-c", folder.script]
            stdout: StdioCollector { onStreamFinished: folder.lines = text.split("\n") }
        }
    }

    Component {
        id: trashBody
        Folder {
            id: trash
            // right-click once to arm, again to empty: nothing is lost by a stray click
            property bool armed: false
            readonly property int count: Number(lines[0]) || 0
            script: 'ls -A "${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files" 2>/dev/null | wc -l'
            tip: armed ? "Right-click again to empty the trash" : count === 0 ? "Trash: empty" : "Trash: " + count + (count === 1 ? " item" : " items")
            function primary(widget) { armed = false; Quickshell.execDetached(["xdg-open", "trash:///"]) }
            function secondary() {
                if (count === 0) return
                if (!armed) { armed = true; disarm.restart(); return }
                armed = false
                Quickshell.execDetached(["gio", "trash", "--empty"])
                refreshSoon.restart()
            }
            Timer { id: disarm; interval: 4000; onTriggered: trash.armed = false }
            Timer { id: refreshSoon; interval: 800; onTriggered: trash.refresh() }
            Glyph { text: "\u{F01B4}"; color: trash.armed ? Theme.error : dock.ink }
            Badge { visible: trash.count > 0; n: trash.count }
        }
    }

    Component {
        id: downloadsBody
        Folder {
            id: dl
            readonly property string dir: lines[0] ?? ""
            readonly property int count: Number(lines[1]) || 0
            script: 'd=$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$HOME/Downloads"); echo "$d"; find "$d" -maxdepth 1 -type f -mtime -1 ! -name ".*" 2>/dev/null | wc -l; ls -t "$d" 2>/dev/null | head -1'
            tip: (lines[2] ?? "") !== "" ? "Downloads: " + lines[2] + (count > 1 ? " and " + (count - 1) + " more today" : "") : "Downloads"
            function primary(widget) { if (dir !== "") Quickshell.execDetached(["xdg-open", dir]) }
            Glyph { text: "\u{F01DA}" }
            Badge { visible: dl.count > 0; n: dl.count }
        }
    }
}
