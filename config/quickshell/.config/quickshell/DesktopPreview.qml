import Quickshell
import QtQuick

// A small drawing of your screen for Settings: the wallpaper, the menu bar and dock where they are now (place,
// size, shape, gap), a window, and on request the on-screen display or the hot corners. `show` picks the part
// the page is about; the rest fades back. Everything follows the live values, so a pick moves it at once.
Item {
    id: pv

    property string show: "bar"          // bar | dock | osd | corners
    property var corners: ({})          // show: "corners": { topLeft: "Mission Control", ... } ("" = nothing)

    readonly property real sw: Math.min(width, 400)
    readonly property real sh: sw * 0.5625
    readonly property real s: sw / 1920 * 1.6     // screen scale, a little exaggerated so a 30 px bar still reads
    function dim(part) { return pv.show === part ? 1 : 0.45 }

    implicitHeight: sh + Theme.spaceM * 2
    Accessible.role: Accessible.Graphic
    Accessible.name: "Preview of the " + ({ bar: "menu bar", dock: "dock", osd: "on-screen display", corners: "hot corners" })[show]

    component Glide: Behavior { enabled: Theme.moves; NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }

    Rectangle {
        id: screen
        anchors.centerIn: parent
        width: pv.sw; height: pv.sh
        radius: Theme.radiusSmall
        color: Theme.base
        border { color: Theme.stroke; width: 1 }
        clip: true
        Image { anchors { fill: parent; margins: 1 } source: Wallpapers.current ? "file://" + Wallpapers.current : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 800; opacity: 0.85 }

        // the room the bar and a reserving dock leave, for the window
        readonly property real bt: bar.visible ? bar.t + bar.gap : 0
        readonly property real dt: dock.visible && !Theme.dockInBar ? dock.t + dock.lift : 0
        function room(side) { return (Theme.barEdge === side ? bt : 0) + (Theme.dockEdge === side ? dt : 0) + 8 * pv.s }

        Rectangle {   // a window, in the middle of the room left over
            readonly property real l: screen.room("left")
            readonly property real r: screen.room("right")
            readonly property real t: screen.room("top")
            readonly property real b: screen.room("bottom")
            width: (screen.width - l - r) * 0.62
            height: (screen.height - t - b) * 0.66
            x: l + (screen.width - l - r - width) / 2
            y: t + (screen.height - t - b - height) / 2
            radius: Math.min(Theme.radius, 18) * pv.s
            color: Qt.alpha(Theme.surfaceColor, 0.9)
            border { color: Theme.strokeStrong; width: 1 }
            opacity: 0.5
            Glide on x {}
            Glide on y {}
            Glide on width {}
            Glide on height {}
            Column {
                x: 10 * pv.s + 4; y: 10 * pv.s + 4
                spacing: 4
                Repeater { model: [0.5, 0.35, 0.42]; Rectangle { required property real modelData; width: screen.width * modelData * 0.6; height: 3; radius: 1.5; color: Theme.muted; opacity: 0.6 } }
            }
        }

        Rectangle {   // the menu bar
            id: bar
            readonly property bool vertical: Theme.barVertical
            readonly property real t: Math.max(5, Theme.barSize * pv.s)
            readonly property real gap: Theme.barMargin * pv.s
            x: Theme.barEdge === "right" ? screen.width - t - gap : gap
            y: Theme.barEdge === "bottom" ? screen.height - t - gap : gap
            width: vertical ? t : screen.width - gap * 2
            height: vertical ? screen.height - gap * 2 : t
            radius: Theme.barFloating ? Math.min(t / 2, Theme.radius) : 0
            color: pv.show === "bar" ? Qt.tint(Theme.base, Qt.alpha(Theme.accent, 0.12)) : Theme.base
            border { color: pv.show === "bar" ? Theme.accent : Theme.strokeStrong; width: 1 }
            opacity: pv.dim("bar")
            Glide on x {}
            Glide on y {}
            Glide on width {}
            Glide on height {}
            Glide on opacity {}
            Rectangle {   // the workspaces, in the accent
                readonly property real d: bar.t * 0.4
                x: bar.vertical ? (bar.t - d) / 2 : bar.t * 0.5
                y: bar.vertical ? bar.t * 0.5 : (bar.t - d) / 2
                width: bar.vertical ? d : d * 3; height: bar.vertical ? d * 3 : d
                radius: d / 2
                color: Theme.accent
            }
            Row {   // the dock inside the bar
                visible: Theme.dockInBar
                anchors.centerIn: parent
                spacing: bar.t * 0.2
                rotation: bar.vertical ? 90 : 0
                Repeater { model: 5; Rectangle { width: bar.t * 0.55; height: width; radius: width * 0.3; color: Theme.text; opacity: pv.show === "dock" ? 0.9 : 0.5 } }
            }
        }

        Rectangle {   // the floating dock
            id: dock
            readonly property bool vertical: Theme.dockVertical
            readonly property real icon: Config.dock.iconSize * pv.s
            readonly property real pad: Theme.dockPad * pv.s
            readonly property real t: icon + pad * 2
            readonly property real len: icon * 6 + pad * 7
            readonly property real lift: Theme.dockLift * pv.s
            visible: Config.dock.enabled && !Theme.dockInBar
            x: Theme.dockEdge === "left" ? lift + (Theme.barEdge === "left" ? screen.bt : 0)
                : Theme.dockEdge === "right" ? screen.width - t - lift - (Theme.barEdge === "right" ? screen.bt : 0)
                : (screen.width - width) / 2
            y: Theme.dockEdge === "top" ? lift + (Theme.barEdge === "top" ? screen.bt : 0)
                : Theme.dockEdge === "bottom" ? screen.height - t - lift - (Theme.barEdge === "bottom" ? screen.bt : 0)
                : (screen.height - height) / 2
            width: vertical ? t : len
            height: vertical ? len : t
            radius: Theme.dockStyle.shape === "pill" ? Math.min(width, height) / 2 : Theme.dockStyle.shape === "tile" ? Math.min(Theme.radius, 14) * pv.s : 0
            color: pv.show === "dock" ? Qt.tint(Theme.base, Qt.alpha(Theme.accent, 0.12)) : Theme.base
            border { color: pv.show === "dock" ? Theme.accent : Theme.strokeStrong; width: 1 }
            opacity: pv.dim("dock")
            Glide on x {}
            Glide on y {}
            Glide on width {}
            Glide on height {}
            Glide on opacity {}
            Grid {
                anchors.centerIn: parent
                columns: dock.vertical ? 1 : 6
                spacing: dock.pad
                Repeater { model: 6; Rectangle { width: dock.icon; height: width; radius: width * 0.28; color: Theme.text; opacity: index === 1 ? 0.95 : 0.55
                                                 required property int index } }
            }
        }

        Rectangle {   // the on-screen display: volume
            visible: pv.show === "osd"
            readonly property string at: Config.osd.position
            width: 150 * pv.s * 2.2; height: 26 * pv.s * 2.2
            x: (screen.width - width) / 2
            y: at === "top" ? screen.room("top") + 6 : at === "center" ? (screen.height - height) / 2 : screen.height - height - screen.room("bottom") - 6
            radius: Math.min(height / 2, Theme.radius)
            color: Theme.base
            border { color: Theme.accent; width: 1 }
            Glide on y {}
            Text { id: osdIcon; anchors { left: parent.left; leftMargin: parent.height * 0.35; verticalCenter: parent.verticalCenter } text: "\u{F057E}"; color: Theme.text; font { family: Theme.iconFont; pixelSize: Theme.glyphS } }
            Rectangle {
                anchors { left: osdIcon.right; leftMargin: 6; right: parent.right; rightMargin: parent.height * 0.4; verticalCenter: parent.verticalCenter }
                height: 4; radius: 2; color: Theme.fill
                Rectangle { width: parent.width * 0.6; height: parent.height; radius: 2; color: Theme.accent }
            }
        }

        Repeater {   // the hot corners: a quarter circle in each, lit when it does something, and what
            model: pv.show === "corners" ? [["topLeft", 0, 0], ["topRight", 1, 0], ["bottomLeft", 0, 1], ["bottomRight", 1, 1]] : []
            Item {
                id: corner
                required property var modelData
                readonly property string action: pv.corners[modelData[0]] ?? ""
                anchors.fill: parent
                Rectangle {
                    readonly property real r: 20
                    width: r * 2; height: r * 2; radius: r
                    x: corner.modelData[1] ? screen.width - r : -r
                    y: corner.modelData[2] ? screen.height - r : -r
                    color: corner.action ? Qt.alpha(Theme.accent, 0.35) : Qt.alpha(Theme.text, 0.08)
                    border { color: corner.action ? Theme.accent : Theme.stroke; width: 1 }
                }
                Rectangle {
                    visible: corner.action !== ""
                    readonly property real m: 24
                    x: corner.modelData[1] ? screen.width - width - m : m
                    y: corner.modelData[2] ? screen.height - height - m : m
                    width: Math.min(label.implicitWidth + 12, screen.width / 2 - m - 4); height: label.implicitHeight + 6
                    radius: Theme.radiusSmall
                    color: Theme.base
                    border { color: Theme.accent; width: 1 }
                    Text { id: label; anchors.centerIn: parent; width: parent.width - 12; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                           text: corner.action; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                }
            }
        }
    }
}
