import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Shapes

// Dock part: one small widget (Config.dock.widgets, names in Theme.dockWidgets). A tile the size of an app
// icon that lifts or grows on hover like one; what it reads only runs while it is on the dock.
// Used by Dock.qml, which passes itself in as `dock`.
Item {
    id: w
    required property var dock
    required property string modelData            // the widget's id
    readonly property var kind: ({ clock: clockBody, date: dateBody, weather: weatherBody, media: mediaBody, volume: volumeBody,
                                   battery: batteryBody, load: loadBody, network: networkBody, screenshot: screenshotBody,
                                   trash: trashBody, downloads: downloadsBody })[modelData]
    readonly property Item body: loader.item
    readonly property real mid: (dock.vertical ? height : width) / 2
    readonly property real s: dock.iconSize
    // an empty widget (nothing playing) leaves no gap: Dock's grid skips items without width
    visible: body?.shown ?? false
    width: visible ? (dock.vertical ? dock.cellCross : dock.slot) : 0
    height: visible ? (dock.vertical ? dock.slot : dock.cellCross) : 0

    Rectangle {
        id: tile
        readonly property bool lit: area.containsMouse
        anchors.centerIn: parent
        // in line with the app icons, which sit a little off the edge for their open-app mark
        anchors.horizontalCenterOffset: dock.vertical ? -3 * dock.sign : 0
        anchors.verticalCenterOffset: dock.vertical ? 0 : -3 * dock.sign
        width: w.s; height: w.s
        radius: dock.shape === "block" ? 0 : Math.round(w.s * 0.27)
        color: w.body?.alert ? Qt.alpha(Theme.error, 0.22) : Qt.alpha(dock.ink, lit ? 0.14 : 0.07)
        border { color: w.body?.alert ? Theme.error : Qt.alpha(dock.ink, lit ? 0.28 : 0.15); width: 1 }
        transformOrigin: dock.edgeOrigin
        // hover like an app icon: lift (off the edge) or grow (from the edge); press: a small give
        property real raise: dock.hoverStyle === "lift" && lit && Theme.moves ? -6 * dock.sign : 0
        transform: Translate { x: dock.vertical ? tile.raise : 0; y: dock.vertical ? 0 : tile.raise }
        Behavior on raise { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
        scale: area.pressed ? Theme.pressScale : dock.hoverStyle === "grow" && tile.lit && Theme.moves ? 1.14 : 1
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.anim } }

        Rectangle {   // top sheen, like the launcher tile on glass
            visible: Theme.glassy
            anchors { fill: parent; margins: 1 }
            radius: Math.max(0, parent.radius - 1)
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.highlight }
                GradientStop { position: 0.5; color: "transparent" }
            }
        }
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
        onClicked: mouse => { if (mouse.button === Qt.RightButton) w.body?.secondary(w); else w.body?.primary(w) }
        onWheel: wheel => w.body?.scrolled(wheel.angleDelta.y)
    }
    // the tooltip follows a reading that changes while the pointer is on it
    Connections { target: w.body; function onTipChanged() { if (area.containsMouse) dock.hovering(w, w.body.tip, true) } }

    // a panel opened from a widget appears beside it
    function beside() { Anchor.take(w, dock.edge, dock.origin()) }

    // each body: `shown`, `tip`, `alert` (tile turns red), primary(widget) on click, secondary(widget) on
    // right-click, scrolled(delta)
    component Body: Item {
        property bool shown: true
        property string tip: ""
        property bool alert: false
        function primary(widget) {}
        function secondary(widget) {}
        function scrolled(delta) {}
    }
    component Glyph: Text {
        anchors.centerIn: parent
        color: dock.ink
        font { family: Theme.iconFont; pixelSize: Math.round(w.s * 0.46) }
    }
    component Figure: Text {   // a number on a tile
        color: dock.ink
        font { family: Theme.font; pixelSize: Math.round(w.s * 0.3); weight: Font.DemiBold; features: { "tnum": 1 } }
    }
    // a count in the corner, like a notification badge, cut out of the tile by a rim of the dock's own colour
    component Badge: Rectangle {
        property int n: 0
        visible: n > 0
        anchors { right: parent.right; top: parent.top; rightMargin: -5; topMargin: -5 }
        height: Math.round(Math.max(16, w.s * 0.38)); width: Math.max(height, badgeText.implicitWidth + 9)
        radius: dock.shape === "block" ? 0 : height / 2
        color: Theme.error
        border { width: 2; color: dock.ds.fill === "ink" ? Theme.text : Theme.surfaceColor }
        Text {
            id: badgeText
            anchors.centerIn: parent
            text: parent.n > 99 ? "99+" : parent.n
            color: Theme.errorText
            font { family: Theme.font; pixelSize: Math.round(parent.height * 0.6); weight: Font.Bold; features: { "tnum": 1 } }
        }
    }
    // a ring gauge: a faint full track and an arc from 12 o'clock for `value` (0-1)
    component Ring: Shape {
        id: ring
        property real value: 0
        property color tone: Theme.accent
        property real thick: Math.max(2.5, Math.round(w.s * 0.07))
        anchors.centerIn: parent
        width: Math.round(w.s * 0.8); height: width
        preferredRendererType: Shape.CurveRenderer
        Behavior on value { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
        ShapePath {
            strokeColor: Qt.alpha(dock.ink, 0.14); strokeWidth: ring.thick; fillColor: "transparent"
            PathAngleArc { centerX: ring.width / 2; centerY: ring.height / 2; radiusX: (ring.width - ring.thick) / 2; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {
            strokeColor: ring.value > 0.005 ? ring.tone : "transparent"; strokeWidth: ring.thick; fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: ring.width / 2; centerY: ring.height / 2; radiusX: (ring.width - ring.thick) / 2; radiusY: radiusX; startAngle: -90; sweepAngle: 360 * Math.min(1, ring.value) }
        }
    }

    // --- clock: an analogue face; the tooltip has the time as the bar shows it (12 / 24 h) and the date
    Component {
        id: clockBody
        Body {
            readonly property date now: Sys.now
            tip: Qt.formatDateTime(now, Sys.h24 ? "HH:mm" : "h:mm AP") + "  ·  " + Qt.formatDate(now, "dddd d MMMM")
            function primary(widget) { w.beside(); Calendar.toggle() }
            Item {
                id: face
                readonly property real r: width / 2
                anchors.centerIn: parent
                width: Math.round(w.s * 0.82); height: width
                Repeater {   // twelve ticks, the quarters longer
                    model: 12
                    Rectangle {
                        required property int index
                        readonly property bool major: index % 3 === 0
                        width: major ? Math.max(2, w.s * 0.05) : Math.max(1.5, w.s * 0.035)
                        height: face.r * (major ? 0.2 : 0.12)
                        radius: width / 2
                        x: face.r - width / 2; y: 0
                        color: Qt.alpha(dock.ink, major ? 0.75 : 0.32)
                        antialiasing: true
                        transform: Rotation { origin.x: width / 2; origin.y: face.r; angle: index * 30 }
                    }
                }
                Repeater {   // the hands from the centre, each with a short stub past the pin: hour, then minute
                    model: [{ length: 0.5, thick: Math.max(3, w.s * 0.085), turn: (now.getHours() % 12 + now.getMinutes() / 60) * 30 },
                            { length: 0.76, thick: Math.max(2, w.s * 0.055), turn: now.getMinutes() * 6 + (Config.bar.seconds ? now.getSeconds() / 10 : 0) }]
                    Rectangle {
                        id: hand
                        required property var modelData
                        readonly property real length: face.r * modelData.length
                        width: modelData.thick; height: length + width * 1.2
                        radius: width / 2
                        x: face.r - width / 2; y: face.r - length
                        color: dock.ink
                        antialiasing: true
                        transform: Rotation { origin.x: hand.width / 2; origin.y: hand.length; angle: hand.modelData.turn }
                    }
                }
                Rectangle {   // the pin
                    anchors.centerIn: parent
                    width: Math.round(w.s * 0.11); height: width; radius: width / 2
                    color: Theme.accent
                }
            }
        }
    }

    // --- date: a page of a desk calendar, the weekday over the day
    Component {
        id: dateBody
        Body {
            tip: Qt.formatDate(Sys.now, "dddd d MMMM yyyy")
            function primary(widget) { w.beside(); Calendar.toggle() }
            Column {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                spacing: -Math.round(w.s * 0.04)
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(Sys.now, "ddd").toUpperCase()
                    color: Theme.accent
                    font { family: Theme.font; pixelSize: Math.max(9, Math.round(w.s * 0.2)); weight: Font.Bold; letterSpacing: 0.6 }
                }
                Figure {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Sys.now.getDate()
                    font { pixelSize: Math.round(w.s * 0.46); weight: Font.Medium }
                }
            }
        }
    }

    // --- weather: the sky now and the temperature (the Weather service already polls; hidden until it has read)
    Component {
        id: weatherBody
        Body {
            shown: Weather.ready
            tip: Weather.ready ? (Weather.city ? Weather.city + ": " : "") + Math.round(Weather.temperature) + "°  " + Weather.condition
                                 + "  ·  feels like " + Math.round(Weather.feelsLike) + "°" : "Weather"
            function primary(widget) { w.beside(); Weather.toggle() }
            Column {
                anchors.centerIn: parent
                spacing: -Math.round(w.s * 0.06)
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Weather.glyph
                    color: Theme.accent
                    font { family: Theme.iconFont; pixelSize: Math.round(w.s * 0.38) }
                }
                Figure {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.horizontalCenterOffset: Math.round(w.s * 0.03)   // the degree sign hangs right
                    text: Math.round(Weather.temperature) + "°"
                    font.pixelSize: Math.round(w.s * 0.28)
                }
            }
        }
    }

    // --- media: the cover in a disc, a ring for how far the track is; paused dims it and shows play
    Component {
        id: mediaBody
        Body {
            id: media
            readonly property var p: Sys.player
            readonly property bool playing: p?.isPlaying ?? false
            readonly property string art: p?.trackArtUrl ?? ""
            shown: p !== null && Sys.track !== ""
            tip: (playing ? "Playing: " : "Paused: ") + Sys.track + "  ·  scroll to skip"
            function primary(widget) { p?.togglePlaying() }
            function secondary(widget) { p?.next() }
            function scrolled(delta) { if (delta > 0) p?.previous(); else p?.next() }
            // MPRIS only reports the position when asked: once a second while it plays
            Timer { running: media.playing && (media.p?.positionSupported ?? false); interval: 1000; repeat: true; onTriggered: media.p.positionChanged() }
            Ring {
                visible: media.p?.lengthSupported ?? false
                value: (media.p?.length ?? 0) > 0 ? media.p.position / media.p.length : 0
                thick: Math.max(2.5, Math.round(w.s * 0.06))
                width: Math.round(w.s * 0.84)
            }
            ClippingRectangle {
                id: disc
                anchors.centerIn: parent
                width: Math.round(w.s * 0.62); height: width; radius: width / 2
                color: Qt.alpha(dock.ink, 0.12)
                opacity: media.playing ? 1 : 0.45
                Behavior on opacity { NumberAnimation { duration: Theme.anim } }
                Image {
                    id: cover
                    anchors.fill: parent
                    source: media.art
                    fillMode: Image.PreserveAspectCrop
                    sourceSize { width: disc.width * 2; height: disc.height * 2 }
                    visible: status === Image.Ready
                    asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    text: "\u{F075A}"
                    color: dock.ink
                    font { family: Theme.iconFont; pixelSize: Math.round(w.s * 0.3) }
                }
            }
            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 1   // a play triangle looks centred a touch right of centre
                text: "\u{F040A}"
                color: dock.ink
                opacity: media.playing ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: Theme.anim } }
                font { family: Theme.iconFont; pixelSize: Math.round(w.s * 0.36) }
            }
        }
    }

    // --- volume: the level as a ring; click mutes, scroll changes it, right-click opens Sound
    Component {
        id: volumeBody
        Body {
            readonly property int pct: Math.round(Sys.volume * 100)
            shown: Sys.sink !== null
            tip: Sys.muted ? "Volume: muted" : "Volume: " + pct + "%  ·  scroll to change"
            function primary(widget) { Sys.toggleMute() }
            function secondary(widget) { SettingsApp.show("sound") }
            function scrolled(delta) { Sys.nudgeVolume(delta > 0 ? 1 : -1) }
            Ring { value: Sys.muted ? 0 : Sys.volume; tone: Qt.alpha(dock.ink, 0.85) }
            Glyph {
                text: Sys.volumeGlyph
                color: Sys.muted ? Qt.alpha(dock.ink, 0.5) : dock.ink
                font.pixelSize: Math.round(w.s * 0.34)
            }
        }
    }

    // --- battery (laptops): a battery that fills, and the percentage under it
    Component {
        id: batteryBody
        Body {
            id: bat
            readonly property color tone: Sys.batteryLow ? Theme.error : Sys.charging ? Theme.success : dock.ink
            shown: Sys.hasBattery
            tip: "Battery: " + Sys.batteryPct + "%" + (Sys.charging ? "  ·  charging" : Sys.plugged ? "  ·  plugged in" : "")
            function primary(widget) { SettingsApp.show("power") }
            Column {
                anchors.centerIn: parent
                spacing: Math.round(w.s * 0.06)
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.round(w.s * 0.58); height: Math.round(w.s * 0.3)
                    Rectangle {   // the case
                        id: shell
                        width: parent.width - nub.width - 1; height: parent.height
                        radius: Math.round(height * 0.28)
                        color: "transparent"
                        border { width: 1.5; color: Qt.alpha(dock.ink, 0.6) }
                        Rectangle {   // the charge
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 3 }
                            width: Math.max(2, (parent.width - 6) * Sys.batteryPct / 100)
                            radius: Math.max(0, parent.radius - 2)
                            color: bat.tone
                            Behavior on width { NumberAnimation { duration: Theme.anim } }
                        }
                    }
                    Rectangle {
                        id: nub
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        width: 2.5; height: parent.height * 0.4; radius: 1
                        color: Qt.alpha(dock.ink, 0.6)
                    }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    Text {
                        visible: Sys.charging
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\u{F140B}"
                        color: Theme.success
                        font { family: Theme.iconFont; pixelSize: Math.round(w.s * 0.22) }
                    }
                    Figure { text: Sys.batteryPct + "%"; font.pixelSize: Math.round(w.s * 0.24) }
                }
            }
        }
    }

    // --- CPU load: a ring that turns warning, then error, with the number inside
    Component {
        id: loadBody
        Body {
            readonly property real pct: Math.max(0, Metrics.value("cpu"))
            tip: Metrics.detail("cpu") || "CPU load"
            function primary(widget) { w.beside(); Sensors.toggle() }
            Component.onCompleted: Metrics.want(["cpu"], 2)
            Component.onDestruction: Metrics.unwant(["cpu"])
            Ring { value: parent.pct / 100; tone: parent.pct >= 95 ? Theme.error : parent.pct >= 85 ? Theme.warning : Theme.accent }
            Figure { anchors.centerIn: parent; text: Math.round(parent.pct); font.pixelSize: Math.round(w.s * 0.28) }
        }
    }

    // --- network: download and upload speed, one line each
    Component {
        id: networkBody
        Body {
            readonly property var net: Metrics.data.net
            tip: Metrics.detail("net") || "Network speed"
            function primary(widget) { w.beside(); Sensors.toggle() }
            Component.onCompleted: Metrics.want(["net"], 2)
            Component.onDestruction: Metrics.unwant(["net"])
            Column {
                anchors.centerIn: parent
                spacing: Math.round(w.s * 0.02)
                Repeater {   // one line each: an arrow and a speed
                    model: [{ glyph: "\u{F0045}", tone: Theme.accent, bytes: net?.down ?? 0 },
                            { glyph: "\u{F005D}", tone: Qt.alpha(dock.ink, 0.55), bytes: net?.up ?? 0 }]
                    Row {
                        required property var modelData
                        spacing: 1
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.glyph; color: modelData.tone
                            font { family: Theme.iconFont; pixelSize: Math.round(w.s * 0.22) }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(w.s * 0.5)   // a fixed width, so the arrows stay put as numbers change
                            text: Metrics.bytes(modelData.bytes)
                            color: dock.ink
                            font { family: Theme.font; pixelSize: Math.max(10, Math.round(w.s * 0.24)); weight: Font.DemiBold; features: { "tnum": 1 } }
                        }
                    }
                }
            }
        }
    }

    // --- screenshot: click for an area; right-click for the other screen tools
    Component {
        id: screenshotBody
        Body {
            tip: "Screenshot an area  ·  right-click for more tools"
            function primary(widget) { Quickshell.execDetached(["sh", "-c", "sleep 0.3; screenshot"]) }
            function secondary(widget) { w.beside(); UtilityMenu.toggle() }
            Glyph { text: "\u{F0100}"; font.pixelSize: Math.round(w.s * 0.42) }
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

    // --- trash: a can, filled when there is something in it, and how many
    Component {
        id: trashBody
        Folder {
            id: trash
            // right-click once to arm, again to empty: nothing is lost by a stray click
            property bool armed: false
            readonly property int count: Number(lines[0]) || 0
            alert: armed
            script: 'ls -A "${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files" 2>/dev/null | wc -l'
            tip: armed ? "Right-click again to empty the trash" : count === 0 ? "Trash: empty" : "Trash: " + count + (count === 1 ? " item" : " items") + "  ·  right-click to empty"
            function primary(widget) { armed = false; Quickshell.execDetached(["xdg-open", "trash:///"]) }
            function secondary(widget) {
                if (count === 0) return
                if (!armed) { armed = true; disarm.restart(); return }
                armed = false
                Quickshell.execDetached(["gio", "trash", "--empty"])
                refreshSoon.restart()
            }
            Timer { id: disarm; interval: 4000; onTriggered: trash.armed = false }
            Timer { id: refreshSoon; interval: 800; onTriggered: trash.refresh() }
            Glyph { text: trash.count > 0 ? "\u{F0A79}" : "\u{F0A7A}"; color: trash.armed ? Theme.error : dock.ink }
            Badge { n: trash.count }
        }
    }

    // --- downloads: a little fan of pages (one per file today, up to three), the front one with the arrow
    Component {
        id: downloadsBody
        Folder {
            id: dl
            readonly property string dir: lines[0] ?? ""
            readonly property int count: Number(lines[1]) || 0
            script: 'd=$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$HOME/Downloads"); echo "$d"; find "$d" -maxdepth 1 -type f -mtime -1 ! -name ".*" 2>/dev/null | wc -l; ls -t "$d" 2>/dev/null | head -1'
            tip: (lines[2] ?? "") !== "" ? "Downloads: " + lines[2] + (count > 1 ? " and " + (count - 1) + " more today" : "") : "Downloads"
            function primary(widget) { if (dir !== "") Quickshell.execDetached(["xdg-open", dir]) }
            Item {
                id: fan
                anchors.centerIn: parent
                anchors.verticalCenterOffset: Math.round(w.s * 0.03)
                width: Math.round(w.s * 0.4); height: Math.round(w.s * 0.5)
                Repeater {
                    model: [{ angle: -16, alpha: 0.22, from: 3 }, { angle: 13, alpha: 0.38, from: 2 }]
                    Rectangle {
                        required property var modelData
                        anchors.fill: parent
                        radius: Math.round(w.s * 0.07)
                        color: Qt.alpha(dock.ink, modelData.alpha)
                        visible: dl.count >= modelData.from
                        transformOrigin: Item.Bottom
                        rotation: modelData.angle
                        antialiasing: true
                    }
                }
                Rectangle {   // the front page
                    anchors.fill: parent
                    radius: Math.round(w.s * 0.07)
                    color: Theme.accent
                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 1
                        text: "\u{F01DA}"
                        color: Theme.accentText
                        font { family: Theme.iconFont; pixelSize: Math.round(w.s * 0.32) }
                    }
                }
            }
            Badge { n: dl.count }
        }
    }
}
