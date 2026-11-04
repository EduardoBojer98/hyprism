import QtQuick

// The focused app: its name (bold), then the window title when there's room.
Row {
    id: app
    property bool title: Config.bar.windowTitle
    property int maxTitle: 360
    property color tone: Theme.text
    property string family: Theme.font
    property int size: Theme.fontSize
    property int weight: Font.DemiBold
    property bool lower: false
    spacing: Theme.spaceM
    visible: Sys.appClass !== ""
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: app.lower ? Sys.appName.toLowerCase() : Sys.appName
        color: app.tone
        font { family: app.family; pixelSize: app.size; weight: app.weight }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: app.title && Sys.appTitle !== "" && Sys.appTitle !== Sys.appName
        width: Math.min(implicitWidth, app.maxTitle)
        elide: Text.ElideRight
        text: Sys.appTitle
        color: Theme.subtext
        font { family: app.family; pixelSize: app.size }
    }
}
