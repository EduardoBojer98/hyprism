import QtQuick

// Launcher part: the grid layout's (Lumen) squircle plate behind an app icon; put it inside the icon's box.
Rectangle {
    property real pad: Theme.spaceS
    visible: Launcher.layout === "grid"
    anchors.centerIn: parent
    z: -1
    width: parent.width + pad * 2; height: width
    radius: width * 0.32
    color: Theme.fill
    border { width: 1; color: Theme.stroke }
}
