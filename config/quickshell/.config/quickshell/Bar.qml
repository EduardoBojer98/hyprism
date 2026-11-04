import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// The bar of one screen, in the active theme's layout (Themes.qml bar.kind). Each kind is its own
// composition of the shared pieces (BarWs, BarStatus, BarTray, BarKeyboard, BarBell, BarApp, Sys):
//   text       bottom strip of mono words (Monolith)        line      thin top line, ticks and time (Mist)
//   menubar    translucent top strip, app name (Glass)        gnome     black top bar, centred clock (Canvas)
//   poster     paper bar, huge workspace blocks (Poster)      pills     three floating pills (Pebble)
//   rail       vertical rail on the left or right (Atlas)     readout   a text line on the top edge + corner brackets (Console)
//   taskbar    Start, search, running apps, clock (Workstation)
//   letterbox  black bands at top and bottom (Noir)           island    one capsule at the bottom (Garden)
//   halo       one small floating pill at the bottom (Halo)    corner    a clock in the bottom-right corner (Zen)
Scope {
    id: root
    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property var b: Theme.bar
    readonly property string kind: b.kind
    readonly property string edge: b.edge
    readonly property int size: b.size

    // ---- the main window: an edge strip, or a floating piece for halo / island / corner -----------
    PanelWindow {
        id: win
        screen: root.screen
        WlrLayershell.namespace: "qs-bar"
        color: "transparent"
        readonly property bool floating: ["halo", "island"].includes(root.kind)
        anchors {
            top: root.edge === "top" || Theme.barVertical
            bottom: root.edge === "bottom" || Theme.barVertical
            left: root.edge === "left" || (!Theme.barVertical && !win.floating && root.kind !== "corner")
            right: root.edge === "right" || (!Theme.barVertical && !win.floating)
        }
        exclusiveZone: root.kind === "corner" ? 40 : Theme.barHeight
        implicitHeight: Theme.barVertical ? 0 : (root.kind === "corner" ? 40 : Theme.barHeight)
        implicitWidth: Theme.barVertical ? Theme.barHeight : (win.floating || root.kind === "corner") ? Math.max(40, loader.item?.implicitWidth ?? 40) : 0
        Loader {
            id: loader
            anchors.fill: parent
            sourceComponent: ({ text: textBar, line: lineBar, menubar: menuBar, gnome: gnomeBar, poster: posterBar, pills: pillsBar,
                                rail: railBar, readout: readoutBar, taskbar: taskBar, letterbox: letterTop, island: islandBar,
                                halo: haloBar, corner: cornerBar })[root.kind] ?? menuBar
        }
    }

    // ---- extras: Noir's bottom band, Console's corner brackets --------------------------------------
    PanelWindow {
        screen: root.screen
        visible: root.kind === "letterbox"
        WlrLayershell.namespace: "qs-bar"
        anchors { bottom: true; left: true; right: true }
        implicitHeight: root.size
        color: "#000000"
        Loader { anchors.fill: parent; active: parent.visible; sourceComponent: letterBottom }
    }
    PanelWindow {
        screen: root.screen
        visible: root.kind === "readout"
        WlrLayershell.namespace: "qs-brackets"
        WlrLayershell.layer: WlrLayer.Bottom
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        mask: Region {}   // click-through
        Repeater {
            model: [[0, 0], [1, 0], [0, 1], [1, 1]]
            Item {
                id: bracket
                required property var modelData
                readonly property int arm: 40
                x: modelData[0] ? parent.width - arm - 14 : 14
                y: modelData[1] ? parent.height - arm - 14 : 14 + root.size
                width: arm; height: arm
                Rectangle { width: parent.width; height: 2; color: Theme.accent; y: bracket.modelData[1] ? parent.height - 2 : 0 }
                Rectangle { width: 2; height: parent.height; color: Theme.accent; x: bracket.modelData[0] ? parent.width - 2 : 0 }
            }
        }
    }

    // ================================ shared pieces of the layouts ================================

    // A horizontal strip with three zones
    component Strip: Item {
        default property alias leftItems: leftRow.data
        property alias centerItems: centerRow.data
        property alias rightItems: rightRow.data
        property int pad: 12
        property int gap: 14
        RowLayout { id: leftRow; anchors { left: parent.left; leftMargin: parent.pad; verticalCenter: parent.verticalCenter } spacing: parent.gap }
        RowLayout { id: centerRow; anchors.centerIn: parent; spacing: parent.gap }
        RowLayout { id: rightRow; anchors { right: parent.right; rightMargin: parent.pad; verticalCenter: parent.verticalCenter } spacing: parent.gap }
    }
    component Words: Text {
        property bool mono: false
        color: Theme.text
        font { family: mono ? Theme.monoFont : Theme.font; pixelSize: Theme.fontLabel; features: { "tnum": 1 } }
    }
    component ClockItem: BarItem {
        property alias text: clockLabel.text
        property alias tone: clockLabel.color
        property alias family: clockLabel.font.family
        property alias pixelSize: clockLabel.font.pixelSize
        property alias weight: clockLabel.font.weight
        property alias align: clockLabel.horizontalAlignment
        active: Calendar.open === true
        onPressed: Calendar.toggle()
        Text {
            id: clockLabel
            text: Sys.clockText
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.Medium; features: { "tnum": 1 } }
        }
    }

    // ================================ layouts ================================

    // Monolith: mono words on a dark strip at the bottom
    Component {
        id: textBar
        Rectangle {
            color: Theme.surfaceColor
            Rectangle { width: parent.width; height: 1; color: Theme.stroke }
            Strip {
                anchors.fill: parent
                pad: 8
                BarWs { monitor: root.monitor; style: "filled" }
                Words { mono: true; text: "│"; color: Theme.muted }
                BarApp { family: Theme.monoFont; size: Theme.fontLabel; weight: Font.Normal; lower: true; maxTitle: 420 }
                rightItems: [
                    BarTray { iconSize: 14 },
                    BarBell {},
                    BarKeyboard { plain: true; family: Theme.monoFont },
                    BarStatus { mode: "text"; family: Theme.monoFont; pad: 4 },
                    ClockItem { text: Qt.formatDateTime(Sys.now, "ddd dd MMM ").toLowerCase() + Sys.time(); tone: Theme.accent; family: Theme.monoFont; pixelSize: Theme.fontLabel; pad: 4 }
                ]
            }
        }
    }

    // Mist: a pale line with ticks on the left and the time on the right
    Component {
        id: lineBar
        Rectangle {
            color: Theme.base
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.stroke }
            Strip {
                anchors.fill: parent
                pad: 16
                BarWs { monitor: root.monitor; style: "ticks" }
                rightItems: [
                    BarTray { iconSize: 14 },
                    BarBell { tone: Theme.subtext },
                    BarKeyboard { plain: true; tone: Theme.subtext },
                    BarStatus { tone: Theme.subtext; glyphSize: 13 },
                    ClockItem { text: Qt.formatDateTime(Sys.now, "ddd d MMM  ") + Sys.time(); pixelSize: Theme.fontLabel }
                ]
            }
        }
    }

    // Glass: the classic translucent menu bar
    Component {
        id: menuBar
        Glass {
            radius: 0
            border.width: 0
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.stroke }
            Strip {
                anchors.fill: parent
                gap: 10
                BarItem { active: UtilityMenu.open; onPressed: UtilityMenu.toggle(); Text { text: "\u{F303}"; color: Theme.text; font { family: Theme.iconFont; pixelSize: 15 } } }
                BarApp { title: false }
                BarWs { monitor: root.monitor; style: "numbers" }
                rightItems: [ BarTray {}, BarKeyboard {}, BarStatus {}, BarBell {}, ClockItem {} ]
            }
        }
    }

    // Canvas: black bar, dots left, the clock dead centre, one status pill right
    Component {
        id: gnomeBar
        Rectangle {
            color: "#000000"
            Strip {
                anchors.fill: parent
                BarItem { onPressed: MissionControl.toggle(); hover: Qt.alpha("#ffffff", 0.12); BarWs { monitor: root.monitor; style: "dots" } }
                centerItems: [ ClockItem { text: Qt.formatDateTime(Sys.now, "ddd d MMM  ") + Sys.time(); tone: "#ffffff"; weight: Font.Bold; hover: Qt.alpha("#ffffff", 0.12) } ]
                rightItems: [
                    BarTray {},
                    BarBell { tone: "#ffffff" },
                    BarStatus { tone: "#ffffff"; radius: height / 2; pad: 12; hover: Qt.alpha("#ffffff", 0.16); color: active ? Qt.alpha("#ffffff", 0.22) : Qt.alpha("#ffffff", 0.08) }
                ]
            }
        }
    }

    // Poster: a paper bar, workspace numbers as huge blocks, the time set big
    Component {
        id: posterBar
        Rectangle {
            color: Theme.surfaceColor
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: Theme.line; color: Theme.stroke }
            Strip {
                anchors.fill: parent
                pad: 0
                gap: 18
                BarWs { monitor: root.monitor; style: "blocks"; thickness: root.size - Theme.line }
                BarApp { title: false; size: Theme.fontTitle + 2; weight: Font.ExtraBold }
                rightItems: [
                    BarTray {}, BarKeyboard {}, BarStatus {}, BarBell {},
                    ClockItem { text: Sys.time(); family: Theme.displayFont; pixelSize: Math.round(root.size * 0.62); weight: Theme.displayWeight; pad: 14; radius: 0 }
                ]
            }
        }
    }

    // Pebble: three floating pills: menu + dots, the clock, the status
    Component {
        id: pillsBar
        Item {
            id: pills
            component Pill: Glass {
                default property alias content: pillRow.data
                strong: true
                y: Theme.barInset
                height: root.size
                width: pillRow.implicitWidth + 20
                radius: height / 2
                RowLayout { id: pillRow; anchors.centerIn: parent; spacing: 10 }
            }
            Pill {
                x: 10
                BarItem { active: UtilityMenu.open; onPressed: UtilityMenu.toggle(); radius: height / 2; Text { text: "\u{F0765}"; color: Theme.accent; font { family: Theme.iconFont; pixelSize: 16 } } }
                BarWs { monitor: root.monitor; style: "dots" }
            }
            Pill { x: (pills.width - width) / 2; ClockItem { radius: height / 2 } }
            Pill {
                x: pills.width - width - 10
                BarTray {}
                BarKeyboard {}
                BarBell {}
                BarStatus { radius: height / 2 }
            }
        }
    }

    // Atlas: a black rail: heavy clock on top, square blocks, status, the date on its side
    Component {
        id: railBar
        Rectangle {
            color: Theme.text
            ColumnLayout {
                anchors { top: parent.top; topMargin: 18; horizontalCenter: parent.horizontalCenter }
                spacing: 22
                BarItem {
                    Layout.alignment: Qt.AlignHCenter
                    vertical: true
                    hover: Qt.alpha(Theme.base, 0.12)
                    onPressed: Calendar.toggle()
                    Text { text: Sys.hours() + "\n" + Sys.minutes(); horizontalAlignment: Text.AlignHCenter; lineHeight: 0.85
                           color: Theme.base; font { family: Theme.displayFont; pixelSize: 30; weight: Theme.displayWeight; letterSpacing: -1; features: { "tnum": 1 } } }
                }
                BarWs { Layout.alignment: Qt.AlignHCenter; monitor: root.monitor; style: "squares"; vertical: true; tone: Theme.base; dim: Qt.alpha(Theme.base, 0.6) }
            }
            ColumnLayout {
                anchors { bottom: parent.bottom; bottomMargin: 16; horizontalCenter: parent.horizontalCenter }
                spacing: 14
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: dateText.implicitHeight; implicitHeight: dateText.implicitWidth
                    Text {
                        id: dateText
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(Sys.now, "dddd d MMMM")
                        color: Theme.base
                        rotation: 90
                        font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
                    }
                }
                BarTray { vertical: true; Layout.alignment: Qt.AlignHCenter }
                BarBell { tone: Theme.base; vertical: true; Layout.alignment: Qt.AlignHCenter; hover: Qt.alpha(Theme.base, 0.12) }
                BarKeyboard { tone: Theme.base; vertical: true; Layout.alignment: Qt.AlignHCenter; hover: Qt.alpha(Theme.base, 0.12) }
                BarStatus { tone: Theme.base; vertical: true; Layout.alignment: Qt.AlignHCenter; hover: Qt.alpha(Theme.base, 0.12) }
            }
        }
    }

    // Console: one amber readout line along the top edge
    Component {
        id: readoutBar
        Item {
            Row {
                anchors.centerIn: parent
                spacing: 26
                ClockItem { anchors.verticalCenter: parent.verticalCenter; text: Qt.formatDateTime(Sys.now, Sys.h24 ? "HH:mm:ss" : "h:mm:ss AP"); tone: Theme.accent; family: Theme.monoFont; pixelSize: Theme.fontLabel; pad: 4 }
                BarWs { monitor: root.monitor; style: "text"; anchors.verticalCenter: parent.verticalCenter }
                BarItem { anchors.verticalCenter: parent.verticalCenter; pad: 4; active: Sensors.open; onPressed: Sensors.toggle()
                    Text { text: "CPU " + Math.round(BarStats.cpu * 100) + "%   MEM " + BarStats.memUsed.toFixed(1) + "G"; color: Theme.accent
                           font { family: Theme.monoFont; pixelSize: Theme.fontLabel; letterSpacing: 1; features: { "tnum": 1 } } } }
                BarStatus { anchors.verticalCenter: parent.verticalCenter; mode: "caps"; tone: Theme.accent; family: Theme.monoFont; pad: 4 }
                BarKeyboard { anchors.verticalCenter: parent.verticalCenter; plain: true; tone: Theme.accent; family: Theme.monoFont; pad: 4 }
                BarBell { anchors.verticalCenter: parent.verticalCenter; tone: Theme.accent; pad: 4 }
                BarTray { anchors.verticalCenter: parent.verticalCenter; iconSize: 14 }
            }
        }
    }

    // Workstation: Start, search, workspaces, running apps, tray and a two-line clock
    Component {
        id: taskBar
        Rectangle {
            color: Theme.surfaceColor
            Rectangle { width: parent.width; height: 1; color: Theme.stroke }
            RowLayout {
                anchors { fill: parent; leftMargin: 6; rightMargin: 10 }
                spacing: 6
                BarItem {   // Start
                    Layout.preferredHeight: root.size - 10; Layout.preferredWidth: root.size - 10
                    active: Launcher.open
                    onPressed: Launcher.toggle()
                    color: active ? Qt.darker(Theme.accent, 1.2) : Theme.accent
                    Text { text: "\u{F0646}"; color: Theme.accentText; font { family: Theme.iconFont; pixelSize: 18 } }
                }
                Rectangle {   // search: opens the launcher
                    Layout.preferredHeight: root.size - 14; Layout.preferredWidth: 220
                    radius: Theme.radiusSmall
                    color: Theme.raised
                    Text { anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter } text: "\u{F0349}  Search"; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontSize } }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Launcher.toggle() }
                }
                BarWs { monitor: root.monitor; style: "small"; Layout.leftMargin: 6 }
                Repeater {   // running apps on this screen
                    model: Hyprland.toplevels.values.filter(t => t.wayland && t.workspace?.monitor === root.monitor && (t.workspace?.id ?? 0) > 0)
                    BarItem {
                        id: task
                        required property var modelData
                        readonly property var entry: DesktopEntries.heuristicLookup(modelData.wayland.appId)
                        Layout.preferredHeight: root.size - 8
                        pad: 10
                        active: modelData.activated
                        onPressed: modelData.wayland.activate()
                        IconImage { implicitSize: 22; source: Quickshell.iconPath(task.entry?.icon ?? "", "application-x-executable") }
                        Rectangle {
                            parent: task
                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 2 }
                            width: task.active ? 18 : 6; height: 3; radius: 2
                            color: task.active ? Theme.accent : Theme.subtext
                            Behavior on width { NumberAnimation { duration: Theme.anim } }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                BarTray {}
                BarKeyboard {}
                BarStatus {}
                BarBell {}
                ClockItem { text: Sys.time() + "\n" + Qt.formatDateTime(Sys.now, "dd/MM/yyyy"); pixelSize: Theme.fontLabel; align: Text.AlignRight }
            }
        }
    }

    // Noir: the top band: the app as a title, roman workspaces, the time as a credit
    Component {
        id: letterTop
        Rectangle {
            color: "#000000"
            Strip {
                anchors.fill: parent
                pad: 36
                BarApp { title: false; family: Theme.displayFont; size: Theme.fontHeading; weight: Font.Normal }
                centerItems: [ BarWs { monitor: root.monitor; style: "roman" } ]
                rightItems: [ ClockItem { text: Qt.formatDateTime(Sys.now, "dddd, ") + Sys.time(); family: Theme.displayFont; pixelSize: Theme.fontTitle + 2; weight: Font.Light } ]
            }
        }
    }
    Component {
        id: letterBottom
        Strip {
            pad: 36
            BarStatus { mode: "caps"; tone: Theme.subtext }
            BarKeyboard { plain: true; tone: Theme.subtext }
            rightItems: [ BarTray {}, BarBell { tone: Theme.subtext } ]
        }
    }

    // Garden: one pale capsule with the apps, the workspaces, the time and the status
    Component {
        id: islandBar
        Item {
            implicitWidth: capsule.width + 4
            Rectangle {
                id: capsule
                anchors { bottom: parent.bottom; bottomMargin: Theme.barInset; horizontalCenter: parent.horizontalCenter }
                height: root.size
                width: row.implicitWidth + 24
                radius: Theme.radius + 6
                color: Theme.accent2
                readonly property color ink: Themes.textOn(Theme.accent2, Theme.c)   // ink for the capsule's own colour
                RowLayout {
                    id: row
                    anchors.centerIn: parent
                    spacing: 10
                    BarItem { hover: Qt.alpha(capsule.ink, 0.1); onPressed: Launcher.toggle(); Text { text: "\u{F0BB1}"; color: capsule.ink; font { family: Theme.iconFont; pixelSize: 20 } } }
                    Repeater {
                        model: Config.dock.pinned.map(id => DesktopEntries.byId(id)).filter(e => e).slice(0, 6)
                        BarItem {
                            id: app
                            required property var modelData
                            hover: Qt.alpha(capsule.ink, 0.1); pad: 4
                            onPressed: modelData.execute()
                            IconImage { implicitSize: 30; source: Quickshell.iconPath(app.modelData?.icon ?? "", "application-x-executable") }
                        }
                    }
                    Rectangle { implicitWidth: 1; implicitHeight: root.size * 0.5; color: Qt.alpha(capsule.ink, 0.25) }
                    BarWs { monitor: root.monitor; style: "tiles"; tone: capsule.ink; dim: Qt.alpha(capsule.ink, 0.6) }
                    Rectangle { implicitWidth: 1; implicitHeight: root.size * 0.5; color: Qt.alpha(capsule.ink, 0.25) }
                    ClockItem { text: Sys.time(); tone: capsule.ink; family: Theme.displayFont; pixelSize: Theme.fontHeading; weight: Theme.displayWeight; hover: Qt.alpha(capsule.ink, 0.1) }
                    BarStatus { tone: capsule.ink; hover: Qt.alpha(capsule.ink, 0.1) }
                }
            }
        }
    }

    // Halo: one small floating pill: dots, the time, the status
    Component {
        id: haloBar
        Item {
            implicitWidth: pill.width + 4
            Glass {
                id: pill
                strong: true
                anchors { bottom: parent.bottom; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
                height: root.size - 8
                width: haloRow.implicitWidth + 28
                radius: height / 2
                RowLayout {
                    id: haloRow
                    anchors.centerIn: parent
                    spacing: 14
                    BarWs { monitor: root.monitor; style: "dots" }
                    ClockItem { text: Sys.time(); family: Theme.displayFont; pixelSize: Theme.fontTitle + 1; weight: Theme.displayWeight; radius: height / 2 }
                    BarStatus { radius: height / 2; glyphSize: 13 }
                }
            }
        }
    }

    // Zen: the time and the dots, small, in the bottom-right corner
    Component {
        id: cornerBar
        Item {
            implicitWidth: zenRow.implicitWidth + 40
            RowLayout {
                id: zenRow
                anchors { right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter }
                spacing: 14
                BarTray { iconSize: 14 }
                BarBell { tone: Theme.subtext }
                BarWs { monitor: root.monitor; style: "dots" }
                BarItem { onPressed: ControlCenter.toggle(); active: ControlCenter.open
                    Text { text: Sys.time(); color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.Light; features: { "tnum": 1 } } } }
            }
        }
    }
}
