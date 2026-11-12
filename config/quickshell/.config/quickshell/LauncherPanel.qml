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
    height: keys.height + (Launcher.view === "home" ? home.implicitHeight + Theme.spaceM * 2
          : Launcher.view === "apps" || Launcher.view === "clip" ? 460
          : Math.min(440, Math.max(64, resultsView.contentHeight + Theme.spaceS * 2 + (Launcher.confirmFor ? 44 : 0))))

    // Confirmation strip for actions marked "ask first"
    Rectangle {
        id: confirmBar
        visible: Launcher.confirmFor !== null
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceS }
        height: 36
        radius: Theme.radiusSmall
        color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.16)
        Text {
            anchors { left: parent.left; leftMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
            text: "Run “" + (Launcher.confirmFor?.title ?? "") + "”? Enter to confirm, Esc to cancel"
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontSize }
        }
    }


    LauncherHome {
        id: home
        visible: Launcher.view === "home" && !Launcher.confirmFor
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

    // what the keys do, under the results (Tab cycles Search, Apps, Files, Actions, Clipboard)
    Text {
        id: keys
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 26
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: Launcher.view === "clip" ? "↑↓ move   ↵ paste   Del remove   Ctrl+P pin   Esc close"
            : Launcher.view === "apps" ? "←→↑↓ move   ↵ open   Tab next mode   Esc close"
            : "↑↓ move   ↵ open   Tab apps · files · actions   Esc close"
        color: Theme.muted
        font { family: Launcher.prompt !== "" ? Theme.monoFont : Theme.font; pixelSize: Theme.fontCaption }
    }
}
