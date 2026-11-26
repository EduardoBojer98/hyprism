import QtQuick

// Launcher part: a result row's right end. Idle: what the result is (Application, File, Setting…) in a quiet
// caption, so a list of mixed results reads at a glance. Selected: what Enter does ("Open", "Copy", "Run") and a ↵
// keycap. The sheet (Poster) has its LauncherTag instead; `kindShown` off (a row under its group's heading) leaves
// only the selected row's verb.
Row {
    id: kind
    property var item
    property bool current: false
    property bool kindShown: true
    readonly property string k: item?.kind ?? ""
    readonly property string name: ({ Applications: "Application", Files: "File", Folders: "Folder", Calculator: "Calculator",
                                      Settings: "Setting", Actions: "Action", Command: "Command", Web: "Web search" })[k] ?? ""
    readonly property string verb: ({ Calculator: "Copy", Actions: "Run", Command: "Run", Web: "Search" })[k] ?? "Open"
    visible: Launcher.layout !== "sheet" && (current || kindShown && name !== "")
    width: visible ? implicitWidth : 0
    spacing: Theme.spaceXs + 2
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: kind.current ? kind.verb : kind.name
        color: kind.current ? Launcher.selSub : Theme.muted
        font { family: Launcher.rowFont; pixelSize: Theme.fontCaption; weight: kind.current ? Font.Medium : Font.Normal }
    }
    Rectangle {   // the Enter keycap, only on the selected row
        visible: kind.current
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(height, cap.implicitWidth + Theme.spaceS); height: cap.implicitHeight + 2
        radius: Math.min(Theme.radiusSmall, 5)
        color: Launcher.inverse ? Qt.alpha(Launcher.selText, 0.18) : Theme.fill
                Text {
            id: cap
            anchors.centerIn: parent
            text: "↵"
            color: Launcher.selSub
            font { family: Theme.monoFont; pixelSize: Theme.fontLabel }
        }
    }
}
