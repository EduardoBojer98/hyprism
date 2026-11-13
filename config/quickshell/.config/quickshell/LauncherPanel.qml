import Quickshell
import QtQuick

// Launcher part: the results / browse panel under the search pill: confirmation strip, home, clipboard,
// apps grid and ranked list, plus the key hints. Used by Launcher.qml; reads state from the Launcher singleton.
Glass {
    id: panel
    property alias results: resultsView
    property alias grid: apps.grid
    property alias clipView: clipView
    strong: true
    flat: Launcher.unified
    color: Launcher.unified ? "transparent" : Launcher.surface
    border.width: Launcher.unified ? 0 : 1
    radius: Launcher.corner
    visible: Launcher.view !== "search" || Launcher.field.text.trim() !== ""
    // as tall as its content, never past the dock (the home view scrolls then); a style with `fill` keeps one height
    readonly property real natural: keys.height + (Launcher.view === "home" ? home.implicitHeight + Theme.spaceM * 2
          : Launcher.view === "apps" || Launcher.view === "clip" ? 460
          : resultsView.count === 0 ? 150   // room for the empty state
          : Math.min(440, Math.max(64, resultsView.contentHeight + Theme.spaceS * 2 + (Launcher.confirmFor ? 44 : 0))))
    height: Math.max(0, Launcher.look.fill > 0 ? Math.round(Launcher.room * Launcher.look.fill) : Math.min(natural, Launcher.room))

    // Confirmation strip for actions marked "ask first"
    Rectangle {
        id: confirmBar
        visible: Launcher.confirmFor !== null
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceS }
        height: 36
        radius: Launcher.corner === 0 ? 0 : Theme.radiusSmall
        color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.16)
        Text {
            anchors { left: parent.left; leftMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
            text: "Run “" + (Launcher.confirmFor?.title ?? "") + "”? Enter to confirm, Esc to cancel"
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontSize }
        }
    }

    Flickable {
        id: homeFlick
        anchors { fill: parent; bottomMargin: keys.height }
        visible: Launcher.view === "home" && !Launcher.confirmFor
        clip: true
        contentHeight: home.implicitHeight + Theme.spaceM * 2
        boundsBehavior: Flickable.StopAtBounds
        LauncherHome { id: home }
    }

    // Clipboard history inside Spotlight
    ClipboardView {
        id: clipView
        visible: Launcher.view === "clip"
        anchors { fill: parent; margins: Theme.spaceS; bottomMargin: keys.height }
    }

    LauncherApps {
        id: apps
        anchors { fill: parent; bottomMargin: keys.height }
    }

    LauncherResults {
        id: resultsView
        anchors { fill: parent; margins: Theme.spaceS; topMargin: confirmBar.visible ? 52 : Theme.spaceS; bottomMargin: keys.height }
    }

    // a cut-off row fades out instead of showing a sliver of icons
    Repeater {
        model: [homeFlick, apps.grid, resultsView]
        MoreBelow {
            required property var modelData
            z: 1
            flick: modelData
            opacity: modelData.visible ? 1 : 0   // only over the view on show (MoreBelow's own visible: more to scroll)
            ground: Launcher.surface
            anchors { left: parent.left; right: parent.right; bottom: keys.top; leftMargin: 1; rightMargin: 1 }
        }
    }

    // what the keys do, as key caps under the results (Tab cycles Search, Apps, Files, Actions, Clipboard)
    Item {
        id: keys
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 34
        Rectangle {   // a hairline over the hints, so they read as the panel's footer
            anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: Theme.spaceM; rightMargin: Theme.spaceM }
            height: 1
            color: Theme.stroke
            opacity: 0.6
        }
        Row {
            anchors.centerIn: parent
            spacing: Theme.spaceL
            Repeater {
                model: Launcher.view === "clip" ? [["↑↓", "move"], ["↵", "paste"], ["Del", "remove"], ["Ctrl P", "pin"], ["Esc", "close"]]
                     : Launcher.view === "apps" ? [["←→↑↓", "move"], ["↵", "open"], ["Tab", "next mode"], ["Esc", "close"]]
                     : [["↑↓", "move"], ["↵", "open"], ["Tab", "apps · files · actions"], ["Esc", "close"]]
                Row {
                    required property var modelData
                    spacing: Theme.spaceXs + 1
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(height, cap.implicitWidth + 10); height: cap.implicitHeight + 4
                        radius: Math.min(Theme.radiusSmall, 5)
                        color: Theme.fill
                        border { width: 1; color: Theme.stroke }
                        Text {
                            id: cap
                            anchors.centerIn: parent
                            text: modelData[0]
                            color: Theme.subtext
                            font { family: Theme.monoFont; pixelSize: Theme.fontCaption - 1 }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData[1]
                        color: Theme.muted
                        font { family: Launcher.rowFont; pixelSize: Theme.fontCaption }
                    }
                }
            }
        }
    }
}
